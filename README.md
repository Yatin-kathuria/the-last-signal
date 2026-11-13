# The Last Signal

A three-room circuit puzzle built in **Godot 4.7.2** with GDScript. Carry a power cell, rotate mirrors, catch a beam, and reach the exit. The final room adds a pressure plate and a six-second gate window.

This is a small game and a gameplay assessment sample. The playable version is the **reference solution**. The `challenges/` folder contains a realistic bug report, a feature brief, exact acceptance criteria, and a patch that introduces the bug into a copy of the project.

## Play and inspect

| Action | Keyboard | On-screen control |
| --- | --- | --- |
| Move / face a device | WASD or arrows | Direction pad |
| Pick up, insert, or rotate | E or Space | E button |
| Restart current room | R | Reset button |
| Continue after a room | Enter | Next Room button |
| Return to title | Escape | — |

The game is intentionally small: three handcrafted rooms, one battery per room, one beam receiver, and one exit. Each room adds a system and then uses the previous systems. The model in [`scripts/puzzle_state.gd`](scripts/puzzle_state.gd) owns all puzzle state; [`scripts/game.gd`](scripts/game.gd) handles presentation and input. Room data is kept beside the rules so reproductions remain deterministic.

## Run locally

1. Install the standard **Godot 4.7.2** editor and matching export templates.
2. Open `project.godot` and press F5 to run.
3. Run the deterministic replay checks:

   ```sh
   godot --headless --path . --script res://tests/test_puzzle.gd
   ```

The test replays all three rooms and checks gate, mirror, removal, timeout, and reset transitions.

## Publish on GitHub Pages

The committed `web/` directory is the playable build. To rebuild it after editing the Godot source:

```sh
GODOT_BIN=/path/to/Godot ./scripts/export_web.sh
```

The export script imports the project, runs the replay test, exports a **single-threaded Web** build, and copies the generated files into `web/`. Godot's Compatibility renderer and GDScript are used so the build works as a static browser game. The on-screen controls also make it usable without a keyboard.

1. Create a GitHub repository with this folder as its root and push it to `main`.
2. In the repository, open **Settings → Pages** and select **GitHub Actions** as the build and deployment source.
3. The `Publish playable game` workflow uploads `web/` and deploys it. The URL will appear in the workflow's deployment result and in the Pages settings.

The workflow serves the checked-in build, so run `./scripts/export_web.sh` and commit changes in `web/` whenever the game changes. Browsers need WebGL 2.0 for Godot 4's Web export.

## Assessment sample

- [`challenges/bug-01-brief.md`](challenges/bug-01-brief.md): a player-facing report with visual reproduction steps.
- [`challenges/bug-01-seed.patch`](challenges/bug-01-seed.patch): introduces the defect into the clean project with `git apply challenges/bug-01-seed.patch`.
- [`challenges/bug-01-reference.md`](challenges/bug-01-reference.md): diagnosis, fix, and regression test.
- [`challenges/feature-01-brief.md`](challenges/feature-01-brief.md): producer-style request for the timed pressure plate.
- [`challenges/feature-01-reference.md`](challenges/feature-01-reference.md): implementation and acceptance replay, as shipped in the clean game.
- [`challenges/qa-matrix.md`](challenges/qa-matrix.md): input sequences, expected visuals, and state checks for manual playtesting.

All in-game art is drawn by Godot code; the project icon is a small SVG. No external assets or services are required to play.
