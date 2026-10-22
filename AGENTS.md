# Nova agent guide

Nova is a private-server emulator for Stella Sora: the SDK service the client
logs into over HTTP, and the `agent-zone` game protocol it plays through, both
written in Zig.

It is a fork of [Astralis](https://git.xeondev.com/nyan/astralis) by nyan and is
licensed under AGPL-3.0 (`LICENSE`). Keep the copyright and license notices
intact, and credit the origin when the project is redistributed.

This file is the standing context for automated sessions in this checkout.
`CLAUDE.md` imports it.

## Definition of done

- `zig build -Doptimize=ReleaseSafe` succeeds.
- `zig build test` passes.
- `zig fmt` was run on every changed Zig file.
- No `generated/` file was edited by hand, and no game table row was invented.
- Commits are focused: one feature or fix per commit, with the reason in the
  message.

## Toolchain

Zig `0.16.0`, pinned by `build.zig.zon`. Nothing else is required.

| Command | Purpose |
| --- | --- |
| `zig build -Doptimize=ReleaseSafe` | Build both servers into `zig-out/bin/` |
| `zig build test` | Unit tests for common, protocol, game server and serve-all |
| `zig build serve-all` | Run the SDK server and the game server together |
| `zig build run-sdk-server` | Run only the SDK server |
| `zig build run-game-server` | Run only the game server |
| `zig build generate-assets -- all` | Regenerate every `generated/assets/*.zig` |
| `zig build generate-assets -- gacha` | Regenerate one asset module |
| `zig build generate-error-codes` | Regenerate `generated/error_code.zig` |
| `zig build generate-net-msg-id` | Regenerate `generated/net_msg_id.zig` |
| `zig build generate-protocol` | Regenerate `generated/protocol.zig` |

The last two need `assets/protocol/`, which is not tracked in this repository.
Without it the steps are no-ops and the checked-in output is used.

## Layout

```text
servers/sdk/          SDK server: accounts, client codes, server list (20001)
servers/game/         Game server: agent-zone protocol and gameplay (20002)
  agent_zone.zig      HTTP transport, decryption, packet framing, dispatch loop
  Scope.zig           Per-request state: player, mutation, response helpers
  messaging.zig       Builds the packet-ID to handler table at compile time
  messaging/          One file per feature; each public handler answers one request
  gameplay/           Semantic operations and their rules, no protobuf or Scope
  store/              Saved player structs, the player cache and the save format
  notify/             Notifications appended to the response after finalization
  view/               Response builders shared between handlers
  tables/             Typed access, lookups and validation over the game tables
common/               Shared CLI, IO and memory helpers
build/                Host tools: asset and protocol generators
assets/tables/        Raw game tables (.zon), tracked
assets/protocol/      Protocol dump, not tracked
assets/sdk/           SDK client codes and account fixtures
generated/            Checked-in generated Zig
docs/                 Contributor documentation, start at docs/README.md
tools/serve_all.zig   Supervises both server processes
store/                Runtime saves, git-ignored
```

## How a request is handled

1. `agent_zone.handle` receives an HTTP `POST` carrying an `X-Token` header.
2. The body is decrypted in place: AES-GCM with the session key, or the IKE key
   from `config.server_garble_key` for the first packet of a session.
3. An authenticated plaintext is `i64 timestamp | u16 sequence | i16 packet id |
   protobuf payload`; an initial packet has no prefix.
4. Pings are answered before an arena is created or player state is touched.
5. `messaging.dispatch` looks the packet id up in a compile-time handler table.
6. The handler reads through `Scope`, asks gameplay modules to mutate, and
   appends one or more response packets.
7. `agent_zone` finalizes progression, commits the player, encrypts the response
   and writes it back.

Requests without a handler go through `respondUnhandledPacket`: the mapped
success packet from `generated/net_msg_id.zig` when it is known, otherwise an
empty packet with `id + 1`. That keeps a newer client running while a feature is
unimplemented, so an `acking unknown packet` line is a lead, not a failure.

## Writing a handler

A handler is one function per request:

```zig
const proto = @import("proto");
const Scope = @import("../Scope.zig");

pub fn player_dorm_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.reject(.api_disabled);
}
```

Rules that the dispatcher enforces or assumes:

- The function name must equal a `proto.PacketId` field. The table is built from
  the declaration names, so a typo or a duplicate is a compile error.
- Every function in a registered namespace that takes exactly one `*Scope`
  argument becomes a handler. Keep helpers out of that shape and non-`pub`.
- Register the new file in the `namespaces` list in `servers/game/messaging.zig`.
- Read the request even when the body is empty, so the stream position is
  well-defined.
- `scope.respond` and `scope.respondEmpty` send success, `respondFailure` and
  `respondFailureEmpty` send a failure packet, `scope.reject(.code)` sends the
  mapped failure plus that error code.
- Log through `scope.logger(.feature)`; entries then carry the player id:

  ```zig
  const log = scope.logger(.gacha_spin_req);
  log.info("completed {d} pull(s) on banner {d}", .{ count, banner_id });
  ```

- Packet ids and messages live in `generated/net_msg_id.zig` and
  `generated/protocol.zig`. Extend them by regenerating from the protocol dump,
  not by hand, and check the result in.

## Gameplay modules and the mutation system

`docs/mutations.md` is required reading before changing saved state. The parts
that bite most often:

- `mutation.read()` for validation; `mutation.modify(.{...})` only when the
  operation is ready to write.
- Discover every expected client error before the first `modify()`. Calling
  `scope.reject()` after the request became dirty is invalid, because the player
  already holds a partial mutation.
- Gameplay modules own the rules and take `Mutation`; they must not import
  `Scope`, protobuf messages or handler modules.
- Handlers decode, validate shape, map gameplay errors to error codes and format
  the response. They do not reimplement rules.
- `notify/` turns the recorded changes into packets that ride along with the
  response.

## Tables and generated code

- `assets/tables/*.zon` are the game tables extracted from the client. They are
  the source of truth for every id, reward and probability.
- `build/assets/*.zig` are the generators. `zig build generate-assets -- all`
  rewrites `generated/assets/*.zig`, and those files are checked in.
- `servers/game/tables/*.zig` add typed access, lookups and validation on top of
  the generated data.
- The generators validate consistency and refuse input that does not line up,
  for example `InconsistentTalentGroupCount` when a character's talent groups
  disagree with its Potential and Talent rows. Never invent rows to silence such
  an error: extract the real tables from the client build being targeted.
- `generated/error_code.zig` is produced from `assets/tables/ErrorCode.zon` by
  `zig build generate-error-codes`.

## Configuration

`servers/game/config.zon` and `servers/sdk/config.zon` are injected as anonymous
imports named `config`, typed by the matching `Config.zig`. Add new options to
both the data file and the struct, with a comment that says why the option
exists.

Options that exist for client compatibility work:

- `extra_guide_groups`: guide groups the bundled guide table does not contain.
  The client runs a guide for every group it knows, so a group the server cannot
  answer has to be marked complete.
- `gacha_unknown_banner_fallback`: serve a banner the tables do not contain from
  the shared pools of its pity group instead of rejecting the pull.
- `gallery_types`: gallery types whose bitmap is sent. The client resolves the
  rows of every type it caches and logs `Get skinData fail` for rows its own
  tables lack.
- `trace_packets`: log every request with its numeric id, protocol name and
  payload size.

## Client compatibility

- The bundled tables match client `1.13.0.139`. The client used for testing is
  `1.13.0.143`, which is newer, so some requests and table rows have no server
  data behind them.
- Recruitment banner ids of the forms `1xxxx` and `11xxx` share pity storage 1,
  and `2xxxx` and `21xxx` share storage 3. That is what makes the fallback
  banner safe: it serves the same pools the real banner would.
- `Get skinData fail` and `ScoreBossControl Id = 13` come from the client's own
  tables, not from the server. They were proven to be client-side: the server
  sent no gallery data at all and the error count did not change.
- Before blaming the server for a client error, find the request behind it in
  the trace, then look for a matching `rejected` entry in the server log.

## Debugging

- Server logs are scoped: `agent_zone` for transport, `rejected` for refused
  requests, and one scope per feature.
- `trace_packets = true` logs each request as `received <id> (<name>), payload
  <n> bytes`.
- Unknown ids log a warning with the payload in hex, then get the fallback ack.
- Player saves are `store/player/<uid>.bin`, format version 2. A save written by
  another version is refused with a warning, and deleting the file resets that
  player.
- Sessions live in `store/session.bin`, accounts in `store/account/<uid>`.
- The client log is
  `%USERPROFILE%\AppData\LocalLow\YOSTAR (HONG KONG) LIMITED\StellaSora_steam\Player.log`.
  It is locked while the client runs, so clear it before launching.

## Testing against a real client

1. Stop both servers. On Windows the executables stay locked, so a rebuild fails
   with `AccessDenied` while they run.
2. `zig build -Doptimize=ReleaseSafe`.
3. Start `zig-out/bin/nova-sdk-server` (20001) and `nova-game-server` (20002), or
   run `zig build serve-all`.
4. Launch the patched client and play the feature. The client needs Asterism, a
   separate repository that redirects it to the local server.
5. Compare the client log with the server log and fix the first error in time
   order; later errors are usually fallout from it.

## Style

- `zig fmt`, four spaces, `snake_case` for functions and file names,
  `PascalCase` for types. Generated protocol structs keep their wire names.
- Files separate the import block from the code with a lone `//` line, and use
  the same lone `//` line before long static declarations. Follow that.
- Comments are plain sentences that explain why something is done. No banner
  comments and no dividers made of punctuation.
- Prefer explicit code. The one intentional piece of metaprogramming is the
  handler table in `messaging.zig`; keep it that way.

## Open work

The current task list lives in `.opencode/todos.md`, which is local and
git-ignored. Durable gaps are tracked in the README's "Still in progress"
section; do not duplicate them here.

Machine-specific details for the local test setup, such as install paths, log
locations and the client patch values, are in `.opencode/notes.md` when that
file exists. It is git-ignored for the same reason.
