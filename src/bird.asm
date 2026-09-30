initialise_bird:
    lda #0
    sta BIRD_Y_FRACTION
    sta BIRD_VELOCITY_FRACTION
    sta BIRD_VELOCITY
    sta BIRD_ANIM_TIMER
    sta BIRD_FRAME_INDEX
    sta SCROLL_PENDING
    lda #BIRD_FRAME_TICKS
    sta BIRD_ANIM_TIMER
    lda #$ff
    sta BIRD_CACHE_SHIFT
    lda #BIRD_START_Y
    sta BIRD_Y_POSITION
    jsr select_bird_mask
    jsr compose_bird
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

; Build candidate glyphs in scratch RAM, never in the live character set.
; SCROLL_PENDING selects the next one-pixel scroll (including its wrap).
compose_bird:
    lda SCROLL_OFFSET
    sec
    sbc SCROLL_PENDING
    and #7
    eor #7
    sta BIRD_H_SHIFT
    lda BIRD_Y_POSITION
    and #7
    sta BIRD_SUB_Y
    ; Signed divide by eight: the transparent top can extend above row 0.
    lda BIRD_Y_POSITION
    cmp #$f0
    ror
    cmp #$80
    ror
    cmp #$80
    ror
    sta BIRD_TOP_ROW
    jsr prepare_shifted_mask
    ldx #BIRD_GLYPH_BYTES - 1
    lda #0
clear_candidate_glyphs:
    sta BIRD_CANDIDATE,x
    dex
    bpl clear_candidate_glyphs
    ldx #0
    ldy BIRD_SUB_Y
copy_candidate_rows:
    lda BIRD_SHIFTED,x
    sta BIRD_CANDIDATE,y
    lda BIRD_SHIFTED + BIRD_HEIGHT,x
    sta BIRD_CANDIDATE + 24,y
    lda BIRD_SHIFTED + (BIRD_HEIGHT * 2),x
    sta BIRD_CANDIDATE + 48,y
    lda BIRD_SHIFTED + (BIRD_HEIGHT * 3),x
    sta BIRD_CANDIDATE + 72,y
    iny
    inx
    cpx #BIRD_HEIGHT
    bcc copy_candidate_rows
    ; One occupancy flag per glyph. A blank cell must keep BOTH the
    ; environment character and its color, even in the overflow row.
    ldx #0
    ldy #0
candidate_cell:
    lda BIRD_CANDIDATE,x
    ora BIRD_CANDIDATE + 1,x
    ora BIRD_CANDIDATE + 2,x
    ora BIRD_CANDIDATE + 3,x
    ora BIRD_CANDIDATE + 4,x
    ora BIRD_CANDIDATE + 5,x
    ora BIRD_CANDIDATE + 6,x
    ora BIRD_CANDIDATE + 7,x
    sta BIRD_OCCUPIED,y
    txa
    clc
    adc #8
    tax
    iny
    cpy #BIRD_CELLS
    bne candidate_cell
    rts

; Horizontal bit shifts are the expensive part. Cache them across Y
; probes and frames, keyed by the source pose and hardware counter-shift.
prepare_shifted_mask:
    lda MASK_POINTER
    cmp BIRD_CACHE_MASK
    bne rebuild_shifted_mask
    lda MASK_POINTER + 1
    cmp BIRD_CACHE_MASK + 1
    bne rebuild_shifted_mask
    lda BIRD_H_SHIFT
    cmp BIRD_CACHE_SHIFT
    beq shifted_mask_ready
    ; Consecutive fine-scroll phases differ by exactly one bit. Shift the
    ; cached four bytes once instead of rebuilding all shifts from scratch.
    sec
    sbc BIRD_CACHE_SHIFT
    cmp #1
    bne rebuild_shifted_mask
    lda BIRD_CACHE_SHIFT
    cmp #7
    bcs rebuild_shifted_mask
    inc BIRD_CACHE_SHIFT
    ldx #BIRD_HEIGHT - 1
shift_cached_row:
    lsr BIRD_SHIFTED,x
    ror BIRD_SHIFTED + BIRD_HEIGHT,x
    ror BIRD_SHIFTED + (BIRD_HEIGHT * 2),x
    ror BIRD_SHIFTED + (BIRD_HEIGHT * 3),x
    dex
    bpl shift_cached_row
shifted_mask_ready:
    rts
rebuild_shifted_mask:
    lda BIRD_H_SHIFT
    sta BIRD_CACHE_SHIFT
    lda MASK_POINTER
    sta BIRD_CACHE_MASK
    lda MASK_POINTER + 1
    sta BIRD_CACHE_MASK + 1
    ldy #0
    ldx #0
copy_bird_rows:
    lda (MASK_POINTER),y
    sta BIRD_SHIFT_LEFT
    iny
    lda (MASK_POINTER),y
    sta BIRD_SHIFT_RIGHT
    iny
    lda (MASK_POINTER),y
    sta BIRD_SHIFT_TAIL
    iny
    lda #0
    sta BIRD_SHIFT_EXTRA
    lda BIRD_H_SHIFT
    beq store_shifted_row
    sta BIRD_SHIFT_COUNT
shift_bird_row:
    lsr BIRD_SHIFT_LEFT
    ror BIRD_SHIFT_RIGHT
    ror BIRD_SHIFT_TAIL
    ror BIRD_SHIFT_EXTRA
    dec BIRD_SHIFT_COUNT
    bne shift_bird_row
store_shifted_row:
    lda BIRD_SHIFT_LEFT
    sta BIRD_SHIFTED,x
    lda BIRD_SHIFT_RIGHT
    sta BIRD_SHIFTED + BIRD_HEIGHT,x
    lda BIRD_SHIFT_TAIL
    sta BIRD_SHIFTED + (BIRD_HEIGHT * 2),x
    lda BIRD_SHIFT_EXTRA
    sta BIRD_SHIFTED + (BIRD_HEIGHT * 3),x
    inx
    cpy #BIRD_MASK_BYTES
    bne copy_bird_rows
    rts

; Restore all in-bounds snapshot cells before copying the hidden buffer.
clear_bird:
    lda BIRD_PREV_ROW
    sta ROW_INDEX
    lda #0
    sta CELL_INDEX
clear_bird_row:
    lda ROW_INDEX
    cmp #SCREEN_ROWS
    bcs clear_next_row
    jsr row_to_pointers
    ldx CELL_INDEX
    ldy #BIRD_SCREEN_COLUMN
clear_bird_cell:
    lda BIRD_UNDER_GLYPH,x
    sta (SCREEN_DESTINATION),y
    lda BIRD_UNDER_COLOR,x
    sta (SCREEN_SOURCE),y
    inx
    iny
    cpy #BIRD_SCREEN_COLUMN + BIRD_COLUMNS
    bcc clear_bird_cell
clear_next_row:
    inc ROW_INDEX
    lda CELL_INDEX
    clc
    adc #BIRD_COLUMNS
    sta CELL_INDEX
    cmp #BIRD_CELLS
    bcc clear_bird_row
    rts

; Publish only the accepted scratch image. Occupancy uses column-major
; glyph order, while the saved screen cells are in row-major order.
render_bird:
    ldx #BIRD_GLYPH_BYTES - 1
publish_bird_glyphs:
    lda BIRD_CANDIDATE,x
    sta CHARSET_RAM + (GLYPH_BIRD_LEFT_ROW0 * 8),x
    dex
    bpl publish_bird_glyphs
    lda BIRD_TOP_ROW
    sta BIRD_PREV_ROW
    sta ROW_INDEX
    lda #0
    sta CELL_INDEX
render_bird_row:
    lda ROW_INDEX
    cmp #SCREEN_ROWS
    bcs render_next_row
    jsr row_to_pointers
    ldy #BIRD_SCREEN_COLUMN
render_bird_cell:
    ldx CELL_INDEX
    lda (SCREEN_DESTINATION),y
    sta BIRD_UNDER_GLYPH,x
    lda (SCREEN_SOURCE),y
    sta BIRD_UNDER_COLOR,x
    lda bird_cell_order,x
    tax
    lda BIRD_OCCUPIED,x
    beq render_cell_done
    txa
    clc
    adc #GLYPH_BIRD_LEFT_ROW0
    sta (SCREEN_DESTINATION),y
    lda #TED_BIRD_COLOR
    sta (SCREEN_SOURCE),y
render_cell_done:
    inc CELL_INDEX
    iny
    cpy #BIRD_SCREEN_COLUMN + BIRD_COLUMNS
    bcc render_bird_cell
    jmp render_row_done
render_next_row:
    lda CELL_INDEX
    clc
    adc #BIRD_COLUMNS
    sta CELL_INDEX
render_row_done:
    inc ROW_INDEX
    lda CELL_INDEX
    cmp #BIRD_CELLS
    bcc render_bird_row
    rts

bird_cell_order:
    !byte 0, 3, 6, 9, 1, 4, 7, 10, 2, 5, 8, 11

; GIF frames last 100 ms each: five PAL frames, independent of velocity.
select_bird_mask:
    lda BIRD_ANIM_TIMER
    bne bird_animation_tick
    lda BIRD_FRAME_INDEX
    clc
    adc #1
    and #3
    sta BIRD_FRAME_INDEX
    lda #BIRD_FRAME_TICKS
    sta BIRD_ANIM_TIMER
bird_animation_tick:
    dec BIRD_ANIM_TIMER
    ldx BIRD_FRAME_INDEX
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

wing_mask_table_lo:
    !byte <BIRD_MASK_0, <BIRD_MASK_1, <BIRD_MASK_2, <BIRD_MASK_3
wing_mask_table_hi:
    !byte >BIRD_MASK_0, >BIRD_MASK_1, >BIRD_MASK_2, >BIRD_MASK_3

!source "src/bird_masks.inc"
