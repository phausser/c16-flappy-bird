"""Sound effect lengths, replacement, silence and preserved TED bits.

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


class Memory(list):
    """RAM whose TED keyboard latch reads back the simulated Space key."""
    space = False

    def __getitem__(self, index):
        if index == SYMBOLS['TED_KEYBOARD'] and self.space:
            return 0xff ^ SYMBOLS['SPACE_KEY_COLUMN_MASK']
        return super().__getitem__(index)


cpu = MPU(memory=Memory([0] * 0x10000))
base = int.from_bytes(prg[:2], 'little')
cpu.memory[base:base + len(prg) - 2] = prg[2:]

CONTROL = SYMBOLS['TED_SOUND_CTRL']
MISC = SYMBOLS['TED_MISC']
FREQ2_HI = SYMBOLS['TED_FREQ2_HI']
# Frames each effect sounds, from the step data (silent rests included).
LENGTHS = {'SOUND_FLAP': 10, 'SOUND_POINT': 7, 'SOUND_DEATH': 24}


def call(name):
    cpu.sp = 0xff
    cpu.stPushWord(0x02ff)
    cpu.pc = SYMBOLS[name]
    cycles = cpu.processorCycles
    for _ in range(2000):
        cpu.step()
        if cpu.pc == 0x0300:
            return cpu.processorCycles - cycles
    raise AssertionError(f'{name} did not return')


def request(name):
    cpu.memory[SYMBOLS['SOUND_REQUEST']] = SYMBOLS[name]


def frames_until_silent():
    """Ticks until the effect writes its end; the first tick starts it."""
    for frame in range(1, 300):
        call('sound_tick')
        if cpu.memory[SYMBOLS['sound_delay']] == 0:
            assert cpu.memory[CONTROL] == 0
            return frame - 1
    raise AssertionError('effect never ended')


cpu.memory[MISC] = 0xc8
cpu.memory[FREQ2_HI] = 0xfc
call('sound_silence')
assert cpu.memory[CONTROL] == 0
call('sound_tick')
assert cpu.memory[CONTROL] == 0

worst = 0
for name, length in LENGTHS.items():
    request(name)
    assert frames_until_silent() == length, name
    assert cpu.memory[SYMBOLS['SOUND_REQUEST']] == 0
    assert cpu.memory[MISC] & 0xfc == 0xc8, name
    assert cpu.memory[FREQ2_HI] & 0xfc == 0xfc, name
    request(name)
    for _ in range(length):
        worst = max(worst, call('sound_tick'))

# A new request replaces the playing effect at once.
request('SOUND_DEATH')
call('sound_tick')
call('sound_tick')
request('SOUND_POINT')
assert frames_until_silent() == LENGTHS['SOUND_POINT']

# A round start cuts an effect and drops a pending request.
request('SOUND_DEATH')
call('sound_tick')
assert cpu.memory[CONTROL] != 0
request('SOUND_FLAP')
call('sound_silence')
call('sound_tick')
assert cpu.memory[CONTROL] == 0
assert cpu.memory[SYMBOLS['sound_delay']] == 0

assert worst < 250, worst


def frame(space):
    cpu.memory.space = space
    cpu.memory[SYMBOLS['TED_KEYBOARD']] = 0xff
    call('read_input')
    return cpu.memory[SYMBOLS['FLAP_PRESSED']]


# Playing: a press flaps at once and starts the flap sound.
cpu.memory[SYMBOLS['GAME_OVER']] = 0
call('initialise_input')
assert frame(True) and cpu.memory[CONTROL] != 0
assert not frame(True)
frame(False)

# Dead: Space restarts only after the crash sound, and only with a new press.
cpu.memory[SYMBOLS['GAME_OVER']] = SYMBOLS['GAME_STATE_DEAD']
request('SOUND_DEATH')
for count in range(LENGTHS['SOUND_DEATH']):
    assert not frame(count % 2 == 1)
    assert cpu.memory[SYMBOLS['sound_delay']] != 0
assert not frame(True)
assert cpu.memory[SYMBOLS['sound_delay']] == 0
frame(False)
assert frame(True)

# Waiting: no sound plays, so the first press starts the round.
cpu.memory[SYMBOLS['GAME_OVER']] = SYMBOLS['GAME_STATE_WAITING']
frame(False)
assert frame(True) and cpu.memory[CONTROL] == 0
print(f'sound: 3 effects, crash blocks restart, worst tick {worst} cycles')
