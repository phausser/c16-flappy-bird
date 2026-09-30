# C16 Flappy Bird

Flappy Bird for a stock 16 KiB PAL Commodore 16, written in ACME assembler.

The playfield is TED text mode: 38 visible columns, a 40-byte matrix, and
one-pixel horizontal scroll. The next frame is built in a hidden text buffer
and `$FF14` flips to it in the bottom border. Collision uses the visible bird
pixels and stops at the last free pixel against solid pipes and the upper
and lower screen edges (0 and 200 pixels). Pipes extend through all 25 rows;
there is no character-based ground strip or reserved HUD row. Empty bird
cells leave the environment and its colors untouched.
The sky uses a blue luminance ramp. The top border is darkest blue, the side
border ramps evenly to light blue, and the lower border uses color 9 at
luminance 5. A TED raster IRQ sets these bands; the active screen occupies
TED raster-counter lines `$04` through `$CB`. The handler owns the hardware
IRQ with ROM banked out and returns directly with `RTI`. It prepares each
color in advance, normally enters one line before the boundary, and uses `$FF1E` to
place both color writes in the horizontal blank. The first band starts
exactly with character row 0 at TED line `$04` (PAL picture line `$34`):
its separate handler enters two lines early and writes after the line-3
character fetch. Other band edges avoid fetch pairs. This timing targets
PAL with vertical scroll 3.
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
`python tests/gradient.py` checks IRQ register/stack preservation, restart,
and the full 9-bit raster sequence. Optionally pass a VICE monitor log
(recorded with `trace store ff19` and `trace store ff15`) to check the
actual color writes against the horizontal blank windows over 100+ frames.

The collision tests cover every pose and scroll phase, pixel contact, empty-cell rendering,
animation near edges, freeze and restart. The tests emulate the CPU; use VICE
for TED raster timing and visual checks.

The bird uses all six frames in `assets/flappy.gif` at its original 20×14 pixels,
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

## Current validation and remaining work

The full-height playfield passed 1,024 buffer flips, 3,000 automated gameplay
frames, 79,872 pixel collision cases and 3,424 render/restore cases. All four
poses currently covered by the collision oracle stop at the actual lower
screen edge. The aligned raster build passed 3,928 color-store checks in
VICE, plus IRQ register, stack, vector, 9-bit compare and restart checks.

`tests/collision.py` still stops at its existing animation-cadence assertion:
it assumes four frames, while the imported asset contains six. Tests after
that assertion are not reached by a normal run. Updating the animation
oracle and validating all six poses remains open in [TODO.md](TODO.md).
The latest raster changes have not been verified on physical C16 hardware.

To reproduce the raster trace after `make`, create a monitor command file:

```sh
printf 'trace store ff19\ntrace store ff15\nx\n' > build/raster.mon
xplus4 -console +sound -model c16pal -ramsize 16 \
  -autostartprgmode 1 -autostart-delay 1 -autostart-warp \
  -autostart build/flappy.prg -moncommands build/raster.mon \
  -monlog -monlogname build/raster.log -limitcycles 10000000
python tests/gradient.py build/raster.log
```

VICE exits with status 1 when the requested cycle limit is reached. Keep the
log paired with the exact build: the checker uses its symbol addresses.
