# Technical notes

The playfield uses mixed multicolor/hires TED text mode: 38 visible columns, a
40-byte matrix, and one-pixel horizontal scroll. The next frame is built in a
hidden text buffer and `$FF14` flips to it in the bottom border. Collision
uses the visible bird pixels and stops at the last free pixel against solid
pipes, the top edge (pixel 0) and the floor row (pixel 192). Pipes use rows
0-23. Row 24 is a fixed floor in the lower-border color and shows the score,
centered, without scrolling. Empty bird cells leave the environment and its
colors untouched.

The pipes use the exact 24-pixel stripe layout from
[assets/pipe.png](assets/pipe.png), repeated vertically without end caps.
Three multicolor glyphs provide yellow highlights (`$77`), green (`$55`) and
dark green (`$25`) using the TED palette. The bird remains hires; its TED
color is set by `TED_BIRD_COLOR` in `src/hardware.inc`. The sky uses a blue
luminance ramp. The top border is darkest blue, the side border ramps evenly
to light blue, and color 9 at luminance 5 covers the floor row plus the lower
border, starting at TED line `$C4`. That same IRQ sets horizontal scroll to 0
for the score row only; the game loop restores the playfield scroll at line
`$FC`. The active screen occupies TED raster-counter lines `$04` through
`$CB`. The handler owns the hardware IRQ with ROM banked out and returns
directly with `RTI`. It prepares each color in advance, normally enters one
line before the boundary, and uses `$FF1E` to place both color writes in the
horizontal blank. The first band starts exactly with character row 0 at TED
line `$04` (PAL picture line `$34`): its separate handler enters two lines
early and writes after the line-3 character fetch. Other band edges avoid
fetch pairs. This timing targets PAL with vertical scroll 3.

Each pipe passed scores one point. The pipe that ends the run does not.
Release and press Space again to restart from 0. Best score and a title
screen are still open; see [TODO.md](TODO.md). The scroll timing is specified
in [SPEC.md](SPEC.md).

## Pages build

GitHub Pages (Settings → Pages → Source: GitHub Actions) publishes
`web/index.html` together with the built PRG. The page loads the program in
EmulatorJS as a PAL C16. Space flaps; click the picture once so the key
reaches the emulator.

## Tests

Collision regression tests execute the assembled code with py65 (install it
in a Python virtual environment): `python tests/collision.py` after `make`.
`python tests/gradient.py` checks IRQ register/stack preservation, restart,
and the full 9-bit raster sequence. Optionally pass a VICE monitor log
(recorded with `trace store ff19` and `trace store ff15`) to check the
actual color writes against the horizontal blank windows over 100+ frames.

The collision tests cover every pose and scroll phase, pixel contact,
empty-cell rendering, animation near edges, freeze and restart. The tests
emulate the CPU; use VICE for TED raster timing and visual checks.

The bird uses all six frames in `assets/flappy.gif` at its original 20×14
pixels, 100 ms each (five PAL frames). Fully transparent pixels remain
transparent; opaque pixels use the game's bird color. Regenerate the
checked-in assembler masks with `python3 tools/import_bird.py` (requires
Pillow). Normal builds need neither Pillow nor GIF decoding.

Pipes have a 72-pixel gap and a 96-pixel start-to-start spacing. Gap starts
vary between rows 4 and 10, changing by at most 16 pixels per pipe. The first
pipe keeps the familiar centered gap. Restart resets the fixed seed (`$5d`);
change `PIPE_RANDOM_SEED` in `src/constants.inc` to test another sequence.
`python tests/score.py` checks one point per pipe, the fixed floor row and
digit placement. `python tests/obstacles.py` verifies the multicolor stripe
pattern and mode, generation, restarts, screen/color copies, ring/counter
wraparound and an automated flight through changing gaps.

## Current validation and remaining work

The full-height playfield passed 1,024 buffer flips, 3,000 automated gameplay
frames, 79,872 pixel collision cases and 3,064 render/restore cases. All four
poses currently covered by the collision oracle stop at pixel 191, on the
score row. The multicolor raster build passed 3,874 color-store checks in
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
