initialise_video:
    lda #TED_CONTROL1_TEXT_25_ROWS
    sta TED_CONTROL1
    lda #TED_CONTROL2_TEXT_40_COLS
    sta TED_CONTROL2

    lda TED_MISC
    and #$fb
    sta TED_MISC
    lda #(CHARSET_RAM >> 10)
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
    jsr shift_screen_left
    inc WORLD_COLUMN
    inc COLUMN_UPDATE_COUNTER
    lda COLUMN_UPDATE_COUNTER
    and #1
    clc
    adc #TED_BLUE
    sta TED_BORDER_COLOR
    ldx #SCREEN_COLUMNS - 1
    jsr render_world_column

commit_scroll_offset:
    lda #TED_CONTROL2_TEXT_40_COLS
    ora SCROLL_OFFSET
    sta TED_CONTROL2
    rts

; Advance the character map only once for each eight hardware-scroll pixels.
; This copies the visible map rather than redrawing the playfield.
shift_screen_left:
    lda #<SCREEN_RAM
    sta SCREEN_DESTINATION
    lda #>SCREEN_RAM
    sta SCREEN_DESTINATION + 1
    lda #<(SCREEN_RAM + 1)
    sta SCREEN_SOURCE
    lda #>(SCREEN_RAM + 1)
    sta SCREEN_SOURCE + 1
    jsr shift_columns_left

    lda #<COLOR_RAM
    sta SCREEN_DESTINATION
    lda #>COLOR_RAM
    sta SCREEN_DESTINATION + 1
    lda #<(COLOR_RAM + 1)
    sta SCREEN_SOURCE
    lda #>(COLOR_RAM + 1)
    sta SCREEN_SOURCE + 1

shift_columns_left:
    ldx #SCREEN_ROWS
shift_row:
    ldy #0
shift_cell:
    lda (SCREEN_SOURCE),y
    sta (SCREEN_DESTINATION),y
    iny
    cpy #SCREEN_COLUMNS - 1
    bcc shift_cell

    clc
    lda SCREEN_DESTINATION
    adc #SCREEN_COLUMNS
    sta SCREEN_DESTINATION
    bcc destination_advanced
    inc SCREEN_DESTINATION + 1
destination_advanced:
    clc
    lda SCREEN_SOURCE
    adc #SCREEN_COLUMNS
    sta SCREEN_SOURCE
    bcc source_advanced
    inc SCREEN_SOURCE + 1
source_advanced:
    dex
    bne shift_row
    rts
