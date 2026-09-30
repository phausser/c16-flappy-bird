; Stock C16 memory map. The program and charset deliberately stay below $4000,
; the first BASIC ROM address on a 16 KiB machine.
;
; $0004-$0024  Scroll state, column-update marker, screen-copy pointers, and
;              bird physics/rendering state
; $0100-$01ff  CPU stack
; $0800-$0bff  TED color RAM
; $0c00-$0fe7  TED screen RAM (the remaining 24 bytes are harmless padding)
; $1001-$2fff  Program code, static assets and future game state
; $3000-$33ff  Reserved for obstacle ring buffer and renderer work data
; $3400-$3bff  RAM-resident 256-glyph character set
; $3c00-$3fff  1 KiB safety reserve

SCREEN_RAM = $0c00
COLOR_RAM = $0800
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
FLAP_HELD = $0c
FLAP_PRESSED = $0d
BIRD_Y_FRACTION = $0e
BIRD_Y_POSITION = $0f
BIRD_VELOCITY_FRACTION = $10
BIRD_VELOCITY = $11
BIRD_PREV_ROW = $12
BIRD_TOP_ROW = $13
BIRD_ANIM_TIMER = $14
BIRD_ROW_COUNTER = $15
BIRD_SUB_Y = $16
MASK_POINTER = $17
; MASK_POINTER + 1 = $18

; Saved glyph/color pairs for the 3x2 cells the bird currently covers, so
; clear_bird can restore whatever playfield content (sky or pipe) was there
; instead of assuming sky.
BIRD_UNDER_GLYPH = $19
; BIRD_UNDER_GLYPH .. +5 = $19-$1e
BIRD_UNDER_COLOR = $1f
; BIRD_UNDER_COLOR .. +5 = $1f-$24
