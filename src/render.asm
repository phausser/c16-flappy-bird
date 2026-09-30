render_playfield:
    ldx #0
render_initial_column:
    jsr render_world_column
    inx
    cpx #SCREEN_COLUMNS
    bcc render_initial_column
    rts

; Rendering only reads the ring; RNG advances when a new world column is
; generated at startup or at the right edge of the hidden buffer.
render_world_column:
    stx COLUMN_X
    txa
    clc
    adc WORLD_COLUMN
    and #PIPE_RING_MASK
    tay
    lda OBSTACLE_BUFFER_RAM,y
    sta PIPE_HERE
    clc
    adc #PIPE_GAP_HEIGHT
    sta PIPE_RENDER_GAP_END
    lda PIPE_HERE
    sec
    sbc #1
    sta PIPE_RENDER_TOP_CAP
    ldy #0
paint_row:
    sty ROW_INDEX
    lda #GLYPH_SKY
    sta CELL_GLYPH
    lda #TED_SKY_COLOR
    sta CELL_COLOR
    lda PIPE_HERE
    beq store_cell
    cpy PIPE_HERE
    bcc top_pipe_cell
    cpy PIPE_RENDER_GAP_END
    bcc store_cell
    beq pipe_cap_cell
    bne pipe_body_cell
top_pipe_cell:
    cpy PIPE_RENDER_TOP_CAP
    beq pipe_cap_cell
pipe_body_cell:
    lda #GLYPH_PIPE_BODY
    bne set_pipe_cell
pipe_cap_cell:
    lda #GLYPH_PIPE_CAP
set_pipe_cell:
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
