; Own the hardware IRQ, including its register save/restore. On a 16 KiB
; C16, the RAM IRQ vector at $FFFE mirrors $3FFE in the safety reserve.
initialise_background_gradient:
    sei
    lda #<background_gradient_top_irq
    sta HARDWARE_IRQ_VECTOR
    lda #>background_gradient_top_irq
    sta HARDWARE_IRQ_VECTOR + 1
    sta TED_RAM_ENABLE
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda background_gradient_colors
    sta gradient_color + 1
    lda #BACKGROUND_GRADIENT_FIRST_RASTER - 2
    sta TED_RASTER_COMPARE
    lda #BG_GRADIENT_START_COLOR
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
    lda TED_IRQ_STATUS
    sta TED_IRQ_STATUS
    lda #2
    sta TED_IRQ_ENABLE
    cli
    rts

; Normal bands retain the short entry path. Their color operand is prepared
; by the preceding IRQ; X is saved only after the two color writes.
background_gradient_irq:
    pha
    lda TED_IRQ_STATUS
    sta TED_IRQ_STATUS
gradient_wait_visible:
    lda TED_RASTER_HORIZONTAL
    cmp #$a0
    bcs gradient_wait_visible
gradient_wait_blank:
    lda TED_RASTER_HORIZONTAL
    cmp #$a0
    bcc gradient_wait_blank
gradient_color:
    lda #$1d
gradient_border_store:
    sta TED_BORDER_COLOR
gradient_background_store:
    sta TED_COLOR_BG
    txa
    pha
    jmp gradient_schedule_next

; At the top, enter on line 2 and wait across its right blank. The line-3
; character fetch holds the CPU until late in that line. Stores immediately
; after that fetch fall in the right blank, before line 4 displays row 0.
; A separate hardware vector keeps this extra work out of the other bands.
background_gradient_top_irq:
    pha
    lda TED_IRQ_STATUS
    sta TED_IRQ_STATUS
    txa
    pha
    ldx gradient_color + 1
; Use separate thresholds: enter the blank at $B0, accept the post-fetch
; sample below $BC. Reusing $B0 can miss a late read and skip a whole line.
gradient_top_wrap:
    lda TED_RASTER_HORIZONTAL
    cmp #$b0
    bcc gradient_top_wrap
gradient_top_fetch:
    lda TED_RASTER_HORIZONTAL
    cmp #$bc
    bcs gradient_top_fetch
gradient_top_border_store:
    stx TED_BORDER_COLOR
gradient_top_background_store:
    stx TED_COLOR_BG
gradient_schedule_next:
    ldx BACKGROUND_GRADIENT_INDEX
    inx
    cpx #BACKGROUND_GRADIENT_LEVELS + 2
    bcc gradient_next_ready
    ldx #0
gradient_next_ready:
    stx BACKGROUND_GRADIENT_INDEX
    cpx #0
    beq gradient_arm_top
    cpx #BACKGROUND_GRADIENT_LEVELS
    beq gradient_arm_floor
    lda #<background_gradient_irq
    sta HARDWARE_IRQ_VECTOR
    lda #>background_gradient_irq
    bne gradient_arm_vector
gradient_arm_floor:
    lda #<background_gradient_floor_irq
    sta HARDWARE_IRQ_VECTOR
    lda #>background_gradient_floor_irq
    bne gradient_arm_vector
gradient_arm_top:
    lda #<background_gradient_top_irq
    sta HARDWARE_IRQ_VECTOR
    lda #>background_gradient_top_irq
gradient_arm_vector:
    sta HARDWARE_IRQ_VECTOR + 1
    lda background_gradient_colors,x
    sta gradient_color + 1
    lda background_gradient_rasters,x
    sta TED_RASTER_COMPARE
    lda background_gradient_high,x
    sta TED_IRQ_ENABLE
    pla
    tax
    pla
    rti

; Character row 24 is fetched on the line before it is displayed. Enter two
; lines early, wait out that fetch, then set the floor color and scroll 0
; in the same blank. No other band writes $FF07, so their color stores stay
; on the short path. The main loop puts the playfield scroll back at $FC.
background_gradient_floor_irq:
    pha
    lda TED_IRQ_STATUS
    sta TED_IRQ_STATUS
    txa
    pha
    ldx gradient_color + 1
gradient_floor_wrap:
    lda TED_RASTER_HORIZONTAL
    cmp #$b0
    bcc gradient_floor_wrap
gradient_floor_fetch:
    lda TED_RASTER_HORIZONTAL
    cmp #$bc
    bcs gradient_floor_fetch
gradient_floor_border_store:
    stx TED_BORDER_COLOR
gradient_floor_background_store:
    stx TED_COLOR_BG
    lda #TED_CONTROL2_TEXT_38_COLS
gradient_floor_scroll_store:
    sta TED_CONTROL2
    jmp gradient_schedule_next

; Seven active bands, then lower and upper border. Each event supplies the
; entire 9-bit compare and enables only raster IRQs (bit 1).
; Band edges are shifted at most two lines to avoid the fetch pairs.
; Horizontal timing assumes PAL, vertical scroll 3 and normal TED speed.
background_gradient_colors:
    !byte (1 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (2 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (3 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (4 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (5 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (6 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte (7 << 4) + BACKGROUND_GRADIENT_COLOR
    !byte FRAME_BOTTOM_COLOR, BG_GRADIENT_START_COLOR
background_gradient_rasters:
    !byte BACKGROUND_GRADIENT_FIRST_RASTER - 2
    !byte 1 * BACKGROUND_GRADIENT_DISTANCE
    !byte 2 * BACKGROUND_GRADIENT_DISTANCE
    !byte 3 * BACKGROUND_GRADIENT_DISTANCE
    !byte 4 * BACKGROUND_GRADIENT_DISTANCE
    !byte 5 * BACKGROUND_GRADIENT_DISTANCE
    !byte 6 * BACKGROUND_GRADIENT_DISTANCE
    !byte <(BACKGROUND_GRADIENT_BOTTOM_RASTER - 2), <(BACKGROUND_GRADIENT_TOP_RASTER - 1)
background_gradient_high:
    !fill BACKGROUND_GRADIENT_LEVELS, 2
    !byte 2 | ((BACKGROUND_GRADIENT_BOTTOM_RASTER - 2) >> 8)
    !byte 2 | ((BACKGROUND_GRADIENT_TOP_RASTER - 1) >> 8)
