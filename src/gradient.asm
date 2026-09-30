; Set background and side-frame colors at each text-row boundary. The lower
; border and top border each get their own raster event. The KERNAL dispatcher
; calls this through $0314 after acknowledging the TED IRQ.
initialise_background_gradient:
    sei
    lda #<background_gradient_irq
    sta KERNAL_IRQ_VECTOR
    lda #>background_gradient_irq
    sta KERNAL_IRQ_VECTOR + 1
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda #BACKGROUND_GRADIENT_FIRST_RASTER
    sta BACKGROUND_GRADIENT_RASTER
    sta TED_RASTER_COMPARE
    lda #BG_GRADIENT_START_COLOR
    sta TED_COLOR_BG
    sta TED_BORDER_COLOR
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
    cpx #BACKGROUND_GRADIENT_BANDS
    bcs gradient_border_events
    lda background_gradient_colors,x
    sta TED_COLOR_BG
    lda background_frame_colors,x
    sta TED_BORDER_COLOR
    inx
    stx BACKGROUND_GRADIENT_INDEX
    lda BACKGROUND_GRADIENT_RASTER
    clc
    adc #BACKGROUND_GRADIENT_LINES_PER_BAND
    sta BACKGROUND_GRADIENT_RASTER
    sta TED_RASTER_COMPARE
    jmp restore_gradient_irq
gradient_border_events:
    cpx #(BACKGROUND_GRADIENT_BANDS + 1)
    bcs set_top_border_color
    lda #FRAME_BOTTOM_COLOR
    sta TED_BORDER_COLOR
    inx
    stx BACKGROUND_GRADIENT_INDEX
    lda #BACKGROUND_GRADIENT_TOP_RASTER
    sta BACKGROUND_GRADIENT_RASTER
    sta TED_RASTER_COMPARE
    jmp restore_gradient_irq
set_top_border_color:
    lda #BG_GRADIENT_START_COLOR
    sta TED_BORDER_COLOR
    lda #0
    sta BACKGROUND_GRADIENT_INDEX
    lda #BACKGROUND_GRADIENT_FIRST_RASTER
    sta BACKGROUND_GRADIENT_RASTER
    sta TED_RASTER_COMPARE
restore_gradient_irq:
    jmp KERNAL_IRQ_EXIT

; Background luminance 0..7 is spread across the sky and reaches 7 by row 21.
; It stays at 7 through the solid ground rows.
background_gradient_colors:
    !byte $0d, $0d, $0d, $1d, $1d, $1d, $2d, $2d
    !byte $2d, $3d, $3d, $3d, $4d, $4d, $4d, $5d
    !byte $5d, $5d, $6d, $6d, $6d, $7d, $7d, $7d, $7d

; Side frame ramps from luminance 1 to 7 over 25 text rows, using 3/4-row
; intervals for the closest even spacing; the lower border is handled at $F8.
background_frame_colors:
    !byte $1d, $1d, $1d, $1d, $2d, $2d, $2d, $3d
    !byte $3d, $3d, $3d, $4d, $4d, $4d, $5d, $5d
    !byte $5d, $5d, $6d, $6d, $6d, $7d, $7d, $7d, $7d
