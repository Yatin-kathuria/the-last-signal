# Feature 02 — Reference solution

[`puzzle_state.gd`](../scripts/puzzle_state.gd) adds a fixed `splitter`, a second receiver, separate receiver power state, and explicit beam segments. `_recompute()` follows each ray through mirrors and forks a new ray at the prism. A visited ray-state set and a step cap bound reflection loops. `_recompute_gate()` requires both receivers when the room has two, as well as a live plate timer where present.

[`game.gd`](../scripts/game.gd) renders each beam segment separately, labels receivers A and B, displays the prism, and offers a contextual Hint action. Room data for 07–10 gradually adds mirrors, walls, and timed gates. The deterministic replay in [`test_puzzle.gd`](../tests/test_puzzle.gd) confirms all rooms are solvable and specifically checks that one live branch cannot open the gate.

For manual verification, follow cases 07-A through 10-A in [`qa-matrix.md`](qa-matrix.md). The published Web build is the playable reference result.
