"""IRQ state regression; optionally validate a PAL VICE color-store trace.

Record with monitor commands `trace store ff19`, `trace store ff15`, `x`.
Pass the resulting -monlogname file as the first argument. CPU emulation
alone cannot validate TED bus steals or the horizontal blank timing.
"""
import re
import sys
from collections import Counter
from pathlib import Path
from py65.devices.mpu6502 import MPU

ROOT = Path(__file__).resolve().parents[1]
S = {n: int(v, 16) for n, v in re.findall(r'^\s*(\w+)\s*=\s*\$([0-9a-f]+)',
                                        (ROOT / 'build/flappy.sym').read_text(), re.M)}
COLORS = [0x1d, 0x2d, 0x3d, 0x4d, 0x5d, 0x6d, 0x7d, 0x59, 0x0d]
LINES = [2, 33, 62, 90, 118, 145, 175, 204, 275]


class Memory(list):
    horizontal = 0

    def __getitem__(self, addr):
        if addr == 0xff1e:
            # Cross the threshold once; real timing is checked with VICE.
            self.horizontal ^= 1
            return 0 if self.horizontal else 0xa0
        return super().__getitem__(addr)


cpu = MPU(memory=Memory([0] * 65536))
prg = (ROOT / 'build/flappy.prg').read_bytes()
start = int.from_bytes(prg[:2], 'little')
cpu.memory[start:start + len(prg) - 2] = prg[2:]
for restart in range(2):
    cpu.sp = 255
    cpu.stPushWord(0x2ff)
    cpu.pc = S['initialise_background_gradient']
    for _ in range(100):
        cpu.step()
        if cpu.pc == 0x300:
            break
    else:
        raise AssertionError('initialization did not return')
    assert cpu.WordAt(0xfffe) == S['background_gradient_irq']
    for event in range(27):
        index = event % 9
        compare = cpu.memory[0xff0b] | ((cpu.memory[0xff0a] & 1) << 8)
        assert compare == LINES[index] - 1
        assert cpu.memory[0xff0a] & 0xfe == 2
        cpu.a, cpu.x, cpu.y = (event * 17) & 255, 255 - event, event * 7
        cpu.p = 0x30 | (event & 0xcb)  # Vary N/V/D/Z/C; IRQ enabled.
        cpu.pc = 0x300
        saved = cpu.a, cpu.x, cpu.y, cpu.p, cpu.sp
        cpu.irq()
        for _ in range(100):
            cpu.step()
            if cpu.pc == 0x300:
                break
        else:
            raise AssertionError('IRQ did not return')
        assert (cpu.a, cpu.x, cpu.y, cpu.p, cpu.sp) == saved
        assert cpu.memory[0xff19] == cpu.memory[0xff15] == COLORS[index]
print('IRQ preserves registers, flags and stack; 9-bit sequence and restart passed')

if len(sys.argv) > 1:
    trace = Path(sys.argv[1]).read_text()
    stores = {S['gradient_color'] + 2: 'ff19', S['gradient_color'] + 5: 'ff15'}
    counts = Counter()
    pattern = (r'Trace store (ff19|ff15)\)\s+(\d+)/\$\w+,\s+(\d+)/\$\w+'
               r'\n.C:(\w+) .*?A:(\w+)')
    for reg, line, cycle, pc, color in re.findall(pattern, trace):
        if int(pc, 16) not in stores:
            continue  # Exclude KERNAL boot and video initialization.
        assert stores[int(pc, 16)] == reg
        index = COLORS.index(int(color, 16))
        # Normalize the preceding line's right blank to negative cycles.
        offset = (int(line) - LINES[index]) * 114 + int(cycle)
        # Border visible from cycle 7; character window from cycle 15.
        assert (-10 <= offset <= 5 if reg == 'ff19' else -10 <= offset <= 13), (
            reg, line, cycle, color)
        counts[reg, index] += 1
    assert len(counts) == 18 and min(counts.values()) >= 100, counts
    print(f'{sum(counts.values())} VICE color writes passed blank-window checks')
