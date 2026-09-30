SCREEN_COLUMNS = 40
SCREEN_ROWS = 25

INITIAL_SCROLL_OFFSET = 7
; Number of frames per column shift, and the pieces the hidden buffer is
; filled in. One piece per frame stays far shorter than the border.
SCROLL_SLICE_COUNT = 8
; PAL raster line in the bottom border, below the 200-pixel playfield.
; The scroll register and the buffer flip are stored here.
RASTER_BORDER = $f0
PIPE_PATTERN_MASK = $1f
PIPE_PATTERN_START = 24
PIPE_PATTERN_END = 27

; Only these rows ever differ between world columns (pipe body/cap). Sky,
; the gap and the ground are uniform, so they are mirrored once and the
; per-frame copy moves just the two six-row pipe bands.
PIPE_TOP_FIRST_ROW = 1
PIPE_BOTTOM_FIRST_ROW = 16
PIPE_BLOCK_ROWS = 6

GLYPH_SKY = 0
GLYPH_PIPE_BODY = 1
GLYPH_PIPE_CAP = 2
GLYPH_GROUND = 3

; The bird is composed at runtime into nine dynamic glyphs: three columns
; (left, right, tail) by up to three screen rows. The tail column catches
; the horizontal counter-shift. Each column's three glyphs are consecutive
; charset entries so the composition routine can address them as one flat
; 24-byte span.
GLYPH_BIRD_LEFT_ROW0 = 4
GLYPH_BIRD_LEFT_ROW1 = 5
GLYPH_BIRD_LEFT_ROW2 = 6
GLYPH_BIRD_RIGHT_ROW0 = 7
GLYPH_BIRD_RIGHT_ROW1 = 8
GLYPH_BIRD_RIGHT_ROW2 = 9
GLYPH_BIRD_TAIL_ROW0 = 10
GLYPH_BIRD_TAIL_ROW1 = 11
GLYPH_BIRD_TAIL_ROW2 = 12

BIRD_SCREEN_COLUMN = 12
BIRD_SCREEN_ROW = 10

BIRD_START_Y = BIRD_SCREEN_ROW * 8
BIRD_GRAVITY = $18
BIRD_FLAP_VELOCITY = $fe
BIRD_MAX_FALL_SPEED = 3

; Falling at or above this speed switches to the dive pose instead of the
; wing-flap animation cycle.
BIRD_DIVE_VELOCITY = 2

; Rows below the sky are a solid collision plane (pattern holes ignored).
GROUND_FIRST_ROW = 22

; Collision's endpoint test must not jump across an eight-pixel solid cell.
; Fractional carry can add one pixel to the integer downward velocity.
!if BIRD_MAX_FALL_SPEED >= 7 {
    !error "fall speed can tunnel through a collision cell"
}
!if BIRD_FLAP_VELOCITY < $f9 {
    !error "flap speed can tunnel through a collision cell"
}
