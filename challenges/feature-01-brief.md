# Feature 01 — Timed escape plate

**Producer request**

> Room 03 solves too easily once the beam reaches the receiver. Add a pressure plate near the exit that gives the player a short window to cross the gate. The beam must remain connected. Make the plate and remaining time visible so players can understand why the gate opens or closes.

## Required behavior

- The receiver alone does **not** open the Room 03 gate.
- When the receiver is live, stepping on the plate opens the gate for **six seconds**.
- The gate stays open while the player remains on the plate and then counts down after they leave.
- Stepping on the plate again refreshes the window.
- If the receiver loses power, the gate closes immediately even if time remains.
- Reset clears the timer and restores the initial state.
- Rooms 01 and 02 keep their receiver-only gate behavior.

## Acceptance replay

1. In Room 03, connect the cell and rotate the upper mirror so the receiver lights. The gate must still be closed.
2. Step on the plate. The plate and gate light up, and the UI reads about `6.0s`.
3. Step off and wait more than six seconds. The gate closes and blocks movement.
4. Step onto the plate again, then move right, up, right, right to reach the exit before time expires.
5. Reset. The cell is loose, the receiver is dark, the plate timer is zero, and the gate is shut.

The clean playable game is the reference implementation for this feature.
