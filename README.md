# C16 Flappy Bird

Flappy Bird for a stock 16 KiB PAL Commodore 16, written in ACME assembler.

The playfield is TED text mode: 38 visible columns, a 40-byte matrix, and
one-pixel horizontal scroll. The next frame is built in a hidden text buffer
and `$FF14` flips to it in the bottom border. Collision uses the visible bird
pixels and stops at the last free pixel against solid pipe, ceiling and ground
edges. Empty bird cells leave the environment and its colors untouched.
The sky uses a blue luminance ramp. The top border is darkest blue, the side
border ramps evenly to light blue, and the lower border uses color 9 at
luminance 5. A TED raster IRQ sets these bands; the active screen occupies
TED raster-counter lines `$04` through `$CB`.
Release and press Space again to restart. Scoring and a game-over overlay
are still open; see `TODO.md`. The scroll timing is specified in `SPEC.md`.

Play it in the browser: https://phausser.github.io/c16-flappy-bird/

## Run

Requires [ACME](https://sourceforge.net/projects/acme-crossass/), Python 3 and
VICE (`xplus4`).

```sh
make           # build/flappy.prg
make run       # start it in VICE as a PAL C16
make lint      # build, then check style, names and zero-page addresses
```

GitHub Pages (Settings → Pages → Source: GitHub Actions) publishes
`web/index.html` together with the built PRG. The page loads the program in
EmulatorJS as a PAL C16. Space flaps; click the picture once so the key
reaches the emulator.

Collision regression tests execute the assembled code with py65 (install it
in a Python virtual environment): `python tests/collision.py` after `make`.
These cover every pose and scroll phase, pixel contact, empty-cell rendering,
animation near edges, freeze and restart. The tests emulate the CPU; use VICE
for TED raster timing and visual checks.

The bird uses every frame in `assets/flappy.gif` at its original 20×14 pixels,
100 ms each (five PAL frames). Fully transparent pixels remain transparent;
opaque pixels use the game's bird color. Regenerate the checked-in assembler
masks with `python3 tools/import_bird.py` (requires Pillow). Normal builds
need neither Pillow nor GIF decoding.

Pipes have a 72-pixel gap and a 192-pixel start-to-start spacing. Gap starts
vary between rows 4 and 10, changing by at most 16 pixels per pipe. The first
pipe keeps the familiar centered gap. Restart resets the fixed seed (`$5d`);
change `PIPE_RANDOM_SEED` in `src/constants.inc` to test another sequence.
`python tests/obstacles.py` verifies generation, restarts, screen/color copies,
ring/counter wraparound and an automated flight through changing gaps.
