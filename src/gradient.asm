; Change background and border together at identical raster positions. The
; lower and top borders each get their own event. The KERNAL dispatcher calls
; this through $0314 after acknowledging the TED IRQ.
initialise_background_gradient:
    sei
    lda #<background_gradient_irq
    sta KERNAL_IRQ_VECTOR
    lda #>background_gradient_irq
    sta KERNAL_IRQ_VECTOR + 1
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda #BACKGROUND_GRADIENT_FIRST_RASTER
    sta TED_RASTER_COMPARE
    lda #BG_GRADIENT_START_COLOR
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
    ; $FF0A bit 1 enables raster IRQs; bit 0 is raster-compare bit 8.
    lda #2
    sta TED_IRQ_STATUS
    sta TED_IRQ_ENABLE
    cli
    rts

; Called after the KERNAL has saved A/X/Y. Use its epilogue to restore the
; caller's registers and hardware frame; a direct RTI would leak stack bytes.
background_gradient_irq:
    lda #2
    sta TED_IRQ_STATUS
    ldx BACKGROUND_GRADIENT_INDEX
    cpx #BACKGROUND_GRADIENT_LEVELS
    bcc set_gradient_level
    beq set_bottom_border
set_top_border:
    lda #BG_GRADIENT_START_COLOR
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda #BACKGROUND_GRADIENT_FIRST_RASTER
    sta TED_RASTER_COMPARE
    lda #2
    sta TED_IRQ_ENABLE
    jmp restore_gradient_irq
set_bottom_border:
    lda #FRAME_BOTTOM_COLOR
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
    lda #(BACKGROUND_GRADIENT_LEVELS + 1)
    sta BACKGROUND_GRADIENT_INDEX
    lda #<BACKGROUND_GRADIENT_TOP_RASTER
    sta TED_RASTER_COMPARE
    ; The visible PAL canvas starts at counter $113, so compare bit 8 is set.
    lda #3
    sta TED_IRQ_ENABLE
    jmp restore_gradient_irq
set_gradient_level:
    lda background_gradient_colors,x
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
    inx
    stx BACKGROUND_GRADIENT_INDEX
    dex
    lda background_gradient_rasters,x
    sta TED_RASTER_COMPARE
restore_gradient_irq:
    jmp KERNAL_IRQ_EXIT

; Seven equally sized bands cover the active display, with luminance 1 at the
; first screen line and luminance 7 through the last line. Both TED color
; registers receive each entry on the same raster event.
background_gradient_colors:
    !byte $1d, $2d, $3d, $4d, $5d, $6d, $7d

; TED raster-counter coordinates: active display $04..$CB, lower border
; starts at $CC. Seven bands split 200 lines into 28/29-line intervals.
background_gradient_rasters:
    !byte $21, $3d, $5a, $76, $93, $af, BACKGROUND_GRADIENT_BOTTOM_RASTER
