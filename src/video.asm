initialise_video:
    lda #TED_CONTROL1_TEXT_25_ROWS
    sta TED_CONTROL1
    lda #TED_CONTROL2_TEXT_40_COLS
    sta TED_CONTROL2

    ; $FF12 bit 2 selects chargen ROM (1) or RAM (0).
    lda TED_MISC
    and #$fb
    sta TED_MISC
    ; $FF13 bits 7-2 are chargen A15-A10. 128-character mode (control 2
    ; bit 7 clear) keeps the 1 KiB step, so $34 addresses $3400.
    lda #((CHARSET_RAM >> 8) & $fc)
    sta TED_CHAR_ADDR
    lda #>SCREEN_RAM
    sta TED_VIDEO_ADDR

    lda #TED_SKY_COLOR
    sta TED_COLOR_BG
    lda #TED_BLUE
    sta TED_BORDER_COLOR

    lda #INITIAL_SCROLL_OFFSET
    sta SCROLL_OFFSET
    lda #0
    sta WORLD_COLUMN
    sta COLUMN_UPDATE_COUNTER
    jsr commit_scroll_offset
    rts

; Synchronize on the rising crossing of raster line $80. PAL frames cross it
; exactly once and the loop does not invoke the KERNAL.
wait_for_frame:
wait_before_line:
    lda TED_RASTER_LO
    cmp #$80
    bcs wait_before_line
wait_after_line:
    lda TED_RASTER_LO
    cmp #$80
    bcc wait_after_line
    rts

advance_scroll:
    dec SCROLL_OFFSET
    bpl commit_scroll_offset

    lda #INITIAL_SCROLL_OFFSET
    sta SCROLL_OFFSET
    jsr commit_scroll_offset
    jsr shift_screen_left
    inc WORLD_COLUMN
    inc COLUMN_UPDATE_COUNTER
    ldx #SCREEN_COLUMNS - 1
    jmp render_world_column

commit_scroll_offset:
    lda #TED_CONTROL2_TEXT_40_COLS
    ora SCROLL_OFFSET
    sta TED_CONTROL2
    rts

; Advance the character map only once for each eight hardware-scroll pixels.
; Sky, gap and ground rows are identical for every world column, so only the
; pipe rows (top and bottom band) ever need their columns moved. Shifting
; just those two six-row bands instead of the full 25-row screen keeps the
; copy well inside the frame budget and stops the raster from ever catching
; a row mid-update.
shift_screen_left:
    lda #<(SCREEN_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION
    lda #>(SCREEN_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION + 1
    lda #<(SCREEN_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE
    lda #>(SCREEN_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE + 1
    jsr shift_block

    lda #<(SCREEN_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION
    lda #>(SCREEN_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION + 1
    lda #<(SCREEN_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE
    lda #>(SCREEN_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE + 1
    jsr shift_block

    lda #<(COLOR_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION
    lda #>(COLOR_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION + 1
    lda #<(COLOR_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE
    lda #>(COLOR_RAM + (PIPE_TOP_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE + 1
    jsr shift_block

    lda #<(COLOR_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION
    lda #>(COLOR_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS))
    sta SCREEN_DESTINATION + 1
    lda #<(COLOR_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE
    lda #>(COLOR_RAM + (PIPE_BOTTOM_FIRST_ROW * SCREEN_COLUMNS) + 1)
    sta SCREEN_SOURCE + 1

; Falls through so the final block's rts returns to shift_screen_left's
; caller. The last byte of each row is left untouched (it bleeds in one byte
; from the following row), but render_world_column overwrites every row's
; rightmost column unconditionally right after this runs.
shift_block:
    ldy #0
shift_block_byte:
    lda (SCREEN_SOURCE),y
    sta (SCREEN_DESTINATION),y
    iny
    cpy #PIPE_BLOCK_LENGTH
    bne shift_block_byte
    rts
