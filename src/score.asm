; This helper lives in the upper code segment to keep the main segment
; below the hidden screen buffer. Select color once for all bird cells.
select_bird_color:
    lda #TED_BIRD_COLOR
    ldx GAME_OVER
    cpx #GAME_STATE_DEAD
    bne bird_color_ready
    lda #TED_BIRD_DEAD_COLOR
bird_color_ready:
    sta CELL_COLOR
    rts

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
    lda #SOUND_POINT
    sta SOUND_REQUEST
award_done:
    rts

refresh_footer:
    lda HUD_DIRTY
    beq footer_refresh_done
    lda #0
    sta HUD_DIRTY
    jmp render_footer_scores
footer_refresh_done:
    rts

; Paint HIGH on the left, the title in the center and SCORE on the right.
; Numbers have at least four digits; five retain the full 16-bit range.
; Empty cells stay glyph 0, so the floor raster shows through them.
render_score:
    jsr clear_score_rows
    jsr render_footer_text
render_footer_scores:
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
    lda #0
    sta HUD_NUMBER
    lda SCORE
    sta SCORE_WORK
    lda SCORE + 1
    sta SCORE_WORK + 1
render_footer_number:
    ldx #HUD_MIN_DIGITS
    lda SCORE_WORK + 1
    cmp #>SCORE_FIFTH_DIGIT_THRESHOLD
    bcc score_places_known
    bne score_places_five
    lda SCORE_WORK
    cmp #<SCORE_FIFTH_DIGIT_THRESHOLD
    bcc score_places_known
score_places_five:
    inx
score_places_known:
    stx SCORE_PLACES
    lda #HUD_VISIBLE_LEFT
    sta COLUMN_X
    lda HUD_NUMBER
    bne footer_label_start
    lda #HUD_VISIBLE_RIGHT - HUD_SCORE_LABEL_LENGTH
    sec
    sbc SCORE_PLACES
    sta COLUMN_X
footer_label_start:
    lda #0
    sta HUD_TEXT_INDEX
footer_label_next:
    ldx HUD_TEXT_INDEX
    lda HUD_NUMBER
    bne footer_high_label
    lda footer_score,x
    jmp footer_label_plot
footer_high_label:
    lda footer_high,x
footer_label_plot:
    sta CELL_GLYPH
    jsr plot_score_glyph
    inc COLUMN_X
    inc HUD_TEXT_INDEX
    lda HUD_NUMBER
    beq footer_score_length
    lda #HUD_HIGH_LABEL_LENGTH
    bne footer_label_length
footer_score_length:
    lda #HUD_SCORE_LABEL_LENGTH
footer_label_length:
    cmp HUD_TEXT_INDEX
    bne footer_label_next
    ; The right label moves left when the counter gains a fifth digit.
    ; Clear its separator so the previous label's last letter cannot remain.
    ldy COLUMN_X
    lda #0
    sta SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    inc COLUMN_X
footer_number_positioned:
    lda #SCORE_MAX_DIGITS
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
    cpx #SCORE_MAX_DIGITS
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
    cmp #HUD_BLINK_TICKS
    bcc footer_blink_done
    lda #0
    sta HUD_TIMER
    lda HUD_BLINK
    eor #1
    sta HUD_BLINK
    jsr clear_footer_title
    jsr render_footer_text
footer_blink_done:
    rts

; Blinking changes only the center text, leaving both counters untouched.
clear_footer_title:
    ldy #HUD_PROMPT_COLUMN + HUD_CLEAR_WIDTH - 1
    lda #0
clear_footer_title_cell:
    sta SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    dey
    cpy #HUD_PROMPT_COLUMN - 1
    bne clear_footer_title_cell
    rts

render_footer_text:
    lda #HUD_TITLE_COLUMN
    ldx GAME_OVER
    beq footer_title_positioned
    lda #HUD_PROMPT_COLUMN
footer_title_positioned:
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
    ldx GAME_OVER
    bne footer_prompt_length
    cmp #HUD_TITLE_LENGTH
    bcc footer_text_next
    rts
footer_prompt_length:
    cmp #HUD_PROMPT_LENGTH
    bcc footer_text_next
footer_text_done:
    rts

footer_name:
    !byte GLYPH_LETTER_A+19, GLYPH_LETTER_A+4, GLYPH_LETTER_A+3, GLYPH_LETTER_A+3, GLYPH_LETTER_A+24, 0, GLYPH_LETTER_A+1, GLYPH_LETTER_A+8, GLYPH_LETTER_A+17, GLYPH_LETTER_A+3
footer_high:
    !byte GLYPH_LETTER_A+7, GLYPH_LETTER_A+8, GLYPH_LETTER_A+6, GLYPH_LETTER_A+7
footer_score:
    !byte GLYPH_LETTER_A+18, GLYPH_LETTER_A+2, GLYPH_LETTER_A+14, GLYPH_LETTER_A+17, GLYPH_LETTER_A+4
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

; The HUD row never moves. Address both buffers directly instead of
; recalculating two row pointers for every individual glyph.
plot_score_glyph:
    ldy COLUMN_X
    lda CELL_GLYPH
    sta SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_SCREEN_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    lda #TED_SCORE_COLOR
    sta COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    sta BACK_COLOR_RAM + SCORE_ROW * SCREEN_COLUMNS,y
    rts

; 10000, 1000, 100, 10, 1. Five places cover the whole 16-bit counter.
score_powers_lo:
    !byte <$2710, <$03e8, <$0064, <$000a, <$0001
score_powers_hi:
    !byte >$2710, >$03e8, >$0064, >$000a, >$0001
