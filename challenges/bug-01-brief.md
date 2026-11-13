# Bug 01 — Gate stays open after power is removed

**Player report**

> In the first room, I put the cell in the socket and saw the beam light the receiver. When I took the cell back out, the beam vanished but the receiver and exit gate still looked active. I could walk through an unpowered gate.

## Reproduce in the seeded build

1. Start Room 01. Face the cell and press **E** to pick it up.
2. Move one tile right. Press **E** to insert it into the socket.
3. Confirm the beam, receiver, and gate turn on.
4. Without moving, press **E** again to remove the cell.
5. Observe the receiver and gate, then try crossing the gate.

## Expected result

Removing the cell clears the beam, switches off the receiver, and closes the gate in the same update. The player cannot cross the closed gate. Re-inserting the cell restores the circuit. Reset returns the room to its initial state.

## Acceptance criteria

- The on-screen beam, receiver, and gate agree after every insert/remove action.
- The gate blocks movement whenever the receiver is unpowered.
- Repeated insert/remove cycles do not leave stale power state.
- The other campaign rooms still solve normally.
- The deterministic replay test passes.

To reproduce, apply `bug-01-seed.patch` to a clean checkout. The normal playable build and `bug-01-reference.md` show the reference solution.
