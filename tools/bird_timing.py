#!/usr/bin/env python3
"""Create a VICE top-bird timing probe; optionally check its monitor log.

Run after make. The probe holds Y=8 and clears vertical velocity at each
main-loop entry, allowing animation and scroll phases to advance normally.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
symbols = {name: int(value, 16) for name, value in re.findall(
    r'^\s*(\w+)\s*=\s*\$([0-9a-f]+)',
    (ROOT / 'build/flappy.sym').read_text(), re.M)}
commands = [f'trace exec {symbols["main_loop"]:04x}',
            f'command 1 "> {symbols["BIRD_Y_FRACTION"]:04x} 00 08 00 00"']
commands += [f'trace exec {symbols[name]:04x}'
             for name in ('clear_bird', 'render_bird', 'refresh_footer')]
commands.append('x')
(ROOT / 'build/bird-timing.mon').write_text('\n'.join(commands) + '\n')

if len(sys.argv) > 1:
    log = Path(sys.argv[1]).read_text()
    entries = re.findall(
        r'#4 \(Trace  exec .*?\)\s+(\d+)/\$\w+,\s+(\d+)/\$\w+\n'
        r'\.C:([0-9a-fA-F]+)', log)
    assert len(entries) >= 60, 'need at least 60 publication events'
    assert all(int(pc, 16) == symbols['refresh_footer'] for _, _, pc in entries)
    # Completion must precede the next active text fetch, including row 0.
    for line, cycle, _ in entries:
        assert symbols['RASTER_BORDER'] <= int(line) < 312, (line, cycle)
    print(f'{len(entries)} bird publications finished before the next visible frame; '
          f'latest raster line {max(int(line) for line, _, _ in entries)}')
