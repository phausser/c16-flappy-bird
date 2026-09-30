SCREEN_COLUMNS = 40
SCREEN_ROWS = 25

INITIAL_SCROLL_OFFSET = 7
PIPE_PATTERN_MASK = $1f
PIPE_PATTERN_START = 24
PIPE_PATTERN_END = 27

; Only these rows ever differ between world columns (pipe body/cap); sky,
; gap and ground rows are always uniform and never need to be shifted.
PIPE_TOP_FIRST_ROW = 1
PIPE_BOTTOM_FIRST_ROW = 16
PIPE_BLOCK_ROWS = 6
PIPE_BLOCK_LENGTH = (PIPE_BLOCK_ROWS * SCREEN_COLUMNS) - 1

GLYPH_SKY = 0
GLYPH_PIPE_BODY = 1
GLYPH_PIPE_CAP = 2
GLYPH_GROUND = 3

; The bird is composed at runtime into six dynamic glyphs: two columns (left,
; right) by up to three screen rows (top, middle, bottom-overflow). Each
; column's three glyphs are consecutive charset entries so the composition
; routine can address them as one flat 24-byte span.
GLYPH_BIRD_LEFT_ROW0 = 4
GLYPH_BIRD_LEFT_ROW1 = 5
GLYPH_BIRD_LEFT_ROW2 = 6
GLYPH_BIRD_RIGHT_ROW0 = 7
GLYPH_BIRD_RIGHT_ROW1 = 8
GLYPH_BIRD_RIGHT_ROW2 = 9

BIRD_SCREEN_COLUMN = 12
BIRD_SCREEN_ROW = 10

BIRD_START_Y = BIRD_SCREEN_ROW * 8
BIRD_GRAVITY = $18
BIRD_FLAP_VELOCITY = $fe
BIRD_MAX_FALL_SPEED = 3

; Falling at or above this speed switches to the dive pose instead of the
; wing-flap animation cycle.
BIRD_DIVE_VELOCITY = 2

; Keeps the full 16x16-plus-overflow sprite within screen rows 0-21 (rows
; 22-24 are the ground) at every sub-pixel offset.
BIRD_Y_MIN = 0
BIRD_Y_MAX = 159
