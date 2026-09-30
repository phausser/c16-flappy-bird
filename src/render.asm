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
    ; Neighbour descriptors identify the three columns even across ring
    ; wrap. Keep the ring's gap-only format for generation and collision.
    ldx #GLYPH_PIPE_LEFT
    tya
    sec
    sbc #1
    and #PIPE_RING_MASK
    tay
    lda OBSTACLE_BUFFER_RAM,y
    beq pipe_glyph_ready
    inx
    tya
    sec
    sbc #1
    and #PIPE_RING_MASK
    tay
    lda OBSTACLE_BUFFER_RAM,y
    beq pipe_glyph_ready
    inx
pipe_glyph_ready:
    stx PIPE_RENDER_GLYPH
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
    bcc pipe_body_cell
    cpy PIPE_RENDER_GAP_END
    bcc store_cell
pipe_body_cell:
    lda PIPE_RENDER_GLYPH
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
