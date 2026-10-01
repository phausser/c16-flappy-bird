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
    ; Buffer flips run in the border. Defer the footer until all scrolling
    ; and bird writes are finished, keeping the top rows on schedule.
    lda #1
    sta HUD_DIRTY
award_done:
    rts

refresh_footer:
    lda HUD_DIRTY
    beq footer_refresh_done
    lda #0
    sta HUD_DIRTY
    jmp render_score
footer_refresh_done:
    rts

; Paint the decimal score into row 24 of both text buffers. Leading zeros
; are omitted and the digits are recentered in the 38 visible columns.
; Empty cells stay glyph 0, so the floor raster shows through them.
render_score:
    lda SCORE + 1
    cmp HIGH_SCORE + 1
    bcc high_score_ready
    bne high_score_update
    lda SCORE
    cmp HIGH_SCORE
    bcc high_score_ready
high_score_update:
    lda SCORE
    sta HIGH_SCORE
    lda SCORE + 1
    sta HIGH_SCORE + 1
high_score_ready:
    jsr clear_score_rows
    jsr render_footer_text
    lda #0
    sta HUD_NUMBER
    lda SCORE
    sta SCORE_WORK
    lda SCORE + 1
    sta SCORE_WORK + 1
render_footer_number:
    ldx #1
    lda SCORE_WORK + 1
    bne score_places_large
    lda SCORE_WORK
    cmp #10
    bcc score_places_known
    inx
    cmp #100
    bcc score_places_known
    inx
    jmp score_places_known
score_places_large:
    ldx #3
    lda SCORE_WORK + 1
    cmp #3
    bcc score_places_known
    bne score_places_four
    lda SCORE_WORK
    cmp #$e8
    bcc score_places_known
score_places_four:
    inx
    lda SCORE_WORK + 1
    cmp #$27
    bcc score_places_known
    bne score_places_five
    lda SCORE_WORK
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
    lda HUD_NUMBER
    beq footer_number_positioned
    lda #SCREEN_COLUMNS - 1
    sec
    sbc SCORE_PLACES
    sta COLUMN_X
    sec
    sbc #3
    sta COLUMN_X
    lda #GLYPH_LETTER_A + 7
    sta CELL_GLYPH
    jsr plot_score_glyph
    inc COLUMN_X
    lda #GLYPH_LETTER_A + 8
    sta CELL_GLYPH
    jsr plot_score_glyph
    inc COLUMN_X
    inc COLUMN_X
footer_number_positioned:
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
    lda HUD_NUMBER
    bne footer_numbers_done
    inc HUD_NUMBER
    lda HIGH_SCORE
    sta SCORE_WORK
    lda HIGH_SCORE + 1
    sta SCORE_WORK + 1
    jmp render_footer_number
footer_numbers_done:
    rts

update_footer_blink:
    inc HUD_TIMER
    lda HUD_TIMER
    cmp #25
    bcc footer_blink_done
    lda #0
    sta HUD_TIMER
    lda HUD_BLINK
    eor #1
    sta HUD_BLINK
    jsr render_score
footer_blink_done:
    rts

render_footer_text:
    lda #1
    sta COLUMN_X
    lda #0
    sta HUD_TEXT_INDEX
footer_text_next:
    ldx HUD_TEXT_INDEX
    lda GAME_OVER
    beq footer_title
    lda HUD_BLINK
    bne footer_text_done
    lda footer_prompt,x
    jmp footer_text_plot
footer_title:
    lda footer_name,x
footer_text_plot:
    sta CELL_GLYPH
    jsr plot_score_glyph
    inc COLUMN_X
    inc HUD_TEXT_INDEX
    lda HUD_TEXT_INDEX
    cmp #11
    bcc footer_text_next
footer_text_done:
    rts

footer_name:
    !byte GLYPH_LETTER_A+5, GLYPH_LETTER_A+11, GLYPH_LETTER_A, GLYPH_LETTER_A+15, GLYPH_LETTER_A+15, GLYPH_LETTER_A+24, 0, GLYPH_LETTER_A+1, GLYPH_LETTER_A+8, GLYPH_LETTER_A+17, GLYPH_LETTER_A+3
footer_prompt:
    !byte GLYPH_LETTER_A+15, GLYPH_LETTER_A+17, GLYPH_LETTER_A+4, GLYPH_LETTER_A+18, GLYPH_LETTER_A+18, 0, GLYPH_LETTER_A+18, GLYPH_LETTER_A+15, GLYPH_LETTER_A, GLYPH_LETTER_A+2, GLYPH_LETTER_A+4

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
