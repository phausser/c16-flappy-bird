# C16 Flappy Bird

![C16 Flappy Bird](preview.png)

Flappy Bird for a stock 16 KiB PAL Commodore 16, written in ACME assembler.
Space flaps. Each pipe you clear scores one point. Release Space and press
it again to restart.

Play it in the browser: https://phausser.github.io/c16-flappy-bird/

## Build

Requires [ACME](https://sourceforge.net/projects/acme-crossass/), Python 3 and
VICE (`xplus4`).

```sh
make           # build/flappy.prg
make run       # start it in VICE as a PAL C16
make lint      # build, then check style, names and zero-page addresses
```

Scroll, collision, pipes, tests and the raster trace are in [TECH.md](TECH.md).

## License

[MIT](LICENSE)
