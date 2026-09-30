#!/usr/bin/env python3
"""Check the assembler sources for style and name use.

- No tab indent, no trailing whitespace, a newline at the end of the file
- Opcodes are indented, never in column 0
- Every label is used somewhere, and so is every zero-page name
- Zero-page names do not share a byte. A following comment "+ N = $xx"
  marks a multi-byte value. The memory-map equates above the zero page,
  and the TED register list, may name space that later milestones use.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'src'

MNEMONICS = set('''
adc and asl bcc bcs beq bit bmi bne bpl brk bvc bvs clc cld cli clv cmp cpx cpy
dec dex dey eor inc inx iny jmp jsr lda ldx ldy lsr nop ora pha php pla plp rol
ror rti rts sbc sec sed sei sta stx sty tax tay tsx txa txs tya
'''.split())

# The BASIC stub starts the program at a numeric address, so this label has
# no symbolic use.
ENTRY_POINTS = {'start'}

IDENT = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
DEFINE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)(\s|$)')

errors = []


def error(path, num, text):
    errors.append(f'{path.relative_to(ROOT)}:{num}: {text}')


def code_part(line):
    """Line without comments and without strings."""
    line = re.sub(r'"[^"]*"', '""', line)
    return line.split(';', 1)[0]


def check_style(path, lines, text):
    if text and not text.endswith('\n'):
        error(path, len(lines), 'file does not end with a newline')
    for num, line in enumerate(lines, 1):
        if line != line.rstrip(' '):
            error(path, num, 'trailing whitespace')
        if '\t' in line:
            error(path, num, 'tab; indent with spaces')
        first = code_part(line).split()
        if first and line[:1] not in ' \t' and first[0].lower() in MNEMONICS:
            error(path, num, f'opcode "{first[0]}" is in column 0')


def collect(files):
    """Definitions (name -> file, line, value) and every use."""
    defined = {}
    used = set(ENTRY_POINTS)
    for path, lines in files:
        for num, line in enumerate(lines, 1):
            code = code_part(line)
            names = IDENT.findall(re.sub(r'\$[0-9A-Fa-f]+|%[01]+', '', code))
            match = DEFINE.match(code.strip()) if line[:1] not in ' \t' else None
            if match:
                defined[match.group(1)] = (path, num, match.group(2).strip())
                used.update(IDENT.findall(re.sub(r'\$[0-9A-Fa-f]+', '', match.group(2))))
                continue
            label = LABEL.match(code) if code[:1] not in ' \t!*+}' else None
            if label:
                defined[label.group(1)] = (path, num, None)
                names = names[1:]
            used.update(names)
    return defined, used


def zero_page(lines):
    """Assignments from SCROLL_OFFSET downward. Returns (name, line, addr, size)."""
    started = False
    found = []
    for index, line in enumerate(lines):
        code = code_part(line).strip()
        match = DEFINE.match(code) if line[:1] not in ' \t' else None
        if not match:
            continue
        name, value = match.group(1), match.group(2).strip()
        if name == 'SCROLL_OFFSET':
            started = True
        if not started or not re.fullmatch(r'\$[0-9A-Fa-f]{1,2}', value):
            continue
        size = 1
        if index + 1 < len(lines):
            span = re.search(r'\+\s*(\d+)\s*=', lines[index + 1])
            if lines[index + 1].lstrip().startswith(';') and span:
                size = int(span.group(1)) + 1
        found.append((name, index + 1, int(value[1:], 16), size))
    return found


def check_unused(defined, used, zp_names):
    for name, (path, num, value) in sorted(defined.items(), key=lambda item: (str(item[1][0]), item[1][1])):
        if name in used:
            continue
        if value is None or name in zp_names:
            error(path, num, f'"{name}" is never used')


def check_zero_page(path, lines):
    cells = {}
    for name, num, addr, size in zero_page(lines):
        for byte in range(addr, addr + size):
            if byte in cells:
                error(path, num, f'"{name}" overlaps "{cells[byte]}" at ${byte:02x}')
            cells[byte] = name
    return {name for name, _, _, _ in zero_page(lines)}


def main():
    files = []
    for path in sorted(SRC.glob('*.asm')) + sorted(SRC.glob('*.inc')):
        text = path.read_text()
        lines = text.splitlines()
        check_style(path, lines, text)
        files.append((path, lines))
    defined, used = collect(files)
    memory = next(path for path, _ in files if path.name == 'memory.inc')
    memory_lines = next(lines for path, lines in files if path.name == 'memory.inc')
    zp_names = check_zero_page(memory, memory_lines)
    check_unused(defined, used, zp_names)
    for line in errors:
        print(line)
    if errors:
        print(f'{len(errors)} finding(s)')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
