# Stella Sora 1.13.0.143 support — live task list

- [x] Login → MainView → LevelMenu flow, no ParseMessage errors
- [x] Fix Dorm guide crash (extra_guide_groups + 9510/9516 handlers)
- [x] Generic fallback ack for packet IDs the 1.13 client added (5401, …)
- [x] Add packet tracing (config `trace_packets`: id, name, payload size)
- [x] Add rejection logging: every rejected request logs request + error code
- [x] Prove the 56 "Get skinData fail" errors are client-side (server sends zero gallery data, still 56)
- [x] Prove "ScoreBossControl Id = 13" is client-side (its own event table)
- [x] UI automation works: SendInput clicks reach Unity, Windows OCR reads the UI
- [x] Reproduce the new-banner bug: client asks for banner 10162, server rejected it
- [x] Fix it: serve the shared pools of the pity group for unknown banners (config `gacha_unknown_banner_fallback`)
- [x] Verify in the client: pull on banner 10162 completes, no "illegal request", no new client errors
- [ ] Add the real 1.13.0.143 data for character 162 and banner 10162 (Character, Gacha, GachaPkg, Handbook, Item, Talent, Potential tables)
- [ ] Identify packet 5401 (sent on every scene transition, payload 08 01)
- [ ] Play a stage end to end and implement the missing `*_apply_req` / `*_settle_req` handlers
- [ ] Refresh the remaining assets/tables/*.zon from the 1.13.0.143 client (needs the encrypted data.arcx / lua.arcx extracted)
- [ ] Commit the Astralis changes and the asterism patch
