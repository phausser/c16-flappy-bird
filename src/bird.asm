initialise_bird:
    lda #0
    sta BIRD_Y_FRACTION
    sta BIRD_VELOCITY_FRACTION
    sta BIRD_VELOCITY
    sta BIRD_ANIM_TIMER
    lda #BIRD_START_Y
    sta BIRD_Y_POSITION
    jsr render_bird
    rts

update_bird_physics:
    lda FLAP_PRESSED
    beq apply_gravity
    lda #0
    sta BIRD_VELOCITY_FRACTION
    lda #BIRD_FLAP_VELOCITY
    sta BIRD_VELOCITY
    jmp update_bird_position

apply_gravity:
    clc
    lda BIRD_VELOCITY_FRACTION
    adc #BIRD_GRAVITY
    sta BIRD_VELOCITY_FRACTION
    lda BIRD_VELOCITY
    adc #0
    ; BIRD_VELOCITY is signed. An unsigned compare treats the upward
    ; impulse ($FE) as greater than the fall cap and cancels the flap
    ; on the very next frame.
    bmi store_velocity
    cmp #BIRD_MAX_FALL_SPEED
    bcc store_velocity
    lda #BIRD_MAX_FALL_SPEED
store_velocity:
    sta BIRD_VELOCITY

update_bird_position:
    clc
    lda BIRD_Y_FRACTION
    adc BIRD_VELOCITY_FRACTION
    sta BIRD_Y_FRACTION
    lda BIRD_Y_POSITION
    adc BIRD_VELOCITY
    sta BIRD_Y_POSITION

    rts

; Restores whatever playfield content (sky or pipe) the bird's previous cell
; block was covering, using the snapshot render_bird took before it painted
; there. The block is 3x2, or 3x3 when the counter-shift used the tail
; column. Must run before the hidden-buffer copy: the bird overlaps the
; pipe rows, and those glyphs must not be copied across.
clear_bird:
    lda BIRD_PREV_ROW
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda BIRD_UNDER_GLYPH + 0
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 0
    sta (SCREEN_SOURCE),y
    iny
    lda BIRD_UNDER_GLYPH + 1
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 1
    sta (SCREEN_SOURCE),y

    lda BIRD_PREV_ROW
    clc
    adc #1
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda BIRD_UNDER_GLYPH + 2
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 2
    sta (SCREEN_SOURCE),y
    iny
    lda BIRD_UNDER_GLYPH + 3
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 3
    sta (SCREEN_SOURCE),y

    lda BIRD_PREV_ROW
    clc
    adc #2
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda BIRD_UNDER_GLYPH + 4
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 4
    sta (SCREEN_SOURCE),y
    iny
    lda BIRD_UNDER_GLYPH + 5
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR + 5
    sta (SCREEN_SOURCE),y

    lda BIRD_WIDE
    beq clear_bird_done
    lda BIRD_PREV_ROW
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN + 2
    lda BIRD_UNDER_TAIL_GLYPH + 0
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_TAIL_COLOR + 0
    sta (SCREEN_SOURCE),y
    lda BIRD_PREV_ROW
    clc
    adc #1
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN + 2
    lda BIRD_UNDER_TAIL_GLYPH + 1
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_TAIL_COLOR + 1
    sta (SCREEN_SOURCE),y
    lda BIRD_PREV_ROW
    clc
    adc #2
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN + 2
    lda BIRD_UNDER_TAIL_GLYPH + 2
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_TAIL_COLOR + 2
    sta (SCREEN_SOURCE),y
clear_bird_done:
    rts

; Composes the current animation frame into the dynamic bird glyphs.
; Vertical sub-pixel offset selects the scanline. Horizontal offset is
; 7 - SCROLL_OFFSET, so the hardware scroll and the bitmap walk in opposite
; directions and the bird stays on one screen pixel. The tail column is
; painted only when that offset is nonzero.
render_bird:
    lda #INITIAL_SCROLL_OFFSET
    sec
    sbc SCROLL_OFFSET
    sta BIRD_H_SHIFT
    lda BIRD_Y_POSITION
    and #$07
    sta BIRD_SUB_Y
    lda BIRD_Y_POSITION
    lsr
    lsr
    lsr
    sta BIRD_TOP_ROW

    jsr select_bird_mask

    ldx #0
clear_dynamic_glyphs:
    lda #0
    sta CHARSET_RAM + (GLYPH_BIRD_LEFT_ROW0 * 8),x
    sta CHARSET_RAM + (GLYPH_BIRD_RIGHT_ROW0 * 8),x
    sta CHARSET_RAM + (GLYPH_BIRD_TAIL_ROW0 * 8),x
    inx
    cpx #24
    bne clear_dynamic_glyphs

    ldy #0
    ldx BIRD_SUB_Y
    lda #16
    sta BIRD_ROW_COUNTER
copy_bird_rows:
    lda (MASK_POINTER),y
    sta BIRD_SHIFT_LEFT
    iny
    lda (MASK_POINTER),y
    sta BIRD_SHIFT_RIGHT
    iny
    lda #0
    sta BIRD_SHIFT_TAIL
    lda BIRD_H_SHIFT
    beq store_shifted_row
    sta BIRD_SHIFT_COUNT
shift_bird_row:
    lsr BIRD_SHIFT_LEFT
    ror BIRD_SHIFT_RIGHT
    ror BIRD_SHIFT_TAIL
    dec BIRD_SHIFT_COUNT
    bne shift_bird_row
store_shifted_row:
    lda BIRD_SHIFT_LEFT
    sta CHARSET_RAM + (GLYPH_BIRD_LEFT_ROW0 * 8),x
    lda BIRD_SHIFT_RIGHT
    sta CHARSET_RAM + (GLYPH_BIRD_RIGHT_ROW0 * 8),x
    lda BIRD_SHIFT_TAIL
    sta CHARSET_RAM + (GLYPH_BIRD_TAIL_ROW0 * 8),x
    inx
    dec BIRD_ROW_COUNTER
    bne copy_bird_rows

    jsr set_bird_screen_cells
    lda BIRD_TOP_ROW
    sta BIRD_PREV_ROW
    rts

; Picks the source mask for this frame: a fast fall selects the dive pose,
; otherwise the wing cycle advances on a timer. Result goes in MASK_POINTER.
select_bird_mask:
    lda BIRD_VELOCITY
    bmi choose_animated_mask
    cmp #BIRD_DIVE_VELOCITY
    bcc choose_animated_mask

    lda #<BIRD_MASK_DIVE
    sta MASK_POINTER
    lda #>BIRD_MASK_DIVE
    sta MASK_POINTER + 1
    rts

choose_animated_mask:
    inc BIRD_ANIM_TIMER
    lda BIRD_ANIM_TIMER
    lsr
    lsr
    lsr
    and #$03
    tax
    lda wing_phase_table,x
    tax
    lda wing_mask_table_lo,x
    sta MASK_POINTER
    lda wing_mask_table_hi,x
    sta MASK_POINTER + 1
    rts

; Points SCREEN_DESTINATION / SCREEN_SOURCE at the visible buffer's row A.
; The pages follow the last $FF14 flip, so the bird is always painted on the
; buffer the TED is actually showing.
row_to_pointers:
    ldx VISIBLE_SCREEN_HI
    ldy VISIBLE_COLOR_HI
    jmp point_row

; Saves the true playfield content of the bird's new cell block into
; BIRD_UNDER_GLYPH/COLOR, then paints the freshly composed bird glyphs over
; it. BIRD_TOP_ROW must already hold this frame's top row. The tail column
; is included only when BIRD_H_SHIFT is nonzero; BIRD_WIDE records that for
; the next clear.
set_bird_screen_cells:
    lda BIRD_TOP_ROW
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 0
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 0
    lda #GLYPH_BIRD_LEFT_ROW0
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 1
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 1
    lda #GLYPH_BIRD_RIGHT_ROW0
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    lda BIRD_H_SHIFT
    beq set_row0_done
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_TAIL_GLYPH + 0
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_TAIL_COLOR + 0
    lda #GLYPH_BIRD_TAIL_ROW0
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
set_row0_done:

    lda BIRD_TOP_ROW
    clc
    adc #1
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 2
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 2
    lda #GLYPH_BIRD_LEFT_ROW1
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 3
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 3
    lda #GLYPH_BIRD_RIGHT_ROW1
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    lda BIRD_H_SHIFT
    beq set_row1_done
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_TAIL_GLYPH + 1
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_TAIL_COLOR + 1
    lda #GLYPH_BIRD_TAIL_ROW1
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
set_row1_done:

    lda BIRD_TOP_ROW
    clc
    adc #2
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 4
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 4
    lda #GLYPH_BIRD_LEFT_ROW2
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH + 5
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR + 5
    lda #GLYPH_BIRD_RIGHT_ROW2
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
    lda BIRD_H_SHIFT
    beq set_row2_done
    iny
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_TAIL_GLYPH + 2
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_TAIL_COLOR + 2
    lda #GLYPH_BIRD_TAIL_ROW2
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
set_row2_done:
    lda BIRD_H_SHIFT
    sta BIRD_WIDE
    rts

; -----------------------------------------------------------------------
; Bird sprite data. Each mask is 16 rows of (left-byte, right-byte) making
; a 16x16 1-bit image. render_bird places it at a vertical byte offset and
; shifts it right by 7 - SCROLL_OFFSET so the fine scroll does not drag the
; bird. Reached only via MASK_POINTER, never by falling through code.
; -----------------------------------------------------------------------

wing_phase_table:
    !byte 0, 1, 2, 1

wing_mask_table_lo:
    !byte <BIRD_MASK_UP, <BIRD_MASK_MID, <BIRD_MASK_DOWN
wing_mask_table_hi:
    !byte >BIRD_MASK_UP, >BIRD_MASK_MID, >BIRD_MASK_DOWN

BIRD_MASK_UP:
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $3e, $00
    !byte $7f, $c0
    !byte $7f, $e0
    !byte $1f, $f0
    !byte $3f, $fe
    !byte $3f, $ff
    !byte $3f, $fe
    !byte $1f, $f0
    !byte $0f, $e0
    !byte $07, $c0
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00

BIRD_MASK_MID:
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $07, $c0
    !byte $0f, $e0
    !byte $1f, $f0
    !byte $3f, $fe
    !byte $ff, $ff
    !byte $ff, $fe
    !byte $1f, $f0
    !byte $0f, $e0
    !byte $07, $c0
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00

BIRD_MASK_DOWN:
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $07, $c0
    !byte $0f, $e0
    !byte $1f, $f0
    !byte $3f, $fe
    !byte $3f, $ff
    !byte $3f, $fe
    !byte $1f, $f0
    !byte $7f, $e0
    !byte $7f, $c0
    !byte $3e, $00
    !byte $1c, $00
    !byte $00, $00

BIRD_MASK_DIVE:
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
    !byte $c0, $00
    !byte $07, $c0
    !byte $7f, $e0
    !byte $ff, $f0
    !byte $3f, $fe
    !byte $3f, $ff
    !byte $3f, $fe
    !byte $1f, $f0
    !byte $0f, $e0
    !byte $07, $c0
    !byte $00, $00
    !byte $00, $00
    !byte $00, $00
