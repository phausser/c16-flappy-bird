; Stock C16 memory map. Program, buffers and charset stay below $4000,
; the end of the physical 16 KiB RAM (higher RAM addresses mirror it).
;
; $0004-$003f  Scroll state, buffer pointers, screen-copy pointers, and
;              bird physics/rendering state
; $0100-$01ff  CPU stack
; $0800-$0bff  Front color RAM (TED, paired with the screen below)
; $0c00-$0fe7  Front screen RAM (the remaining 24 bytes are harmless padding)
; $1001-$17ff  Program code. It must end before the hidden buffer.
; $1800-$1be7  Back color RAM. The scroll builds the next frame here.
; $1c00-$1fe7  Back screen RAM. $FF14 flips to this pair in the border.
; $2000-$2fff  Score drawing, then the imported bird masks
; $3000-$30de  Game state, candidate glyphs, saved cells, shifted-mask cache, score and HUD
; $3100-$313f  Gap start per world column, 64-column ring
; $3140-$3147  Generator state and renderer scratch
; $3148-$33ff  Reserved
; $3400-$3bff  Character-set storage; TED uses the lower 128 glyphs
; $3c00-$3ffd  Safety reserve
; $3ffe-$3fff  Hardware IRQ vector (16 KiB mirror of $fffe-$ffff)

SCREEN_RAM = $0c00
COLOR_RAM = $0800
; Second TED text buffer. $FF14 bit 3 steps the pair by 2 KiB, and $18
; selects color at $1800 with the screen at $1c00. The front pair is $0c,
; which the same mask resolves to color $0800 and screen $0c00.
BACK_COLOR_RAM = $1800
BACK_SCREEN_RAM = $1c00
FRONT_VIDEO_PTR = $0c
BACK_VIDEO_PTR = $18

GAME_STATE_RAM = $3000
; 0 = playing, GAME_STATE_DEAD = collision, GAME_STATE_WAITING = startup.
GAME_OVER = GAME_STATE_RAM
SCROLL_PENDING = GAME_STATE_RAM + 1
BIRD_TARGET_Y = GAME_STATE_RAM + 2
BIRD_STEP = GAME_STATE_RAM + 3
BIRD_OLD_MASK = GAME_STATE_RAM + 4
; Two bytes for the previous animation mask pointer.
BIRD_CANDIDATE = GAME_STATE_RAM + $10
; 96 glyph bytes, twelve occupancy flags and twelve saved glyph/color pairs.
BIRD_OCCUPIED = GAME_STATE_RAM + $70
BIRD_UNDER_GLYPH = GAME_STATE_RAM + $7c
BIRD_UNDER_COLOR = GAME_STATE_RAM + $88
CELL_INDEX = GAME_STATE_RAM + $94
BIRD_SHIFTED = GAME_STATE_RAM + $95
; Four columns of fourteen horizontally shifted mask rows.
BIRD_CACHE_SHIFT = GAME_STATE_RAM + $cd
BIRD_CACHE_MASK = GAME_STATE_RAM + $ce
BIRD_FRAME_INDEX = GAME_STATE_RAM + $d0
BIRD_ORIGIN_Y = GAME_STATE_RAM + $d1
BACKGROUND_GRADIENT_INDEX = GAME_STATE_RAM + $d2
SCORE = GAME_STATE_RAM + $d3
; SCORE + 1 = $d4. Displayed decimal value, low byte first.
SCORE_WORK = GAME_STATE_RAM + $d5
; SCORE_WORK + 1 = $d6. Scratch copy while extracting digits.
SCORE_PLACES = GAME_STATE_RAM + $d7
HIGH_SCORE = GAME_STATE_RAM + $d8
HUD_BLINK = GAME_STATE_RAM + $da
HUD_TIMER = GAME_STATE_RAM + $db
HUD_NUMBER = GAME_STATE_RAM + $dc
HUD_TEXT_INDEX = GAME_STATE_RAM + $dd
HUD_DIRTY = GAME_STATE_RAM + $de
OBSTACLE_BUFFER_RAM = $3100
PIPE_RANDOM_STATE = $3140
PIPE_DISTANCE = $3141
PIPE_CURRENT_GAP = $3142
PIPE_FIRST = $3143
PIPE_REMAINING = $3144
PIPE_WRITE_INDEX = $3145
PIPE_RENDER_GAP_END = $3146
PIPE_RENDER_GLYPH = $3147
CHARSET_RAM = $3400
CHARSET_SIZE = $0800
RAM_RESERVE_START = $3c00
RAM_RESERVE_SIZE = $0400

SCORE_CODE_START = $2000
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
BIRD_SUB_Y = $16
MASK_POINTER = $17
; MASK_POINTER + 1 = $18

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

BIRD_H_SHIFT = $3b
BIRD_SHIFT_LEFT = $3c
BIRD_SHIFT_RIGHT = $3d
BIRD_SHIFT_TAIL = $3e
BIRD_SHIFT_COUNT = $3f
BIRD_SHIFT_EXTRA = $19
