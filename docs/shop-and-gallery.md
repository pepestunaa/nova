# Shop, Gallery and skins

Three user-visible bugs shared one cause: a private server facing a client
newer than the data it ships with. Clicking a Lumina topup froze the game,
the Shop's Style and Furniture Gallery tabs were empty, and equipping a
skin you own answered "insufficient resources". This document is the record
of how each was diagnosed and fixed, written so the reasoning can be reused
the next time the client updates.

The common thread is that the client cannot be treated as a black box. Every
fix below started from one of two places: the packet trace (`trace_packets`
in the game server config), which shows what the client asks for and when it
goes quiet, or a table diff against the client's own data, which shows what
the client expects the server to know.

## How purchases work

A purchase is a three-step conversation, not one request:

```text
client                          server
  |                               |
  | mall_gem_order_req (5104)     |   place the order
  |------------------------------>|
  |<------------------------------|   order id, e.g. local-gem:1:7
  |                               |
  |   block input, call the       |
  |   platform SDK pay            |
  |                               |
  | mall_order_collect_req (5110) |   pay answered: collect
  |------------------------------>|
  |<------------------------------|   Lumina granted
```

After placing the order, the client blocks all input and hands the payment
to the platform SDK. On the official server the Steam overlay opens, the
pay callback fires, and the client sends the collect request that completes
the purchase. On a private server the SDK call never returns, so the input
block is never lifted: the game keeps rendering but stops responding to
every click. That was the "crash" — a client waiting forever, not a server
error.

The trace made this obvious: a `5104` line with nothing after it. No
rejection, no response problem — the conversation simply stopped at the
client's own SDK call.

The fix has two halves:

- **The client side (Asterism)** intercepts the game's SDK pay call and
  answers it locally: it builds the same pay-result object the platform
  would have returned, marks it successful, carries the original order
  reference, and invokes the game's own pay-response handler. The client
  cannot tell the difference, unblocks input, and collects.
- **The server side** keeps the `shop.topup_enable` config gate. While the
  client side is the part that makes payment work at all, the gate lets a
  stock client refuse cleanly with a popup instead of freezing.

Package purchases (`mall_package_order_req`, 5122) go through the same
order flow but pay with in-game currency, so they never touch the SDK and
only needed the gate.

## What fills the Style and Furniture Gallery

The Shop's tabs are not hardcoded anywhere on the server. The client asks
for the package list (`mall_package_list_req`, 5119) and renders whatever
packages the server sends, grouped by their `group_id`. A tab is empty
because the server has no rows for it — nothing else.

The bundled tables predated client `2.0.0.144`, so 32 `MallPackage` rows
were missing. They are exactly the new content: the `skin.98.*` packs that
fill the Style Gallery, the `Dorm.*` and `DormRoomLayout.*` packs that
fill the Furniture Gallery, and a batch of `pack.18_*` offers. One
`MallShop` row was missing the same way.

Refreshing a table is mechanical now, and every step of it is guarded:

1. The client's `data.arcx` is a compressed container; the extracted
   tables are protobuf rows keyed by string or numeric id.
2. Rows the server's `.zon` table does not have are appended, with the
   client's field numbers mapped onto the `.zon` field names.
3. `zig build generate-assets -- shop` rewrites the generated table and
   validates every package reward against the Item table. A reward the
   Item table does not know fails the build instead of reaching a player.

The same diff found the other half of "discovery": the Handbook (Gallery)
table itself had 57 new rows, including a whole new gallery type 8 for
dorm decor. The server sends one bitmap per gallery type, and only the
types listed in the `gallery_types` config, so the new type had to be
added there too.

## Skin ownership and equipping

Trekker skins have a stable id scheme: `characterId * 100 + n`, where
`1` is the base skin and `2` the advance skin. Further skins continue the
sequence — character 155's third skin is `15503`.

Ownership is not an item flag or a character field. The client equips
skins against the type-1 Gallery (Handbook) bitmap: one row per skin, and
an unlocked row means "I own this skin". Buying a `skin.98.*` pack grants
the skin item, and granting it unlocks the matching Gallery entry — that
unlock, not the item, is what the client's skin list reads.

`setSkin` used to accept only the base skin and the advance skin (by
advance level). Every further skin was refused with `cond_check`, which
the client displays as "insufficient resources" — misleading, since the
player had already paid. The purchase worked, the bitmap said the skin
was owned, and the equip still failed.

The rule now matches what the client already believes:

- the base skin is always equippable on an owned Trekker,
- the advance skin needs its advance level,
- any other skin needs its type-1 Gallery entry to exist, to belong to
  that Trekker, and to be unlocked.

## Verifying it yourself

With `trace_packets = true`, a healthy purchase is two lines and no
warning:

```text
received 5104 (mall_gem_order_req)
received 5110 (mall_order_collect_req)
```

If `5110` follows `5104`, the pay callback fired and the server granted.
A package purchase shows `5122`, an equip shows `2316`
(`char_skin_set_req`). The one line that always means a refused request is
`rejected ... with <error code>` — the code maps to a name in
`generated/error_code.zig`, and `cond_check` on an equip means the server
did not consider the skin owned, whatever the client displayed.

The client log agrees from the other side: pay success unblocks input and
shows the reward popup; a refused request shows a popup naming the error.

## Where the moving parts live

- `servers/game/gameplay/mall.zig` — order placement, collection, and the
  `topup_enable` gate.
- `servers/game/gameplay/reward.zig` — `grantItem`, which unlocks the
  Gallery entry of skin and decor items it grants.
- `servers/game/gameplay/character_progression.zig` — `setSkin` and the
  equipping rules.
- `servers/game/tables/handbook.zig` — the gallery types, the skin
  lookups, and the bitmap layout the client expects.
- `servers/game/config.zon` — `shop.topup_enable`, `gallery_types`,
  `trace_packets`.
- Asterism (the separate client-patcher repository) — `patchSdkPay`, the
  client patch that answers the SDK pay call locally.

Machine-specific details — client paths, patch addresses, the extraction
scripts — live in `.opencode/notes.md`, which is git-ignored on purpose.
The table refreshes that fixed the galleries are commits `4bff9cd`
(MallShop, MallPackage) and the equip fix is `2ce32ad`.
