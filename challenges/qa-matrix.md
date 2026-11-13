# Playtest and verification matrix

Each case starts from a fresh room unless the row says otherwise. The on-screen observations are intended for manual playtesting; the state checks are covered by `tests/test_puzzle.gd`.

| Case | Input sequence | Expected screen | Verifiable state |
| --- | --- | --- | --- |
| 01-A: connect | Room 01: E, Right, E | Cell appears in socket; beam and receiver glow; gate bars disappear | `socket_filled`, `receiver_on`, `gate_open` |
| 01-B: disconnect | After 01-A: E | Beam vanishes; receiver darkens; gate bars return | Empty `beam`; `not receiver_on`; `not gate_open` |
| 02-A: missed mirror | Room 02: pick up cell, connect socket | Beam goes right, reflects downward, and misses receiver | `socket_filled`; `not receiver_on` |
| 02-B: rotate | Face mirror from above; E | Beam reflects upward; receiver lights; gate opens | `receiver_on`; `gate_open` |
| 03-A: receiver only | Room 03: connect cell and rotate upper mirror | Receiver lights; gate remains closed; UI says `GATE WAITING` | `receiver_on`; `not gate_open` |
| 03-B: plate | After 03-A: step on plate | Plate glows, gate opens, UI starts near `6.0s` | `plate_time > 0`; `gate_open` |
| 03-C: timeout | Step off plate and wait more than six seconds | Countdown reaches zero; bars return; gate blocks entry | `plate_time == 0`; `not gate_open` |
| 03-D: refresh | Re-enter plate before reaching exit | Countdown returns near `6.0s` | `plate_time > 0`; `gate_open` |
| Reset | Press R in any room | Loose cell, dark receiver, closed gate; mirror positions restored | Initial room state restored |

Browser smoke test: the exported `web/` build loaded through a local HTTP server, showed all three rooms, accepted keyboard and on-screen input, and produced no browser console errors.
