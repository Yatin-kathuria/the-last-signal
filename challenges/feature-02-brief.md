# Feature 02 — Split the last signal

**Producer request**

> The station needs a new wing after Room 06. Add a prism that forks one powered beam into two branches. The exit must stay locked until both receiver channels are lit. Build four escalating rooms that teach the split, cross its two routes, then combine the split with the timed plate.

## Player-visible requirements

- The prism is clearly distinct from mirrors and does not rotate. It sends one branch straight and one branch to its left.
- Receivers A and B show separate live and offline states. A lit receiver alone never opens the gate.
- Rooms 07 and 08 teach the new circuit without a timer; Rooms 09 and 10 combine both channels with the pressure plate.
- The beam animation shows both branches without connecting their tips with a false line.
- The Hint action offers a useful next step without giving away exact mirror orientations.

## Acceptance playthrough

1. Open Room 07. Connect the cell. Receiver A lights, B stays dark, and the gate remains closed.
2. Rotate the upper mirror. Both receivers light and the gate opens. Rotate it away; B and the gate switch off immediately.
3. Complete Rooms 08–10 by aligning all mirrors. In Rooms 09 and 10, the gate opens only after both receivers are live **and** the plate has been pressed.
4. Reset each room. The cell, mirror orientations, receiver states, beam paths, and timer return to their starting state.

The reference implementation is in the clean game. `tests/test_puzzle.gd` replays all four rooms and checks the partial circuit regression.
