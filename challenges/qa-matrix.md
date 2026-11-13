# Playtest and verification matrix

Each case starts from a fresh room unless the row says otherwise. The on-screen observations are intended for manual playtesting; the state checks are covered by `tests/test_puzzle.gd`.

| Case | Input sequence | Expected screen | Verifiable state |
| --- | --- | --- | --- |
| 01-A: connect | Room 01: E, Right, E | Cell appears in socket; beam and receiver glow; gate bars disappear | `socket_filled`, `receiver_on`, `gate_open` |
| 01-B: disconnect | After 01-A: E | Beam vanishes; receiver darkens; gate bars return | Empty `beam`; `not receiver_on`; `not gate_open` |
| 02-A: missed mirror | Room 02: pick up cell, connect socket | Beam goes right, reflects downward, and misses receiver | `socket_filled`; `not receiver_on` |
| 02-B: rotate | Face mirror from above; E | Beam reflects upward; receiver lights; gate opens | `receiver_on`; `gate_open` |
| 03-A: double reflection | Room 03: connect cell and align both mirrors | Beam turns twice; receiver lights; gate opens | `receiver_on`; `gate_open` |
| 04-A: receiver only | Room 04: connect cell and rotate upper mirror | Receiver lights; gate remains closed; UI says `GATE WAITING` | `receiver_on`; `not gate_open` |
| 04-B: plate | After 04-A: step on plate | Plate glows, gate opens, UI starts near `6.0s` | `plate_time > 0`; `gate_open` |
| 04-C: timeout | Step off plate and wait more than six seconds | Countdown reaches zero; bars return; gate blocks entry | `plate_time == 0`; `not gate_open` |
| 04-D: refresh | Re-enter plate before reaching exit | Countdown returns near `6.0s` | `plate_time > 0`; `gate_open` |
| 05-A: three turns | Room 05: align three mirrors, then step on plate | Beam reaches receiver after three turns; gate timer starts | `receiver_on`; `gate_open` |
| 06-A: final route | Room 06: align four mirrors, step on plate, navigate around the wall | The final beam reaches receiver; player clears gate before timeout | `won` |
| 07-A: partial split | Room 07: connect cell without rotating the upper mirror | Lower receiver A glows; receiver B and gate stay dark | `receiver_on`; `not extra_receiver_on`; `not gate_open` |
| 07-B: full split | Room 07: rotate upper mirror | Both beam branches reach A and B; gate opens | `receiver_on`; `extra_receiver_on`; `gate_open` |
| 08-A: cross current | Room 08: align all three mirrors | Both receivers glow across separate routes; gate opens | `extra_receiver_on`; `receiver_on`; `gate_open` |
| 09-A: dual timer | Room 09: align both mirrors, then step on plate | Both receivers glow; plate starts six-second gate window | `extra_receiver_on`; `plate_time > 0`; `gate_open` |
| 10-A: final array | Room 10: align four mirrors, then cross from plate to exit | Two circuit branches glow; final gate opens until timer expires | `extra_receiver_on`; `receiver_on`; `won` |
| Reset | Press R in any room | Loose cell, dark receiver, closed gate; mirror positions restored | Initial room state restored |

Browser smoke test: the exported `web/` build loaded through a local HTTP server, showed the menu, chapter select, Learn to Play section, guided first room, and dual-signal rooms, accepted keyboard and on-screen input, and produced no browser console errors.
