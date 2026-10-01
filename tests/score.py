"""Score placement, one point per pipe, and the unmoving floor row.

Run after `make`.
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
    for _ in range(200000):
        cpu.step()
        if cpu.pc == 0x0300:
            return
    raise AssertionError(f'{name} did not return')


def score_value():
    return cpu.memory[SYMBOLS['SCORE']] | (cpu.memory[SYMBOLS['SCORE'] + 1] << 8)


def set_score(value):
    put('SCORE', value)
    cpu.memory[SYMBOLS['SCORE'] + 1] = value >> 8


def score_cells(value):
    glyphs = [0] * 40
    inks = [0] * 40
    high = cpu.memory[SYMBOLS['HIGH_SCORE']] | (cpu.memory[SYMBOLS['HIGH_SCORE'] + 1] << 8)
    title = 'PRESS SPACE' if cpu.memory[SYMBOLS['GAME_OVER']] else 'TEDDY BIRD'
    labels = [(1, f'HIGH {high:04d}'), (39 - len(f'SCORE {value:04d}'), f'SCORE {value:04d}')]
    if not cpu.memory[SYMBOLS['GAME_OVER']] or not cpu.memory[SYMBOLS['HUD_BLINK']]:
        labels.append((1 + (38 - len(title)) // 2, title))
    for start, label in labels:
        for col, char in enumerate(label, start):
            glyphs[col] = (0 if char == ' ' else SYMBOLS['GLYPH_DIGIT_0'] + int(char)
                           if char.isdigit() else SYMBOLS['GLYPH_LETTER_A'] + ord(char) - ord('A'))
            inks[col] = SYMBOLS['TED_SCORE_COLOR'] if char != ' ' or label == title else 0
    return glyphs, inks


def row(page):
    return bytes(cpu.memory[page + 24 * 40:page + 25 * 40])


def expect_score(value):
    glyphs, inks = score_cells(value)
    for page, colors in ((0x0c00, 0x0800), (0x1c00, 0x1800)):
        assert row(page) == bytes(glyphs), (value, page)
        assert bytes(cpu.memory[colors + 24 * 40:colors + 25 * 40]) == bytes(inks)
    assert SYMBOLS['TED_SCORE_COLOR'] & 0x08 == 0


def boot():
    for name in ('wait_for_frame', 'read_input', 'commit_video_ptr'):
        cpu.memory[SYMBOLS[name]] = 0x60
    call('initialise_video')
    call('initialise_obstacles')
    call('render_playfield')
    call('mirror_playfield_to_back')
    call('prime_back_buffer')


boot()
assert score_value() == 0
expect_score(0)
# The zero sits low in the cell: three blank rows, then a two-pixel stem.
# Catches a shifted glyph address.
zero = SYMBOLS['CHARSET_RAM'] + SYMBOLS['GLYPH_DIGIT_0'] * 8
assert list(cpu.memory[zero:zero + 8]) == [0x00, 0x00, 0x00, 0x7e, 0x66, 0x66, 0x66, 0x7e]

for value in (9, 10, 100, 999, 1000, 9999, 10000, 65535):
    set_score(value)
    call('render_score')
    expect_score(value)
print('zero-padded HIGH and SCORE stay aligned through the full 16-bit range', flush=True)

set_score(0)
call('render_score')
floor = row(0x0c00)
for _ in range(7):
    call('advance_scroll')
assert get('WORLD_COLUMN') == 0
assert row(0x0c00) == floor and row(0x1c00) == floor
print('seven scroll steps leave the score row unmoved', flush=True)

# Right pipe edges are world columns 26, 38, 50, ... The award fires when
# WORLD_COLUMN becomes that column minus 11. The boot ring holds 40 columns;
# extend it so the third pipe is present.
for _ in range(24):
    call('generate_obstacle_column')
scored = []
previous = 0
for _ in range(40):
    footer_before = row(0x0c00), row(0x1c00)
    call('swap_buffers')
    assert (row(0x0c00), row(0x1c00)) == footer_before, 'flip drew the footer'
    if score_value() != previous:
        assert get('HUD_DIRTY') == 1
    call('refresh_footer')
    assert get('HUD_DIRTY') == 0
    current = score_value()
    if current != previous:
        scored.append(get('WORLD_COLUMN'))
        assert current == previous + 1
        previous = current
assert scored == [15, 27, 39], scored
expect_score(3)
print('one point per passed pipe, none on the columns in between', flush=True)

# The same wrap would score, but a floor hit skips the scroll.
set_score(0)
boot()
call('initialise_bird')
put('WORLD_COLUMN', 14)
put('SCROLL_OFFSET', 0)
put('FLIP_READY', 1)
put('BIRD_Y_POSITION', 180)
put('BIRD_VELOCITY', 0)
put('BIRD_VELOCITY_FRACTION', 0)
put('BIRD_Y_FRACTION', 0)
put('GAME_OVER', 0)
cpu.pc = SYMBOLS['main_loop']
cpu.step()
for _ in range(200000):
    if cpu.pc == SYMBOLS['main_loop']:
        break
    cpu.step()
else:
    raise AssertionError('contact frame did not finish')
assert get('GAME_OVER') == 1
bird_cells = [col for col in range(24 * 40)
              if SYMBOLS['GLYPH_BIRD_LEFT_ROW0'] <= cpu.memory[0x0c00 + col] <= SYMBOLS['GLYPH_BIRD_LAST']]
assert bird_cells
assert all(cpu.memory[0x0800 + col] == 0x62 for col in bird_cells)
assert score_value() == 0
assert get('SCROLL_OFFSET') == 0 and get('FLIP_READY') == 1
print('contact on the scoring frame awards nothing', flush=True)

set_score(250)
cpu.pc = SYMBOLS['start']
for _ in range(300000):
    if cpu.pc == SYMBOLS['main_loop']:
        break
    cpu.step()
else:
    raise AssertionError('restart did not reach the main loop')
assert score_value() == 0
expect_score(0)
print('restart paints 0 in both buffers', flush=True)

# Best score survives a round restart; the title returns immediately.
put('HIGH_SCORE', 65)
cpu.memory[SYMBOLS['HIGH_SCORE'] + 1] = 1  # 321
put('GAME_OVER', 1)
put('HUD_BLINK', 0)
put('HUD_TIMER', 0)
call('render_score')
expect_score(0)
visible = row(0x0c00)
for _ in range(24):
    call('update_footer_blink')
assert row(0x0c00) == visible
call('update_footer_blink')
expect_score(0)
assert row(0x0c00)[14:25] == bytes(11)
assert row(0x0c00)[:14] == visible[:14]
assert row(0x0c00)[25:] == visible[25:]
for _ in range(25):
    call('update_footer_blink')
assert row(0x0c00) == visible
put('FLAP_PRESSED', 1)
cpu.pc = SYMBOLS['main_loop']
cpu.step()
for _ in range(300000):
    if cpu.pc == SYMBOLS['main_loop']:
        break
    cpu.step()
else:
    raise AssertionError('round restart did not finish')
assert get('GAME_OVER') == get('HUD_BLINK') == get('HUD_TIMER') == 0
bird_cells = [col for col in range(24 * 40)
              if SYMBOLS['GLYPH_BIRD_LEFT_ROW0'] <= cpu.memory[0x0c00 + col] <= SYMBOLS['GLYPH_BIRD_LAST']]
assert bird_cells and all(cpu.memory[0x0800 + col] == SYMBOLS['TED_BIRD_COLOR'] for col in bird_cells)
assert cpu.memory[SYMBOLS['HIGH_SCORE']] | cpu.memory[SYMBOLS['HIGH_SCORE'] + 1] << 8 == 321
expect_score(0)
set_score(322)
call('render_score')
assert cpu.memory[SYMBOLS['HIGH_SCORE']] | cpu.memory[SYMBOLS['HIGH_SCORE'] + 1] << 8 == 322
expect_score(322)
print('centered title, 25-frame blinking, round persistence and dead/live bird colors passed')

# Scoring must preserve the title and playfield and fit a short update.
put('GAME_OVER', 0)
set_score(1233)
call('render_score')
before_screen = [bytes(cpu.memory[page:page + 24 * 40]) for page in (0x0c00, 0x1c00)]
before_title = [row(page)[14:25] for page in (0x0c00, 0x1c00)]
set_score(1234)
put('HUD_DIRTY', 1)
cycles = cpu.processorCycles
call('refresh_footer')
cycles = cpu.processorCycles - cycles
assert cycles < 3000, cycles
expect_score(1234)
assert before_screen == [bytes(cpu.memory[page:page + 24 * 40]) for page in (0x0c00, 0x1c00)]
assert before_title == [row(page)[14:25] for page in (0x0c00, 0x1c00)]
for value in (9999, 10000, 65535):
    set_score(value)
    put('HUD_DIRTY', 1)
    call('refresh_footer')
    expect_score(value)
print(f'incremental score refresh preserves playfield/title: {cycles} CPU cycles at 1234')
