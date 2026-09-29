# C16 Flappy Bird

PAL-oriented Flappy Bird for a stock 16 KiB Commodore 16, written in ACME
assembler.

## Prerequisites

- [ACME](https://sourceforge.net/projects/acme-crossass/)
- VICE with the `xplus4` executable

## Build and run

```sh
make
make run
```

`make run` starts VICE as a PAL C16 with exactly 16 KiB RAM. It injects the
PRG directly and temporarily enables warp mode while autostarting, avoiding
the virtual-drive loading delay:

```sh
xplus4 -model c16pal -ramsize 16 -autostartprgmode 1 -autostart-warp -autostart build/flappy.prg
```

## Current milestone

The fine-scroll prototype establishes milestone 1. It initializes a
RAM-resident character set and renders a 40x25 sky, ground, and deterministic
pipe pattern. The playfield moves left by one hardware pixel per PAL frame;
after each eight pixels, the visible character map advances and one newly
generated right-edge column is filled. The border alternates color at each
column update as a visible refill marker.

The prototype still needs the 30-second VICE verification described in
`TODO.md` before milestone 1 can be accepted.
