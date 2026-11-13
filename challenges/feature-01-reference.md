# Feature 01 — Reference solution

The clean project implements the timed plate in three places:

1. Room 04 data defines the plate tile in [`puzzle_state.gd`](../scripts/puzzle_state.gd).
2. `move()` arms the timer on entry; `tick()` keeps it charged while occupied and counts down after departure. `_recompute_gate()` requires receiver power and a positive timer in Rooms 04–06 and 09–10. The later rooms also require both split signal receivers.
3. [`game.gd`](../scripts/game.gd) draws the plate state and timer text. Input and renderer read the same model state.

The replay test checks that the receiver by itself cannot open the gate, the plate can, a timeout closes it, re-entry refreshes it, and the player can finish the room. The production build is the tested reference solution.
