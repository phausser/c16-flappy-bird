SCREEN_COLUMNS = 40
SCREEN_ROWS = 25
; Rows 0-23 scroll. Row 24 is the floor and the score; it does not.
PLAYFIELD_ROWS = 24
SCORE_ROW = 24

INITIAL_SCROLL_OFFSET = 7
; Number of frames per column shift, and the pieces the hidden buffer is
; filled in. One piece per frame stays far shorter than the border.
SCROLL_SLICE_COUNT = 8
; PAL raster line in the lower border, after the score row ($C4-$CB).
; The scroll register and the buffer flip are stored here.
RASTER_BORDER = $fc
; TED raster-counter coordinates: active 25-row screen is $04..$CB.
; Match the first visible character row.
BACKGROUND_GRADIENT_FIRST_RASTER = $04
; Low nibble is TED color 13 (blue); bits 4-6 set luminance 0..7.
BG_GRADIENT_HUE = $0d
BG_GRADIENT_START_COLOR = BG_GRADIENT_HUE
BACKGROUND_GRADIENT_LEVELS = 7
; VICE normal PAL canvas starts at TED raster $113; active text starts at $04.
BACKGROUND_GRADIENT_TOP_RASTER = $113
; First raster of character row 24. Floor color and scroll 0 start here,
; eight pixels above the lower border that used to begin at $CC.
BACKGROUND_GRADIENT_BOTTOM_RASTER = $c4
FRAME_BOTTOM_COLOR = $59
PIPE_RANDOM_SEED = $5d
PIPE_RING_MASK = $3f
PIPE_FIRST_COLUMN = 24
PIPE_WIDTH_COLUMNS = 3
PIPE_SPACING_COLUMNS = 12
PIPE_GAP_HEIGHT = 9
PIPE_GAP_MIN = 4
PIPE_GAP_MAX = 10
PIPE_START_GAP = 7
PIPE_GAP_MAX_STEP = 2
; A gap moves by at most two rows (16 pixels) between successive pipes.
SCROLL_ROWS_PER_SLICE = 7

GLYPH_SKY = 0
GLYPH_PIPE_LEFT = 1
GLYPH_PIPE_MIDDLE = 2
GLYPH_PIPE_RIGHT = 3

; A 20x14 mask plus seven fine-scroll pixels needs four columns, three rows.
BIRD_HEIGHT = 14
BIRD_COLUMNS = 4
BIRD_CELLS = BIRD_COLUMNS * 3
BIRD_GLYPH_BYTES = BIRD_CELLS * 8
BIRD_MASK_BYTES = BIRD_HEIGHT * 3
BIRD_FRAME_TICKS = 5
GLYPH_BIRD_LEFT_ROW0 = 4
GLYPH_BIRD_LAST = GLYPH_BIRD_LEFT_ROW0 + BIRD_CELLS - 1
; Ten fixed hires digits, immediately after the dynamic bird glyphs.
GLYPH_DIGIT_0 = GLYPH_BIRD_LAST + 1
GLYPH_PIPE_CAP_LEFT = GLYPH_DIGIT_0 + 10

BIRD_SCREEN_COLUMN = 12
BIRD_SCREEN_ROW = 10

BIRD_START_Y = BIRD_SCREEN_ROW * 8
BIRD_GRAVITY = $18
BIRD_FLAP_VELOCITY = $fe
BIRD_MAX_FALL_SPEED = 3

; Collision's endpoint test must not jump across an eight-pixel solid cell.
; Fractional carry can add one pixel to the integer downward velocity.
!if BIRD_MAX_FALL_SPEED >= 7 {
    !error "fall speed can tunnel through a collision cell"
}
!if BIRD_FLAP_VELOCITY < $f9 {
    !error "flap speed can tunnel through a collision cell"
}

!if PIPE_RANDOM_SEED = 0 {
    !error "pipe RNG seed must be nonzero"
}
!if PIPE_GAP_MIN < 1 {
    !error "top pipe needs at least one row"
}
!if PIPE_GAP_MAX + PIPE_GAP_HEIGHT >= PLAYFIELD_ROWS {
    !error "bottom pipe needs at least one row"
}
!if SCORE_ROW <> PLAYFIELD_ROWS {
    !error "score row must be the first row below the playfield"
}
!if BACKGROUND_GRADIENT_BOTTOM_RASTER <> $04 + SCORE_ROW * 8 {
    !error "floor raster must be the first line of the score row"
}
