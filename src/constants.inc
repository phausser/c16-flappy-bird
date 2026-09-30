SCREEN_COLUMNS = 40
SCREEN_ROWS = 25

INITIAL_SCROLL_OFFSET = 7
; Number of frames per column shift, and the pieces the hidden buffer is
; filled in. One piece per frame stays far shorter than the border.
SCROLL_SLICE_COUNT = 8
; PAL raster line in the lower border, after its color has been set at $CC.
; The scroll register and the buffer flip are stored here.
RASTER_BORDER = $fc
; TED raster-counter coordinates: active 25-row screen is $04..$CB.
; Start in the upper border, before the first character-fetch pair.
BACKGROUND_GRADIENT_FIRST_RASTER = $02
; Low nibble is TED color 13 (blue); bits 4-6 set luminance 0..7.
BG_GRADIENT_HUE = $0d
BG_GRADIENT_START_COLOR = BG_GRADIENT_HUE
BACKGROUND_GRADIENT_LEVELS = 7
; VICE normal PAL canvas starts at TED raster $113; active text starts at $04.
BACKGROUND_GRADIENT_TOP_RASTER = $113
BACKGROUND_GRADIENT_BOTTOM_RASTER = $cc
FRAME_BOTTOM_COLOR = $59
PIPE_RANDOM_SEED = $5d
PIPE_RING_MASK = $3f
PIPE_FIRST_COLUMN = 24
PIPE_WIDTH_COLUMNS = 3
PIPE_SPACING_COLUMNS = 24
PIPE_GAP_HEIGHT = 9
PIPE_GAP_MIN = 4
PIPE_GAP_MAX = 10
PIPE_START_GAP = 7
PIPE_GAP_MAX_STEP = 2
; A gap moves by at most two rows (16 pixels) between successive pipes.
SCROLL_ROWS_PER_SLICE = 6

GLYPH_SKY = 0
GLYPH_PIPE_BODY = 1
GLYPH_PIPE_CAP = 2
GLYPH_GROUND = 3

; A 20x14 mask plus seven fine-scroll pixels needs four columns, three rows.
BIRD_HEIGHT = 14
BIRD_COLUMNS = 4
BIRD_CELLS = BIRD_COLUMNS * 3
BIRD_GLYPH_BYTES = BIRD_CELLS * 8
BIRD_MASK_BYTES = BIRD_HEIGHT * 3
BIRD_FRAME_TICKS = 5
GLYPH_BIRD_LEFT_ROW0 = 4
GLYPH_BIRD_LAST = GLYPH_BIRD_LEFT_ROW0 + BIRD_CELLS - 1

BIRD_SCREEN_COLUMN = 12
BIRD_SCREEN_ROW = 10

BIRD_START_Y = BIRD_SCREEN_ROW * 8
BIRD_GRAVITY = $18
BIRD_FLAP_VELOCITY = $fe
BIRD_MAX_FALL_SPEED = 3

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

!if PIPE_RANDOM_SEED = 0 {
    !error "pipe RNG seed must be nonzero"
}
!if PIPE_GAP_MIN < 2 {
    !error "top pipe needs room below the HUD"
}
!if PIPE_GAP_MAX + PIPE_GAP_HEIGHT >= GROUND_FIRST_ROW {
    !error "bottom pipe needs room above the ground"
}
