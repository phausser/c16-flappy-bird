; Stock C16 memory map. The program and charset deliberately stay below $4000,
; the first BASIC ROM address on a 16 KiB machine.
;
; $0004-$003f  Scroll state, buffer pointers, screen-copy pointers, and
;              bird physics/rendering state
; $0100-$01ff  CPU stack
; $0800-$0bff  Front color RAM (TED, paired with the screen below)
; $0c00-$0fe7  Front screen RAM (the remaining 24 bytes are harmless padding)
; $1001-$17ff  Program code and static assets
; $1800-$1be7  Back color RAM. The scroll builds the next frame here.
; $1c00-$1fe7  Back screen RAM. $FF14 flips to this pair in the border.
; $2000-$2fff  Free for future game state
; $3000-$33ff  Reserved for obstacle ring buffer and renderer work data
; $3400-$3bff  RAM-resident 256-glyph character set
; $3c00-$3fff  1 KiB safety reserve

SCREEN_RAM = $0c00
COLOR_RAM = $0800
; Second TED text buffer. $FF14 bit 3 steps the pair by 2 KiB, and $18
; selects color at $1800 with the screen at $1c00. The front pair is $0c,
; which the same mask resolves to color $0800 and screen $0c00.
BACK_COLOR_RAM = $1800
BACK_SCREEN_RAM = $1c00
FRONT_VIDEO_PTR = $0c
BACK_VIDEO_PTR = $18
SCREEN_SIZE = 1000
SCREEN_PAGE_COUNT = 4

GAME_STATE_RAM = $3000
GAME_OVER = GAME_STATE_RAM
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
; SCREEN_DESTINATION + 1 = $09
SCREEN_SOURCE = $0a
; SCREEN_SOURCE + 1 = $0b
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

; Which text buffer the TED is showing, and which one the scroll fills.
VISIBLE_SCREEN_HI = $25
VISIBLE_COLOR_HI = $26
BACK_SCREEN_HI = $27
BACK_COLOR_HI = $28
VISIBLE_FF14 = $29
BACK_FF14 = $2a
COPY_SLICE = $2b
TARGET_SCREEN_HI = $2c
TARGET_COLOR_HI = $2d
COLUMN_X = $2e
PIPE_HERE = $2f
ROW_INDEX = $30
CELL_GLYPH = $31
CELL_COLOR = $32
; Set once the hidden buffer holds the next column. The following frame's
; border stores $FF14; doing it in the same call as the column draw is late
; enough that the beam still paints the old matrix.
FLIP_READY = $33

; Snapshot of the third bird column, used only on frames where the
; counter-shift spills into it. BIRD_WIDE is the shift amount just painted
; (0 means the tail column was not placed). The four shift bytes are
; scratch while render_bird composes one mask row.
BIRD_UNDER_TAIL_GLYPH = $34
; BIRD_UNDER_TAIL_GLYPH .. +2 = $34-$36
BIRD_UNDER_TAIL_COLOR = $37
; BIRD_UNDER_TAIL_COLOR .. +2 = $37-$39
BIRD_WIDE = $3a
BIRD_H_SHIFT = $3b
BIRD_SHIFT_LEFT = $3c
BIRD_SHIFT_RIGHT = $3d
BIRD_SHIFT_TAIL = $3e
BIRD_SHIFT_COUNT = $3f
