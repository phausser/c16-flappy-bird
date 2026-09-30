; Check the candidate Y and next scroll phase before touching either video
; register or the displayed bird. Carry set rejects the entire frame.
; The renderer always writes three rows, including its blank overflow row.
; A wrapped negative Y is also above BIRD_Y_MAX in this unsigned test.
check_bird_collision:
    lda BIRD_Y_POSITION
    cmp #BIRD_Y_MAX + 1
    bcs bird_collision
    lsr
    lsr
    lsr
    sta ROW_INDEX
    lda #3
    sta BIRD_ROW_COUNTER

    ; Non-wrap frames paint columns 12..14 (next phase is 6..0).
    ; On wrap, next columns 12..13 are current columns 13..14. Reading
    ; the current buffer avoids depending on a partly prepared back buffer.
    lda #BIRD_SCREEN_COLUMN
    ldx SCROLL_OFFSET
    bne collision_column_known
    clc
    adc #1
collision_column_known:
    sta COLUMN_X
collision_row:
    lda ROW_INDEX
    jsr row_to_pointers
    ldy COLUMN_X
collision_cell:
    lda (SCREEN_DESTINATION),y
    beq collision_cell_clear
    ; Existing bird cells cover only sky after an accepted frame.
    cmp #GLYPH_BIRD_LEFT_ROW0
    bcc bird_collision
    cmp #GLYPH_BIRD_TAIL_ROW2 + 1
    bcs bird_collision
collision_cell_clear:
    iny
    cpy #BIRD_SCREEN_COLUMN + 3
    bcc collision_cell
    inc ROW_INDEX
    dec BIRD_ROW_COUNTER
    bne collision_row
    clc
    rts
bird_collision:
    sec
    rts
