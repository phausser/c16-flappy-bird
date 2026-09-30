# C16 Flappy Bird

Flappy Bird for a stock 16 KiB PAL Commodore 16, written in ACME assembler.

The playfield is TED text mode: 38 visible columns, a 40-byte matrix, and
one-pixel horizontal scroll. The next frame is built in a hidden text buffer
and `$FF14` flips to it in the bottom border. Collision, score and game over
are still open; see `TODO.md`. The scroll timing is specified in `SPEC.md`.

## Run

Requires [ACME](https://sourceforge.net/projects/acme-crossass/) and VICE
(`xplus4`).

```sh
make
make run
```
