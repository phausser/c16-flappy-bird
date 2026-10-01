SCREEN_COLUMNS = 40
SCREEN_ROWS = 25
SCREEN_SIZE = SCREEN_COLUMNS * SCREEN_ROWS
; Rows 0-23 scroll. Row 24 holds the fixed HIGH/title/SCORE HUD.
PLAYFIELD_ROWS = 24
SCORE_ROW = 24
GAME_STATE_DEAD = 1
GAME_STATE_WAITING = 2

INITIAL_SCROLL_OFFSET = 7
; Number of frames per column shift, and the pieces the hidden buffer is
; filled in. One piece per frame stays far shorter than the border.
SCROLL_SLICE_COUNT = 8
; Begin publishing immediately after the last HUD character pixel.
; The earlier border window keeps bird writes ahead of the top-row fetch.
RASTER_BORDER = $cc
; TED raster-counter coordinates: active 25-row screen is $04..$CB.
; Match the first visible character row.
BACKGROUND_GRADIENT_FIRST_RASTER = $04
; Low nibble selects the TED hue; bits 4-6 set luminance 0..7.
BACKGROUND_GRADIENT_COLOR = 6
BACKGROUND_GRADIENT_DISTANCE = 28
BG_GRADIENT_START_COLOR = (0 << 4) + BACKGROUND_GRADIENT_COLOR
BACKGROUND_GRADIENT_LEVELS = 7
; VICE normal PAL canvas starts at TED raster $113; active text starts at $04.
BACKGROUND_GRADIENT_TOP_RASTER = $113
; First raster of character row 24: HUD background and scroll 0 start here.
BACKGROUND_GRADIENT_BOTTOM_RASTER = $c4
HUD_BACKGROUND_COLOR = (5 << 4) + 9
HUD_BACKGROUND_HEIGHT = 11
FRAME_BOTTOM_COLOR = (6 << 4) + 9
PIPE_RANDOM_SEED = $5d
PIPE_RING_MASK = $3f
PIPE_FIRST_COLUMN = 24
PIPE_WIDTH_COLUMNS = 4
PIPE_SPACING_COLUMNS = 8
PIPE_GAP_HEIGHT = 6
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
GLYPH_LETTER_A = GLYPH_PIPE_CAP_LEFT + 3

BIRD_SCREEN_COLUMN = 12
BIRD_SCREEN_ROW = 10

BIRD_START_Y = BIRD_SCREEN_ROW * 8
BIRD_GRAVITY = $28
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

; Video mode and palette configuration. Register addresses are in hardware.inc.
; Bits 0-2 = vertical scroll 3. Scroll 0 shifts the matrix up and opens
; three scanlines below the playfield; the TED paints the bytes past the
; screen matrix there (a light bar, and on some offsets a black block).
; Bit 3 = 25 rows. Bit 4 = display on.
TED_CONTROL1_TEXT_25_ROWS = $1b
; Bit 3 clear = 38 columns. The border then covers eight pixels on each
; side, which is where a horizontal scroll would otherwise show the partial
; column. The screen matrix stays 40 bytes wide; columns 0 and 39 are the
; hidden guards. Bit 7 stays clear: set, it switches the TED into
; 256-character mode and the chargen base then moves in 2 KiB steps, so
; $3400 cannot be addressed and $0D aliases onto colour RAM at $0800.
; Bit 4 enables mixed multicolor text. Color-RAM bit 3 selects each cell.
TED_CONTROL2_TEXT_38_COLS = $10

TED_BLUE = $6d

TED_SKY_COLOR = TED_BLUE
; Pipe pairs: 01 = highlight, 10 = shadow, 11 = base color.
; Attribute bit 3 enables multicolor; the bird keeps it clear for hires.
TED_PIPE_HIGHLIGHT = (6 << 4) + 5
TED_PIPE_SHADOW = (3 << 4) + 5
TED_PIPE_COLOR = (4 << 4) + 5 | $08

; Live bird: TED hue 7, luminance 7. Dead bird: hue 4, luminance 7.
; Both use hires attributes (color bit 3 clear).
TED_BIRD_COLOR = (7 << 4) + 7
TED_BIRD_DEAD_COLOR = (7 << 4) + 4
; Score digits are hires white (luminance 7, color 1). Color-RAM bit 3
; stays clear, so the digits do not use the pipe multicolor palette.
TED_SCORE_COLOR = (7 << 4) + 1

; HUD layout uses the 38 visible columns between the two guard columns.
HUD_VISIBLE_LEFT = 1
HUD_VISIBLE_RIGHT = SCREEN_COLUMNS - 2
HUD_BLINK_TICKS = 25
HUD_MIN_DIGITS = 4
SCORE_MAX_DIGITS = 5
SCORE_FIFTH_DIGIT_THRESHOLD = 10000
HUD_HIGH_LABEL_LENGTH = 4
HUD_SCORE_LABEL_LENGTH = 5
HUD_TITLE_LENGTH = 10
HUD_PROMPT_LENGTH = 11
HUD_TITLE_COLUMN = HUD_VISIBLE_LEFT + (SCREEN_COLUMNS - 2 - HUD_TITLE_LENGTH) / 2
HUD_PROMPT_COLUMN = HUD_VISIBLE_LEFT + (SCREEN_COLUMNS - 2 - HUD_PROMPT_LENGTH) / 2
HUD_CLEAR_WIDTH = HUD_PROMPT_LENGTH

; PAL horizontal synchronization thresholds; these are cycle-sensitive.
GRADIENT_BLANK_THRESHOLD = $a0
GRADIENT_WRAP_THRESHOLD = $b0
GRADIENT_FETCH_THRESHOLD = $bc
TED_RASTER_IRQ_MASK = 2
SPACE_KEY_ROW_MASK = $7f
SPACE_KEY_COLUMN_MASK = $10
PIPE_LFSR_FEEDBACK = $1d
PIPE_GAP_STEP_MASK = 3
