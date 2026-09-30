initialise_video:
    lda #TED_CONTROL1_TEXT_25_ROWS
    sta TED_CONTROL1
    lda #TED_CONTROL2_TEXT_38_COLS
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
    sta VISIBLE_SCREEN_HI
    sta TARGET_SCREEN_HI
    lda #>COLOR_RAM
    sta VISIBLE_COLOR_HI
    sta TARGET_COLOR_HI
    lda #>BACK_SCREEN_RAM
    sta BACK_SCREEN_HI
    lda #>BACK_COLOR_RAM
    sta BACK_COLOR_HI
    lda #FRONT_VIDEO_PTR
    sta VISIBLE_FF14
    sta TED_VIDEO_ADDR
    lda #BACK_VIDEO_PTR
    sta BACK_FF14

    lda #TED_SKY_COLOR
    sta TED_COLOR_BG
    lda #TED_BLUE
    sta TED_BORDER_COLOR

    lda #0
    sta WORLD_COLUMN
    sta COLUMN_UPDATE_COUNTER
    sta COPY_SLICE
    sta FLIP_READY
    ; Scroll starts at 7. prime_back_buffer copies the first piece, and the
    ; call that reloads 7 is the one that flips — the piece and the new
    ; column were finished on the frame before, so both registers are stored
    ; while the beam is still in the border.
    lda #INITIAL_SCROLL_OFFSET
    sta SCROLL_OFFSET
    jsr commit_scroll_offset
    rts

; Copy the first piece before the loop. The bird is not on screen yet, so
; the hidden rows are plain playfield. Leaves COPY_SLICE at 1.
prime_back_buffer:
    jsr copy_current_slice
    inc COPY_SLICE
    rts

; Copy the finished playfield into the hidden buffer. Both pairs are
; page-aligned and 1000 bytes long: three full pages plus the 232-byte tail.
mirror_playfield_to_back:
    lda #>COLOR_RAM
    ldx #>BACK_COLOR_RAM
    jsr mirror_block
    lda #>SCREEN_RAM
    ldx #>BACK_SCREEN_RAM

; A is the source page, X the destination page. Pages are contiguous, so
; incrementing the high byte walks the next page of the same buffer.
mirror_block:
    sta SCREEN_SOURCE + 1
    stx SCREEN_DESTINATION + 1
    ldy #0
    sty SCREEN_SOURCE
    sty SCREEN_DESTINATION
    ldx #SCREEN_SIZE / 256
mirror_page:
    lda (SCREEN_SOURCE),y
    sta (SCREEN_DESTINATION),y
    iny
    bne mirror_page
    inc SCREEN_SOURCE + 1
    inc SCREEN_DESTINATION + 1
    dex
    bne mirror_page
mirror_tail:
    lda (SCREEN_SOURCE),y
    sta (SCREEN_DESTINATION),y
    iny
    cpy #<SCREEN_SIZE
    bne mirror_tail
    rts

; Synchronize on the rising crossing of the border raster. $FF1D returns only
; the low 8 bits (lines 256-311 read as 0-55), and a PAL frame crosses the
; chosen value exactly once. The loop does not invoke the KERNAL.
wait_for_frame:
wait_before_line:
    lda TED_RASTER_LO
    cmp #RASTER_BORDER
    bcs wait_before_line
wait_after_line:
    lda TED_RASTER_LO
    cmp #RASTER_BORDER
    bcc wait_after_line
    rts

; One pixel per frame. The matrix steps every eight frames. Each piece is
; written into the hidden buffer after the register stores, so a long copy
; cannot move $FF07/$FF14 down into the next picture. The new column is
; finished on the frame before the wrap; the wrap itself only stores the
; two registers, while the beam is still in the border.
advance_scroll:
    dec SCROLL_OFFSET
    bpl scroll_write
    lda #INITIAL_SCROLL_OFFSET
    sta SCROLL_OFFSET
    lda FLIP_READY
    beq scroll_write
    lda #0
    sta FLIP_READY
    jsr swap_buffers
scroll_write:
    jsr commit_scroll_offset
    jsr copy_current_slice
    inc COPY_SLICE
    lda COPY_SLICE
    cmp #SCROLL_SLICE_COUNT
    bcc advance_scroll_done
    lda #0
    sta COPY_SLICE
    jsr draw_back_column
    lda #1
    sta FLIP_READY
advance_scroll_done:
    rts

commit_scroll_offset:
    lda #TED_CONTROL2_TEXT_38_COLS
    ora SCROLL_OFFSET
    sta TED_CONTROL2
    rts

; Each slice contains six encoded rows. Bit 7 selects color RAM; the low
; bits are the row. Screen pieces come first, then the same rows of color,
; so the hidden buffer is only shown once every pipe cell has been copied.
copy_current_slice:
    lda COPY_SLICE
    asl
    clc
    adc COPY_SLICE
    asl
    sta ROW_INDEX
    lda #SCROLL_ROWS_PER_SLICE
    sta PIPE_HERE
copy_slice_row:
    ldx ROW_INDEX
    lda slice_rows,x
    inc ROW_INDEX
    jsr copy_encoded_row
    dec PIPE_HERE
    bne copy_slice_row
    rts

copy_encoded_row:
    cmp #$ff
    beq copy_row_done
    ; The caller increments ROW_INDEX between the load and this jsr, and
    ; that inc replaces N. Compare again so bit 7 still selects color RAM.
    cmp #$80
    bcc copy_from_screen
    and #$1f
    ldx BACK_COLOR_HI
    ldy VISIBLE_COLOR_HI
    jmp copy_shifted_row
copy_from_screen:
    ldx BACK_SCREEN_HI
    ldy VISIBLE_SCREEN_HI
copy_shifted_row:
    jsr point_row
    ; dest[0..38] = source[1..39]. Advance the source pointer once rather
    ; than adjusting Y twice per byte: variable gaps require more rows.
    inc SCREEN_SOURCE
    bne shifted_source_ready
    inc SCREEN_SOURCE + 1
shifted_source_ready:
    ldy #0
copy_shifted_byte:
    lda (SCREEN_SOURCE),y
    sta (SCREEN_DESTINATION),y
    iny
    cpy #SCREEN_COLUMNS - 1
    bne copy_shifted_byte
copy_row_done:
    rts

; Generate the next ring entry and draw it into hidden column 39. Borrow
; WORLD_COLUMN for addressing and restore it; swap_buffers keeps the increment.
draw_back_column:
    jsr generate_obstacle_column
    lda BACK_SCREEN_HI
    sta TARGET_SCREEN_HI
    lda BACK_COLOR_HI
    sta TARGET_COLOR_HI
    inc WORLD_COLUMN
    ldx #SCREEN_COLUMNS - 1
    jsr render_world_column
    dec WORLD_COLUMN
    lda VISIBLE_SCREEN_HI
    sta TARGET_SCREEN_HI
    lda VISIBLE_COLOR_HI
    sta TARGET_COLOR_HI
    rts

swap_buffers:
    lda BACK_SCREEN_HI
    ldx VISIBLE_SCREEN_HI
    sta VISIBLE_SCREEN_HI
    stx BACK_SCREEN_HI

    lda BACK_COLOR_HI
    ldx VISIBLE_COLOR_HI
    sta VISIBLE_COLOR_HI
    stx BACK_COLOR_HI

    lda BACK_FF14
    ldx VISIBLE_FF14
    sta VISIBLE_FF14
    stx BACK_FF14
    jsr commit_video_ptr

    inc WORLD_COLUMN
    inc COLUMN_UPDATE_COUNTER

    lda VISIBLE_SCREEN_HI
    sta TARGET_SCREEN_HI
    lda VISIBLE_COLOR_HI
    sta TARGET_COLOR_HI
    rts

; $FF14 is sampled at the start of a raster line. A store later in the line
; is queued for the next line, and that queue is discarded once the text
; window has closed, so the picture would keep the old matrix for the whole
; next frame. Wait for the line edge, then store before cycle 16.
commit_video_ptr:
    ldx VISIBLE_FF14
    lda TED_RASTER_LO
commit_video_spin:
    cmp TED_RASTER_LO
    beq commit_video_spin
    stx TED_VIDEO_ADDR
    rts

; A = row 0-24, X = screen page, Y = color page. Both buffers are
; page-aligned. Clobbers A and X, preserves Y.
point_row:
    stx SCREEN_DESTINATION + 1
    sty SCREEN_SOURCE + 1
    tax
    lda row_offset_lo,x
    sta SCREEN_DESTINATION
    sta SCREEN_SOURCE
    lda row_offset_hi,x
    clc
    adc SCREEN_DESTINATION + 1
    sta SCREEN_DESTINATION + 1
    lda row_offset_hi,x
    clc
    adc SCREEN_SOURCE + 1
    sta SCREEN_SOURCE + 1
    rts

slice_rows:
!set copy_row = 1
!do while copy_row < GROUND_FIRST_ROW {
    !byte copy_row
    !set copy_row = copy_row + 1
}
!set copy_row = 1
!do while copy_row < GROUND_FIRST_ROW {
    !byte $80 | copy_row
    !set copy_row = copy_row + 1
}
; Six unused slots. HUD and ground never vary between columns.
!fill SCROLL_SLICE_COUNT * SCROLL_ROWS_PER_SLICE - (GROUND_FIRST_ROW - 1) * 2, $ff

row_offset_lo:
!set row_number = 0
!do while row_number < SCREEN_ROWS {
    !byte <(row_number * SCREEN_COLUMNS)
    !set row_number = row_number + 1
}
row_offset_hi:
!set row_number = 0
!do while row_number < SCREEN_ROWS {
    !byte >(row_number * SCREEN_COLUMNS)
    !set row_number = row_number + 1
}
