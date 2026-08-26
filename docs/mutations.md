# The mutation system

The mutation system is the path from "this request changed the player" to
"the change was finalized, notified, and saved". It keeps gameplay code aware
of the progression it affects without turning the server into an event bus.

The short version is:

```text
decode and validate
        ↓
gameplay operation mutates through Mutation
        ↓
progression.finalize recalculates derived state
        ↓
notifications are appended
        ↓
the response is finalized and the player is saved
```

If any step fails, the request does not commit and the player cache restores
the last saved state.

## What `Mutation` contains

`Mutation` is request-local. It borrows the current `Player`, stores no
allocator, and uses fixed-size sets to remember what happened during the
request.

There are two kinds of information in it:

- **Invalidated dependencies** say which progression family must be checked
  again. The current families are acquisitions, characters, discs, Research
  Project, tutorials, and Monolith Research.
- **Recorded changes** identify exact things that need a follow-up update. For
  example, a newly owned character, a changed Handbook type, or a Research
  Project quest that changed.

The sets merge repeated changes automatically. A ten-pull can touch the same
achievement or Handbook category more than once, but finalization still emits
one update with the final state.

## The basic API

Use `read()` while checking a request. It returns a read-only player pointer
and does not make the request dirty.

```zig
const current = mutation.read();
const character = current.characters.get(character_id) orelse
    return error.InvalidCharacter;
```

Call `modify()` only when the operation is ready to change saved state. Pass
the dependencies affected by that change:

```zig
const player = mutation.modify(.{ .characters = true });
player.characters.getMut(character_id).?.setSkillLevel(.main, target_level);
```

In the server, the validation and the low-level write above belong inside a
semantic gameplay operation such as `character_progression.upgradeSkill`, not
inside the handler itself.

For a persistent change that does not affect a derived progression family,
use an empty invalidation set:

```zig
const player = mutation.modify(.{});
player.basic.head_icon = icon_id;
```

If the dependency becomes known later, add it with `invalidate()`:

```zig
const player = mutation.modify(.{ .acquisitions = true });

if (first_character)
    mutation.invalidate(.{ .characters = true });
```

These calls can happen more than once. `modify()` marks the request dirty and
`invalidate()` merges flags; neither call runs progression immediately.

The recording helpers are for exact follow-up notifications:

```zig
mutation.recordNewCharacter(character_id);
mutation.recordHandbookType(tables.handbook.skin_type);
mutation.recordResearchProjectQuest(quest_id);
```

They are deduplicated, so callers do not need to check whether the same value
was already recorded.

`finish()`, `committed()`, and `rebind()` belong to the request pipeline. Do
not call them from a handler or gameplay operation.

## Where code belongs

Handlers deal with the wire protocol. They decode the request, validate its
shape, map expected gameplay errors to client error codes, build the primary
response, and log the request.

Gameplay modules own semantic operations and their rules. They should accept
`Mutation` (and an allocator when they really need one), but they should not
import `Scope`, protobuf messages, or handler modules.

The saved player structs are data storage. They provide low-level access to
the state, but they should not become transaction-aware services.

For example, character progression belongs in the gameplay module:

```zig
try character_progression.upgradeSkill(
    scope.mutation(),
    request.CharId,
    skill,
    &receipt,
);
```

The operation validates the character and costs, mutates the player, and
marks the dependencies it affects. The handler only maps its errors and
formats the response.

## Receipts are not progression changes

An operation-specific receipt describes the response for that operation. A
gacha receipt, for example, contains acquired cards, duplicate conversions,
and resource or item deltas:

```zig
var receipt: reward.GachaReceipt = .{};
try reward.grantCards(
    scope.mutation(),
    scope.gpa,
    cards,
    scope.now,
    &receipt,
);
```

The receipt is not a replacement for invalidation or recorded changes. The
operation still has to tell `Mutation` that acquisitions, characters, discs,
or the Handbook changed. Finalization uses that request-wide information to
refresh derived progression once.

The same pattern applies to action counters. An Ascension operation records
the fact at the point where it happens:

```zig
research_project.enteredAscension(scope.mutation());
```

The counter is authoritative saved state. Research Project reconciliation
later reads that state and produces the final quest changes for notification.

## Errors and rollback

Expected client errors must be discovered before the first call to `modify()`.
After a request becomes dirty, calling `scope.reject()` is invalid because it
would try to send a protocol failure while the player already contains a
partial mutation.

The usual handler shape is:

```zig
const request = try scope.source.read(proto.pb.SomeRequest);

operation.apply(scope.mutation(), request) catch |err| switch (err) {
    error.InvalidInput => return scope.reject(.invalid_req),
    error.InsufficientResources => return scope.reject(.cond_check),
    else => |other| return other,
};

try scope.respond(response);
```

Gameplay code should not swallow allocation, encoding, or storage errors and
turn them into a success response. If one of those errors happens after a
mutation, it propagates out of the request and the cache rollback restores
the last committed player state.

Responses are buffered while finalization and saving still have a chance to
fail. The player is committed only after progression notifications and the
response body have been prepared successfully.

## Adding a new gameplay operation

When adding a feature, walk through this checklist:

1. Decide whether the operation changes persistent player state.
2. Validate all expected client failures through `mutation.read()` first.
3. Put the semantic mutation in the gameplay module, not in the handler.
4. Call `modify()` with every affected dependency.
5. Record exact new entries or quest changes needed by notifications.
6. Keep operation-specific response data in a receipt.
7. Make sure the handler maps expected errors before it becomes dirty.
8. Add a focused gameplay test and a finalization test when derived progress
   is involved.

If a new progression family needs a dependency, add it deliberately to
`Dependency` and to `gameplay/progression.zig`. Do not create a generic
subscriber or register functions by name; the finalization order should stay
visible and explicit.
