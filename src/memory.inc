; Stock C16 memory map. The program and charset deliberately stay below $4000,
; the first BASIC ROM address on a 16 KiB machine.
;
; $0004-$000d  Scroll state, column-update marker, and screen-copy pointers
; $0100-$01ff  CPU stack
; $0800-$0be7  TED screen RAM (the remaining 24 bytes are harmless padding)
; $0c00-$0fff  TED color RAM
; $1001-$2fff  Program code, static assets and future game state
; $3000-$33ff  Reserved for obstacle ring buffer and renderer work data
; $3400-$3bff  RAM-resident 256-glyph character set
; $3c00-$3fff  1 KiB safety reserve

SCREEN_RAM = $0800
COLOR_RAM = $0c00
SCREEN_SIZE = 1000
SCREEN_PAGE_COUNT = 4

GAME_STATE_RAM = $3000
OBSTACLE_BUFFER_RAM = $3100
CHARSET_RAM = $3400
CHARSET_SIZE = $0800
RAM_RESERVE_START = $3c00
RAM_RESERVE_SIZE = $0400

PROGRAM_START = $1001
CODE_START = $100d

SCROLL_OFFSET = $04
WORLD_COLUMN = $05
COLUMN_UPDATE_COUNTER = $06
SCREEN_DESTINATION = $08
SCREEN_SOURCE = $0a
