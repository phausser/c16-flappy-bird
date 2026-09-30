"""Execute the assembled code with py65: make && python tests/collision.py.

The oracle checks each source-mask pixel against world rectangles. It does
not use the assembly routine's glyph occupancy or screen-cell algorithm.
TED raster timing is not emulated here.
"""
import re
from pathlib import Path

from py65.devices.mpu6502 import MPU

ROOT = Path(__file__).resolve().parents[1]
SYMBOLS = {name: int(value, 16) for name, value in re.findall(
    r'^\s*(\w+)\s*=\s*\$([0-9a-f]+)',
    (ROOT / 'build/flappy.sym').read_text(), re.M)}
prg = (ROOT / 'build/flappy.prg').read_bytes()
cpu = MPU()
base = int.from_bytes(prg[:2], 'little')
cpu.memory[base:base + len(prg) - 2] = prg[2:]


def put(name, value):
    cpu.memory[SYMBOLS[name]] = value & 255


def get(name):
    return cpu.memory[SYMBOLS[name]]


def call(name):
    cpu.sp = 0xff
    cpu.stPushWord(0x02ff)
    cpu.pc = SYMBOLS[name]
    cycles = cpu.processorCycles
    for _ in range(150000):
        cpu.step()
        if cpu.pc == 0x0300:
            return cpu.processorCycles - cycles
    raise AssertionError(f'{name} did not return')


def mask(name):
    address = SYMBOLS[name]
    put('MASK_POINTER', address)
    cpu.memory[SYMBOLS['MASK_POINTER'] + 1] = address >> 8


MASKS = ('BIRD_MASK_UP', 'BIRD_MASK_MID', 'BIRD_MASK_DOWN', 'BIRD_MASK_DIVE')
PIXELS = {}
for name in MASKS:
    data = cpu.memory[SYMBOLS[name]:SYMBOLS[name] + 32]
    PIXELS[name] = [(x, y) for y in range(16) for x in range(16)
                    if data[y * 2 + x // 8] & (128 >> (x % 8))]


def oracle(name, bird_y, world, phase, pending):
    next_phase = (phase - pending) % 8
    next_world = world + (pending and phase == 0)
    for x, y in PIXELS[name]:
        py = bird_y + y
        col = 12 + (7 - next_phase + x) // 8
        if py < 0 or py >= 176:
            return True
        if 24 <= (next_world + col) % 32 < 27 and (8 <= py < 56 or 128 <= py < 176):
            return True
    return False


def scene(world=0, phase=7):
    call('initialise_video')
    put('WORLD_COLUMN', world)
    put('SCROLL_OFFSET', phase)
    call('render_playfield')
    call('mirror_playfield_to_back')
    call('prime_back_buffer')
    put('GAME_OVER', 0)
    put('FLAP_PRESSED', 0)
    call('initialise_bird')


def screen_state():
    return (bytes(cpu.memory[0x800:0x1000]),
            bytes(cpu.memory[0x1800:0x2000]),
            bytes(cpu.memory[0x3400:0x3c00]))


count = 0
# Edge neighborhoods include every vertical offset; all horizontal phases,
# masks, both scroll choices, and pipes on either side of the bird.
ys = list(range(-5, 9)) + list(range(38, 58)) + list(range(109, 131)) + list(range(158, 178))
for world in (0, 9, 10, 11, 12, 13, 14, 15, 31):
    for phase in range(8):
        scene(world, phase)
        before = screen_state()
        for name in MASKS:
            mask(name)
            for pending in (0, 1):
                put('SCROLL_PENDING', pending)
                for y in ys:
                    put('BIRD_Y_POSITION', y)
                    call('compose_bird')
                    call('check_bird_collision')
                    assert bool(cpu.p & cpu.CARRY) == oracle(name, y, world, phase, pending), (name, world, phase, pending, y)
                    assert screen_state() == before, 'trial touched live display'
                    count += 1
print(f'{count} pixel-oracle collision cases passed', flush=True)

# Every safe edge position must preserve obstacle glyphs AND colors when
# painted, then restore the complete screen when erased (including row -1).
render_count = 0
for world in (0, 12):
    for phase in range(8):
        scene(world, phase)
        call('clear_bird')
        clean = bytes(cpu.memory[0x800:0x1000])
        for name in MASKS:
            mask(name)
            for y in ys:
                if oracle(name, y, world, phase, 0):
                    continue
                put('BIRD_Y_POSITION', y)
                put('SCROLL_PENDING', 0)
                call('compose_bird')
                call('render_bird')
                for i in range(1000):
                    if clean[0x400 + i] != 0:
                        assert cpu.memory[0xc00 + i] == clean[0x400 + i]
                        assert cpu.memory[0x800 + i] == clean[i]
                # Reconstruct the actual displayed bird pixels, independently
                # of the glyph allocation (including negative top rows).
                actual = set()
                for row in range(25):
                    for col in range(12, 15):
                        glyph = cpu.memory[0xc00 + row * 40 + col]
                        if 4 <= glyph <= 12:
                            for line in range(8):
                                bits = cpu.memory[0x3400 + glyph * 8 + line]
                                for bit in range(8):
                                    if bits & (128 >> bit):
                                        actual.add((col * 8 + bit + phase, row * 8 + line))
                expected = {(103 + x, y + dy) for x, dy in PIXELS[name]}
                assert actual == expected, (name, y, phase)
                call('clear_bird')
                assert bytes(cpu.memory[0x800:0x1000]) == clean
                render_count += 1
print(f'{render_count} render/restore cases passed', flush=True)

# CPU-only frame harness: keep input/raster externally controlled.
for name in ('wait_for_frame', 'read_input', 'commit_video_ptr'):
    cpu.memory[SYMBOLS[name]] = 0x60


def frame():
    cpu.pc = SYMBOLS['main_loop']
    cycles = cpu.processorCycles
    cpu.step()
    for _ in range(150000):
        if cpu.pc == SYMBOLS['main_loop']:
            return cpu.processorCycles - cycles
        cpu.step()
    raise AssertionError('frame did not complete')


def position(y, velocity, name):
    call('clear_bird')
    put('BIRD_Y_POSITION', y)
    put('BIRD_Y_FRACTION', 0)
    put('BIRD_VELOCITY', velocity)
    put('BIRD_VELOCITY_FRACTION', 0)
    mask(name)
    call('compose_bird')
    call('render_bird')


max_cycles = 0
# Fast downward and upward movement stops partway through the proposed step.
for world, start, velocity, expected, name in (
    (0, 162, 3, 163, 'BIRD_MASK_DIVE'),
    (12, 114, 3, 115, 'BIRD_MASK_DIVE'),
    (12, 54, -2, 53, 'BIRD_MASK_UP'),
    (0, -2, -2, -3, 'BIRD_MASK_UP'),
):
    for phase in range(8):
        scene(world, phase)
        position(start, velocity, name)
        max_cycles = max(max_cycles, frame())
        assert get('GAME_OVER') == 1, (world, start, phase)
        assert get('BIRD_Y_POSITION') == expected & 255
        assert get('SCROLL_OFFSET') == phase
        assert get('BIRD_VELOCITY') == 0
        frozen = screen_state()
        frame()
        assert screen_state() == frozen
        put('FLAP_PRESSED', 1)
        frame()
        assert get('GAME_OVER') == 0 and get('BIRD_Y_POSITION') == 80
        assert get('SCROLL_OFFSET') == 7

# A downward wing pose would intersect the pipe; retain the safe old pose.
scene(12)
position(115, 0, 'BIRD_MASK_MID')
put('BIRD_ANIM_TIMER', 15)
frame()
assert get('GAME_OVER') == 0
assert get('MASK_POINTER') == SYMBOLS['BIRD_MASK_MID'] & 255

# Fly horizontally into a pipe. At impact the last visible pixel is exactly
# one pixel left of its solid cell face, and a further scroll is rejected.
for initial_world in range(8):
    scene(initial_world, 7)
    position(32, 0, 'BIRD_MASK_MID')
    for _ in range(200):
        put('BIRD_VELOCITY', 0)
        put('BIRD_VELOCITY_FRACTION', 0)
        put('BIRD_Y_FRACTION', 0)
        max_cycles = max(max_cycles, frame())
        if get('GAME_OVER'):
            break
    else:
        raise AssertionError('pipe was not hit')
    world, phase = get('WORLD_COLUMN'), get('SCROLL_OFFSET')
    assert not oracle('BIRD_MASK_MID', 32, world, phase, 0)
    assert oracle('BIRD_MASK_MID', 32, world, phase, 1)
    pipe_col = next(col for col in range(12, 40) if 24 <= (world + col) % 32 < 27)
    assert pipe_col * 8 + phase == 119
print(f'Sweep, contact, animation, freeze and restart passed; max frame CPU cycles: {max_cycles}')
