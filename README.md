# C16 Flappy Bird

Flappy Bird for a stock 16 KiB PAL Commodore 16, written in ACME assembler.

The playfield is TED text mode: 38 visible columns, a 40-byte matrix, and
one-pixel horizontal scroll. The next frame is built in a hidden text buffer
and `$FF14` flips to it in the bottom border. Collision stops the round before bird cells overwrite the environment.
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
These cover all scroll phases, pipe edges, floor/ceiling, freeze and restart;
TED raster timing still needs verification in VICE.
