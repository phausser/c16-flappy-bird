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

; Clamp to the playfield so the sprite (plus its overflow row) never reaches
; the ground rows or wraps past the top. Hitting a bound also zeroes the
; velocity, standing in for a floor/ceiling until real collision exists.
    cmp #BIRD_Y_MAX + 1
    bcc clamp_done
    bit BIRD_VELOCITY
    bmi clamp_top
    lda #BIRD_Y_MAX
    sta BIRD_Y_POSITION
    jmp clamp_stop_velocity
clamp_top:
    lda #BIRD_Y_MIN
    sta BIRD_Y_POSITION
clamp_stop_velocity:
    lda #0
    sta BIRD_Y_FRACTION
    sta BIRD_VELOCITY
    sta BIRD_VELOCITY_FRACTION
clamp_done:
    rts

; Restores whatever playfield content (sky or pipe) the bird's previous 3x2
; cell block was covering, using the snapshot render_bird took before it
; painted there. Must run before the world-shift so a moving bird never
; leaves glyphs behind in columns the shift touches.
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
    rts

; Composes the current animation frame into the six dynamic bird glyphs at
; the correct sub-pixel row offset, then paints them into the 3x2 screen
; cell block at the bird's new position (saving what was there first).
render_bird:
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
    inx
    cpx #24
    bne clear_dynamic_glyphs

    ldy #0
    ldx BIRD_SUB_Y
    lda #16
    sta BIRD_ROW_COUNTER
copy_bird_rows:
    lda (MASK_POINTER),y
    sta CHARSET_RAM + (GLYPH_BIRD_LEFT_ROW0 * 8),x
    iny
    lda (MASK_POINTER),y
    sta CHARSET_RAM + (GLYPH_BIRD_RIGHT_ROW0 * 8),x
    iny
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

; Computes SCREEN_DESTINATION = SCREEN_RAM + A*SCREEN_COLUMNS and
; SCREEN_SOURCE = COLOR_RAM + A*SCREEN_COLUMNS for row number A (0-24).
row_to_pointers:
    pha
    lda #<SCREEN_RAM
    sta SCREEN_DESTINATION
    lda #>SCREEN_RAM
    sta SCREEN_DESTINATION + 1
    lda #<COLOR_RAM
    sta SCREEN_SOURCE
    lda #>COLOR_RAM
    sta SCREEN_SOURCE + 1
    pla
    tax
    beq row_to_pointers_done
row_to_pointers_loop:
    clc
    lda SCREEN_DESTINATION
    adc #SCREEN_COLUMNS
    sta SCREEN_DESTINATION
    bcc row_screen_ok
    inc SCREEN_DESTINATION + 1
row_screen_ok:
    clc
    lda SCREEN_SOURCE
    adc #SCREEN_COLUMNS
    sta SCREEN_SOURCE
    bcc row_color_ok
    inc SCREEN_SOURCE + 1
row_color_ok:
    dex
    bne row_to_pointers_loop
row_to_pointers_done:
    rts

; Saves the true playfield content of the bird's new 3x2 cell block into
; BIRD_UNDER_GLYPH/COLOR, then paints the freshly composed bird glyphs over
; it. BIRD_TOP_ROW must already hold this frame's top row.
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
    rts

; -----------------------------------------------------------------------
; Bird sprite data. Each mask is 16 rows of (left-byte, right-byte) making
; a 16x16 1-bit image; render_bird copies it into the dynamic glyphs at a
; runtime row offset, so no bit-shifting is needed for vertical sub-pixel
; movement. Reached only via MASK_POINTER, never by falling through code.
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
