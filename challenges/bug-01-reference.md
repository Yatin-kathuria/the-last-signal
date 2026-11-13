# Bug 01 — Reference solution

The seeded defect leaves `receiver_on` unchanged when the socket becomes empty. `_recompute()` clears the beam but only resets receiver power inside the socket-filled branch. `_recompute_gate()` then sees the stale `receiver_on` value and keeps the gate open.

The fix is to reset `receiver_on` **before** checking whether the socket is filled. Then compute the beam and receiver state from the current circuit, and finally recompute the gate. This is the behavior in the clean [`puzzle_state.gd`](../scripts/puzzle_state.gd).

The regression replay removes the cell after a successful connection and checks `beam.is_empty()`, `not receiver_on`, and `not gate_open`. It inserts the cell again to check that the circuit can recover. See [`test_puzzle.gd`](../tests/test_puzzle.gd).
