; One point when the bird's column passes the right edge of a pipe.
; swap_buffers has already advanced WORLD_COLUMN. The cell now one column
; behind the bird is that edge when it holds a gap and the next ring cell
; is sky. A crash skips the swap, so the pipe that ends the run scores nothing.
award_pipe_point:
    lda WORLD_COLUMN
    clc
    adc #BIRD_SCREEN_COLUMN - 1
    and #PIPE_RING_MASK
    tax
    lda OBSTACLE_BUFFER_RAM,x
    beq award_done
    inx
    txa
    and #PIPE_RING_MASK
    tax
    lda OBSTACLE_BUFFER_RAM,x
    bne award_done
    inc SCORE
    bne award_draw
    inc SCORE + 1
award_draw:
    jsr render_score
award_done:
    rts

; Paint the decimal score into row 24 of both text buffers. Leading zeros
; are omitted and the digits are recentered in the 38 visible columns.
; Empty cells stay glyph 0, so the floor raster shows through them.
render_score:
    jsr clear_score_rows
    lda SCORE
    sta SCORE_WORK
    lda SCORE + 1
    sta SCORE_WORK + 1
    ldx #1
    lda SCORE + 1
    bne score_places_large
    lda SCORE
    cmp #10
    bcc score_places_known
    inx
    cmp #100
    bcc score_places_known
    inx
    jmp score_places_known
score_places_large:
    ldx #3
    lda SCORE + 1
    cmp #3
    bcc score_places_known
    bne score_places_four
    lda SCORE
    cmp #$e8
    bcc score_places_known
score_places_four:
    inx
    lda SCORE + 1
    cmp #$27
    bcc score_places_known
    bne score_places_five
    lda SCORE
    cmp #$10
    bcc score_places_known
score_places_five:
    inx
score_places_known:
    stx SCORE_PLACES
    ; start = 1 + (38 - places) / 2. The spare column sits on the right.
    lda #SCREEN_COLUMNS - 2
    sec
    sbc SCORE_PLACES
    lsr
    clc
    adc #1
    sta COLUMN_X
    lda #5
    sec
    sbc SCORE_PLACES
    tax
score_next_digit:
    lda #0
    sta CELL_GLYPH
score_subtract:
    lda SCORE_WORK
    sec
    sbc score_powers_lo,x
    tay
    lda SCORE_WORK + 1
    sbc score_powers_hi,x
    bcc score_digit_ready
    sta SCORE_WORK + 1
    sty SCORE_WORK
    inc CELL_GLYPH
    jmp score_subtract
score_digit_ready:
    lda CELL_GLYPH
    clc
    adc #GLYPH_DIGIT_0
    sta CELL_GLYPH
    txa
    pha
    jsr plot_score_glyph
    pla
    tax
    inc COLUMN_X
    inx
    cpx #5
    bcc score_next_digit
    rts

clear_score_rows:
    lda #>SCREEN_RAM
    ldy #>COLOR_RAM
    jsr clear_score_buffer
    lda #>BACK_SCREEN_RAM
    ldy #>BACK_COLOR_RAM
clear_score_buffer:
    tax
    lda #SCORE_ROW
    jsr point_row
    ldy #SCREEN_COLUMNS - 1
clear_score_cell:
    lda #GLYPH_SKY
    sta (SCREEN_DESTINATION),y
    lda #0
    sta (SCREEN_SOURCE),y
    dey
    bpl clear_score_cell
    rts

; A is the screen page and Y the color page. COLUMN_X and CELL_GLYPH
; select the digit. Both buffers are written so a $FF14 flip cannot blink.
plot_score_glyph:
    lda #>SCREEN_RAM
    ldy #>COLOR_RAM
    jsr plot_score_buffer
    lda #>BACK_SCREEN_RAM
    ldy #>BACK_COLOR_RAM
plot_score_buffer:
    tax
    lda #SCORE_ROW
    jsr point_row
    ldy COLUMN_X
    lda CELL_GLYPH
    sta (SCREEN_DESTINATION),y
    lda #TED_SCORE_COLOR
    sta (SCREEN_SOURCE),y
    rts

; 10000, 1000, 100, 10, 1. Five places cover the whole 16-bit counter.
score_powers_lo:
    !byte <$2710, <$03e8, <$0064, <$000a, <$0001
score_powers_hi:
    !byte >$2710, >$03e8, >$0064, >$000a, >$0001
