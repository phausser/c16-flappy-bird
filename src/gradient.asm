; Own the hardware IRQ, including its register save/restore. On a 16 KiB
; C16, the RAM IRQ vector at $FFFE mirrors $3FFE in the safety reserve.
initialise_background_gradient:
    sei
    lda #<background_gradient_irq
    sta HARDWARE_IRQ_VECTOR
    lda #>background_gradient_irq
    sta HARDWARE_IRQ_VECTOR + 1
    sta TED_RAM_ENABLE
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda #$1d
    sta gradient_color + 1
    lda #BACKGROUND_GRADIENT_FIRST_RASTER - 1
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

; Prepare the immediate color in the previous IRQ: no table indexing
; or subroutine calls select the color before the two stores.
; X is saved only afterwards; Y is untouched. Never enter the KERNAL dispatcher or its exit routine.
background_gradient_irq:
    pha
    lda TED_IRQ_STATUS
    sta TED_IRQ_STATUS
; Enter one line ahead and wait for the right-hand horizontal blank.
; $FF1E exposes the horizontal counter; $A0 is just before the blank.
; The compare/branch/load delay puts the border store beyond the canvas,
; and the background store still precedes the next character window.
; Both sides of each boundary avoid character-fetch lines (low bits 3/4).
; Otherwise a bus steal between the two stores can expose a partial line.
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
    sta TED_BORDER_COLOR
    sta TED_COLOR_BG
    txa
    pha
    ldx BACKGROUND_GRADIENT_INDEX
    inx
    cpx #BACKGROUND_GRADIENT_LEVELS + 2
    bcc gradient_next_ready
    ldx #0
gradient_next_ready:
    stx BACKGROUND_GRADIENT_INDEX
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

; Seven active bands, then lower and upper border. Each event supplies the
; entire 9-bit compare and enables only raster IRQs (bit 1).
; Band edges are shifted at most two lines to avoid the fetch pairs.
; Horizontal timing assumes PAL, vertical scroll 3 and normal TED speed.
background_gradient_colors:
    !byte $1d, $2d, $3d, $4d, $5d, $6d, $7d
    !byte FRAME_BOTTOM_COLOR, BG_GRADIENT_START_COLOR
background_gradient_rasters:
    !byte BACKGROUND_GRADIENT_FIRST_RASTER - 1, $20, $3d, $59, $75, $90, $ae
    !byte <(BACKGROUND_GRADIENT_BOTTOM_RASTER - 1), <(BACKGROUND_GRADIENT_TOP_RASTER - 1)
background_gradient_high:
    !fill BACKGROUND_GRADIENT_LEVELS, 2
    !byte 2 | ((BACKGROUND_GRADIENT_BOTTOM_RASTER - 1) >> 8)
    !byte 2 | ((BACKGROUND_GRADIENT_TOP_RASTER - 1) >> 8)
