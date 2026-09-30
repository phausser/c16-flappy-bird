"""Execute the built 6502 collision routine: pip install py65; make; run this file."""
import re
from pathlib import Path

from py65.devices.mpu6502 import MPU

ROOT = Path(__file__).resolve().parents[1]
SYMBOLS = dict((name, int(value, 16)) for name, value in re.findall(
    r'^\s*(\w+)\s*=\s*\$([0-9a-f]+)',
    (ROOT / 'build/flappy.sym').read_text(), re.M))
prg = (ROOT / 'build/flappy.prg').read_bytes()
cpu = MPU()
base = int.from_bytes(prg[:2], 'little')
cpu.memory[base:base + len(prg) - 2] = prg[2:]


def put(name, value):
    cpu.memory[SYMBOLS[name]] = value


def call(name):
    cpu.sp = 0xff
    cpu.stPushWord(0x02ff)
    cpu.pc = SYMBOLS[name]
    for _ in range(100000):
        cpu.step()
        if cpu.pc == 0x0300:
            return
    raise AssertionError(f'{name} did not return')


count = 0
for world in (0, 9, 10, 11, 12, 13, 14, 15, 31):
    for phase in range(8):
        call('initialise_video')
        put('WORLD_COLUMN', world)
        put('SCROLL_OFFSET', phase)
        call('render_playfield')
        call('initialise_bird')
        screen = bytes(cpu.memory[0xc00:0xfe8])
        for y in range(256):
            put('BIRD_Y_POSITION', y)
            call('check_bird_collision')
            # Independent world-geometry oracle, including the renderer's
            # full three-row footprint and next frame's horizontal phase.
            next_world = (world + (phase == 0)) & 255
            width = 2 if phase == 0 else 3
            expected = y > 159 or any(
                24 <= ((next_world + col) & 31) < 27
                and (1 <= row <= 6 or 16 <= row <= 21)
                for col in range(12, 12 + width)
                for row in range(y // 8, y // 8 + 3)
            )
            assert bool(cpu.p & cpu.CARRY) == expected, (world, phase, y)
            assert bytes(cpu.memory[0xc00:0xfe8]) == screen
            assert cpu.memory[SYMBOLS['SCROLL_OFFSET']] == phase
            count += 1

# Exercise the actual loop through a floor hit and explicit restart.
# Raster/input are supplied by the harness; no TED timing is simulated.
for name in ('wait_for_frame', 'read_input', 'commit_video_ptr'):
    cpu.memory[SYMBOLS[name]] = 0x60
cpu.pc = SYMBOLS['start']


def frame():
    cpu.step()
    for _ in range(150000):
        if cpu.pc == SYMBOLS['main_loop']:
            return
        cpu.step()
    raise AssertionError('frame did not complete')


frame()
for _ in range(100):
    before = bytes(cpu.memory[0x800:0x1000]), bytes(cpu.memory[0x1800:0x2000])
    old_y = cpu.memory[SYMBOLS['BIRD_Y_POSITION']]
    old_scroll = cpu.memory[SYMBOLS['SCROLL_OFFSET']]
    frame()
    if cpu.memory[SYMBOLS['GAME_OVER']]:
        assert before == (bytes(cpu.memory[0x800:0x1000]), bytes(cpu.memory[0x1800:0x2000]))
        assert cpu.memory[SYMBOLS['BIRD_Y_POSITION']] == old_y
        assert cpu.memory[SYMBOLS['SCROLL_OFFSET']] == old_scroll
        break
else:
    raise AssertionError('fall did not cause game over')
for _ in range(3):
    frame()
    assert before == (bytes(cpu.memory[0x800:0x1000]), bytes(cpu.memory[0x1800:0x2000]))
put('FLAP_PRESSED', 1)
frame()
assert cpu.memory[SYMBOLS['GAME_OVER']] == 0
assert cpu.memory[SYMBOLS['BIRD_Y_POSITION']] == 80
assert cpu.memory[SYMBOLS['SCROLL_OFFSET']] == 7
print(f'{count} collision cases passed; freeze and restart passed')
