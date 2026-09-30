"""CPU regression: deterministic obstacles, full scrolling, and playable gaps."""
import re
from pathlib import Path
from py65.devices.mpu6502 import MPU

ROOT = Path(__file__).resolve().parents[1]
S = {n: int(v, 16) for n, v in re.findall(r'^\s*(\w+)\s*=\s*\$([0-9a-f]+)',
                                        (ROOT / 'build/flappy.sym').read_text(), re.M)}
cpu = MPU()
prg = (ROOT / 'build/flappy.prg').read_bytes()
start = int.from_bytes(prg[:2], 'little')
cpu.memory[start:start + len(prg) - 2] = prg[2:]


def get(name):
    return cpu.memory[S[name]]


def put(name, value):
    cpu.memory[S[name]] = value & 255


def call(name):
    cpu.sp = 255
    cpu.stPushWord(0x2ff)
    cpu.pc = S[name]
    for _ in range(150000):
        cpu.step()
        if cpu.pc == 0x300:
            return
    raise AssertionError(name)


# Independent descriptor model: generate complete pipes, not columns or a
# ring. Absolute positions remain unbounded while the game wraps its bytes.
def model(length):
    columns = [0] * length
    seed, gap = 0x5d, 7
    gaps = []
    for index, x in enumerate(range(24, length, 24)):
        if index:
            seed = ((seed << 1) ^ (0x1d if seed & 128 else 0)) & 255
            gap = max(4, min(10, gap + (-2, -1, 1, 2)[seed & 3]))
        gaps.append(gap)
        for col in range(x, min(x + 3, length)):
            columns[col] = gap
    return columns, gaps


columns, gaps = model(4096)
assert len(set(gaps)) == 7
assert all(abs(a-b) <= 2 for a, b in zip(gaps, gaps[1:]))
for repeat in range(2):
    call('initialise_obstacles')
    assert cpu.memory[S['OBSTACLE_BUFFER_RAM']:S['OBSTACLE_BUFFER_RAM'] + 40] == columns[:40]
    for col in range(40, len(columns)):
        assert get('PIPE_WRITE_INDEX') == col % 64
        call('generate_obstacle_column')
        assert cpu.memory[S['OBSTACLE_BUFFER_RAM'] + col % 64] == columns[col]
print('4096 columns match the model on both restarts; all 7 heights reached', flush=True)


def expected_cell(world, row, col):
    gap = columns[world + col]
    if gap and (row < gap or row >= gap + 9):
        glyph = S['GLYPH_PIPE_CAP'] if row in (gap - 1, gap + 9) else S['GLYPH_PIPE_BODY']
        return glyph, S['TED_PIPE_COLOR']
    return S['GLYPH_SKY'], S['TED_SKY_COLOR']


def check_buffer(world, screen, color, bird=False):
    for row in range(25):
        for col in range(40):
            glyph, ink = expected_cell(world, row, col)
            address = row * 40 + col
            actual = cpu.memory[screen + address]
            if bird and 4 <= actual <= 15:
                assert glyph == 0, ('bird overwrote pipe', world, row, col)
            else:
                assert (actual, cpu.memory[color + address]) == (glyph, ink), (world, row, col)


cpu.memory[S['commit_video_ptr']] = 0x60
call('initialise_video')
call('initialise_obstacles')
call('render_playfield')
call('mirror_playfield_to_back')
call('prime_back_buffer')
check_buffer(0, 0xc00, 0x800)
for frame in range(1024 * 8):
    call('advance_scroll')
    world = (frame + 1) // 8
    if get('SCROLL_OFFSET') == 0:
        check_buffer(world + 1, get('BACK_SCREEN_HI') << 8, get('BACK_COLOR_HI') << 8)
    if get('SCROLL_OFFSET') == 7:
        check_buffer(world, get('VISIBLE_SCREEN_HI') << 8, get('VISIBLE_COLOR_HI') << 8)
        assert get('WORLD_COLUMN') == world % 256
        assert get('PIPE_WRITE_INDEX') == (world + 40) % 64
print('1024 buffer flips passed: glyphs, colors, ring and world-counter wrap', flush=True)

# Exercise actual game physics/rendering with a deterministic simple pilot.
# Aim inside the nearest pipe, allowing room for the approximately 22-pixel
# ascent after a flap. This also tests the larger copy slices with bird erase.
for name in ('wait_for_frame', 'read_input'):
    cpu.memory[S[name]] = 0x60
cpu.pc = S['start']


def run_to_loop():
    for _ in range(150000):
        if cpu.pc == S['main_loop']:
            return
        cpu.step()
    raise AssertionError('main loop timeout')


run_to_loop()
world = 0
for frame in range(3000):
    next_gap = next(columns[world + col] for col in range(12, 40) if columns[world + col])
    put('FLAP_PRESSED', int(get('BIRD_Y_POSITION') > next_gap * 8 + 40))
    cpu.step()
    run_to_loop()
    assert not get('GAME_OVER'), ('autoplay collision', frame, world, get('BIRD_Y_POSITION'), next_gap)
    world = (frame + 1) // 8
    if frame % 8 == 7:
        check_buffer(world, get('VISIBLE_SCREEN_HI') << 8, get('VISIBLE_COLOR_HI') << 8, bird=True)
print('3000 gameplay frames passed with variable gaps and intact environment')
