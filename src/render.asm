render_playfield:
    ldx #0
render_initial_column:
    jsr render_world_column
    inx
    cpx #SCREEN_COLUMNS
    bcc render_initial_column
    rts

; X is the screen column to write. WORLD_COLUMN identifies its leftmost
; logical world column, so the same deterministic pipe pattern is used when
; a new right-edge column is prepared. TARGET_SCREEN_HI / TARGET_COLOR_HI
; select the front buffer at startup and the hidden buffer on a flip.
; X is restored for the caller's inx.
render_world_column:
    stx COLUMN_X
    lda #0
    sta PIPE_HERE
    txa
    clc
    adc WORLD_COLUMN
    and #PIPE_PATTERN_MASK
    cmp #PIPE_PATTERN_START
    bcc column_pattern_known
    cmp #PIPE_PATTERN_END
    bcs column_pattern_known
    inc PIPE_HERE
column_pattern_known:
    ldy #0
paint_row:
    sty ROW_INDEX
    lda default_glyph,y
    sta CELL_GLYPH
    lda default_color,y
    sta CELL_COLOR
    lda PIPE_HERE
    beq store_cell
    lda pipe_glyph,y
    beq store_cell
    sta CELL_GLYPH
    lda #TED_PIPE_COLOR
    sta CELL_COLOR
store_cell:
    tya
    ldx TARGET_SCREEN_HI
    ldy TARGET_COLOR_HI
    jsr point_row
    ldy COLUMN_X
    lda CELL_GLYPH
    sta (SCREEN_DESTINATION),y
    lda CELL_COLOR
    sta (SCREEN_SOURCE),y
    ldy ROW_INDEX
    iny
    cpy #SCREEN_ROWS
    bcc paint_row
    ldx COLUMN_X
    rts

; Row 0 and rows 7-15 are sky, 22-24 the ground. pipe_glyph is 0 on those
; rows; a pipe column overrides the rest (body, cap at the gap).
default_glyph:
    !fill 22, GLYPH_SKY
    !fill 3, GLYPH_GROUND
default_color:
    !fill 22, TED_SKY_COLOR
    !fill 3, TED_GROUND_COLOR
pipe_glyph:
    !byte 0
    !fill 5, GLYPH_PIPE_BODY
    !byte GLYPH_PIPE_CAP
    !fill 9, 0
    !byte GLYPH_PIPE_CAP
    !fill 5, GLYPH_PIPE_BODY
    !fill 3, 0
