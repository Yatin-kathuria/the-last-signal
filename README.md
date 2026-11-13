# The Last Signal

**[Play The Last Signal in your browser](https://yatin-kathuria.github.io/the-last-signal/)**

A ten-room circuit puzzle built in **Godot 4.7.2** with GDScript. Carry a power cell, rotate mirrors, split a beam across two receivers, and reach the exit. Later rooms combine the dual signal with pressure plates and a six-second gate window. The presentation includes a cinematic tower scene, chapter selection, animated circuit feedback, original generated sound, and a separate **Learn to Play** section.

This is a small game and a gameplay assessment sample. The playable version is the **reference solution**. The `challenges/` folder contains a realistic bug report, a feature brief, exact acceptance criteria, and a patch that introduces the bug into a copy of the project.

## Play and inspect

| Action | Keyboard | On-screen control |
| --- | --- | --- |
| Move / face a device | WASD or arrows | Direction pad |
| Pick up, insert, or rotate | E or Space | E button |
| Restart current room | R | Reset button |
| Request a contextual hint | H | Hint button |
| Continue after a room | Enter | Next Room button |
| Return to title | Escape | — |
| Toggle sound | M | — |

The first room gives contextual hints and a pulsing target marker. Rooms 07–10 introduce a prism that splits one signal into two paths; both receivers must be live to open the gate. Rooms 04–06 and 09–10 add a timed plate. The model in [`scripts/puzzle_state.gd`](scripts/puzzle_state.gd) owns all puzzle state; [`scripts/game.gd`](scripts/game.gd) handles presentation and input. Room data is kept beside the rules so reproductions remain deterministic.

| Room | New challenge |
| --- | --- |
| 01 · First Spark | Guided cell pickup, socket connection, and exit |
| 02 · Reflection | One mirror |
| 03 · Double Back | Two mirrors |
| 04 · The Window | Two mirrors plus a timed plate |
| 05 · Fractured Path | Three mirrors plus a timed plate |
| 06 · Final Transmission | Four mirrors, a blocked route, and a timed plate |
| 07 · Split Horizon | A prism and two receivers |
| 08 · Cross Current | Three turns across two signal branches |
| 09 · Short Wave | Dual signal plus a timed gate |
| 10 · The Last Array | Four turns, two targets, and a final timed route |

## Run locally

1. Install the standard **Godot 4.7.2** editor and matching export templates.
2. Open `project.godot` and press F5 to run.
3. Run the deterministic replay checks:

   ```sh
   godot --headless --path . --script res://tests/test_puzzle.gd
   ```

The test replays all ten rooms and checks gate, mirror, split circuit, removal, timeout, and reset transitions. The audio files are original and reproducible with `python3 scripts/generate_audio.py`.

## Publish on GitHub Pages

The [live game](https://yatin-kathuria.github.io/the-last-signal/) is published from the committed `web/` directory by the `Publish playable game` GitHub Actions workflow. To rebuild it after editing the Godot source:

```sh
GODOT_BIN=/path/to/Godot ./scripts/export_web.sh
```

The export script imports the project, runs the replay test, exports a **single-threaded Web** build, and copies the generated files into `web/`. Godot's Compatibility renderer and GDScript are used so the build works as a static browser game. The on-screen controls also make it usable without a keyboard.

Commit and push the updated `web/` files to `main` whenever the game changes. The workflow then redeploys the site. Browsers need WebGL 2.0 for Godot 4's Web export.

## Assessment sample

- [`challenges/bug-01-brief.md`](challenges/bug-01-brief.md): a player-facing report with visual reproduction steps.
- [`challenges/bug-01-seed.patch`](challenges/bug-01-seed.patch): introduces the defect into the clean project with `git apply challenges/bug-01-seed.patch`.
- [`challenges/bug-01-reference.md`](challenges/bug-01-reference.md): diagnosis, fix, and regression test.
- [`challenges/feature-01-brief.md`](challenges/feature-01-brief.md): producer-style request for the timed pressure plate.
- [`challenges/feature-01-reference.md`](challenges/feature-01-reference.md): implementation and acceptance replay, as shipped in the clean game.
- [`challenges/feature-02-brief.md`](challenges/feature-02-brief.md): dual-channel prism request with a four-room acceptance playthrough.
- [`challenges/feature-02-reference.md`](challenges/feature-02-reference.md): split-beam implementation and regression checks.
- [`challenges/qa-matrix.md`](challenges/qa-matrix.md): input sequences, expected visuals, and state checks for manual playtesting.

All in-game art is drawn by Godot code; the project icon is a small SVG. The sound palette is generated in the repository. No external assets or services are required to play.

## Visual direction

The atmospheric station silhouettes take inspiration from [INSIDE](https://playdead.com/inside/); the high-contrast puzzle signals and gradual teaching take inspiration from [The Witness](https://the-witness.net/news/about/). The geometry, UI, art, and sound in this project are original.
