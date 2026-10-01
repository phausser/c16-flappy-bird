# Technical notes

The playfield uses mixed multicolor/hires TED text mode: 38 visible columns, a
40-byte matrix, and one-pixel horizontal scroll. The next frame is built in a
hidden text buffer and `$FF14` flips to it in the bottom border. Collision
uses the visible bird pixels and stops at the last free pixel against solid
pipes, the top edge (pixel 0) and the floor row (pixel 192). Pipes use rows
0-23. Row 24 is a fixed floor in the lower-border color and shows “HIGH 0000”
on the left, “TEDDY BIRD” centered and “SCORE 0000” on the right, without
scrolling. Numbers have four places with leading zeros (five above 9999).
On game over, “PRESS SPACE” replaces the centered title and alternates visible/hidden every 25 PAL frames. The best score
survives round restarts and resets when the program starts. The lettering
uses the digits' five-pixel height and two-pixel strokes. On death the bird
uses TED color 2 at luminance 6 (`$62`); restarting restores `TED_BIRD_COLOR`.
The RAM character set lives in `src/font.inc`: letters, digits and pipe
glyphs use one binary byte per line. Eight consecutive lines form a glyph;
bit 7 is the leftmost pixel. Dynamic bird glyphs are reserved there and
filled at runtime from the animation masks in `src/bird_masks.inc`.
Empty bird cells leave the environment and its
colors untouched.

The pipes use the exact 24-pixel stripe layout from
[assets/pipe.png](assets/pipe.png). Its top eight pixels form the end caps
beside the gap; the remaining stripe pattern repeats along the bodies.
Three multicolor glyphs provide yellow highlights (`$77`), green (`$55`) and
dark green (`$25`) using the TED palette. The bird remains hires; its TED
color is set by `TED_BIRD_COLOR` in `src/hardware.inc`. The sky hue is set by
`BACKGROUND_GRADIENT_COLOR` (currently TED color 6), with luminance 1–7.
The upper border uses luminance 0. Band spacing is set by
`BACKGROUND_GRADIENT_DISTANCE` (currently 28 lines). Color 9 at luminance 6
covers the lower border after the HUD. The HUD background starts at TED
line `$C4` in color 5 at luminance 1 (`$15`) for exactly 11 raster lines;
the existing brown begins at `$CF`. The HUD-entry IRQ sets horizontal scroll to 0
for the score row only; the game loop restores the playfield scroll at line
`$FC`. The active screen occupies TED raster-counter lines `$04` through
`$CB`. The handler owns the hardware IRQ with ROM banked out and returns
directly with `RTI`. It prepares each color in advance, normally enters one
line before the boundary, and uses `$FF1E` to place both color writes in the
horizontal blank. The first band starts exactly with character row 0 at TED
line `$04` (PAL picture line `$34`): its separate handler enters two lines
early and writes after the line-3 character fetch. Changes to band spacing require a fresh check of fetch pairs and blank
windows in VICE. This timing targets PAL with vertical scroll 3.

Each pipe passed scores one point. The pipe that ends the run does not.
Release and press Space again to restart from 0. A separate title screen
is still open; see [TODO.md](TODO.md). Score changes set `HUD_DIRTY` during
the buffer flip; only the numeric side fields are refreshed after scroll
copying and bird rendering. Fixed HUD cells are written directly into both
buffers, avoiding per-character row-pointer calculations. At score 1234,
the incremental update uses 2,628 CPU cycles versus 9,242 for the previous
full redraw. The centered title stays untouched by scoring. This keeps the approximately 1.92-second scoring events from
delaying the time-critical top-row updates. The scroll timing is specified
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

The current CPU regression suite passed 1,024 buffer flips, 3,000 automated
gameplay frames, 119,808 pixel collision cases and 4,616 render/restore cases.
All six poses stop at pixel 191. Tests cover animation cadence, contact,
freeze, restart, the session best score, footer alignment, 25-frame blinking
and deferred footer writes. IRQ register, stack, vector, 9-bit compare and
restart checks pass.

An earlier raster build passed 3,874 color-store checks in VICE. That result
does not validate the latest configurable colors, spacing or footer timing.
A fresh VICE trace, five-minute visual run and physical C16 check remain open.

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
