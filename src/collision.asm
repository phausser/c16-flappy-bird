; Select a safe pose, then test Y at the current world position, backing
; out one pixel at a time on contact. Finally try the one-pixel scroll.
; Display the last free pixel, which can differ from the previous frame.
prepare_bird_frame:
    lda #0
    sta SCROLL_PENDING
    lda MASK_POINTER
    sta BIRD_OLD_MASK
    lda MASK_POINTER + 1
    sta BIRD_OLD_MASK + 1
    lda BIRD_Y_POSITION
    sta BIRD_ORIGIN_Y
    jsr update_bird_physics
    lda BIRD_Y_POSITION
    sta BIRD_TARGET_Y
    jsr select_bird_mask
    ; Most frames are clear: compose the final pose and next scroll only
    ; once. Sub-cell movement cannot tunnel through an eight-pixel obstacle.
    lda #1
    sta SCROLL_PENDING
    jsr compose_bird
    jsr check_bird_collision
    bcs resolve_bird_contact
    rts
resolve_bird_contact:
    lda #0
    sta SCROLL_PENDING
    lda BIRD_ORIGIN_Y
    sta BIRD_Y_POSITION
    lda MASK_POINTER
    cmp BIRD_OLD_MASK
    bne check_new_pose
    lda MASK_POINTER + 1
    cmp BIRD_OLD_MASK + 1
    beq pose_is_safe
check_new_pose:
    jsr compose_bird
    jsr check_bird_collision
    bcc pose_is_safe
    ; A wing change must not create a collision or force a jump away from
    ; an edge. Retain the displayed pose if the new silhouette will not fit.
    lda BIRD_OLD_MASK
    sta MASK_POINTER
    lda BIRD_OLD_MASK + 1
    sta MASK_POINTER + 1
pose_is_safe:
    lda #1
    ldx BIRD_VELOCITY
    bpl movement_direction_known
    lda #$ff
movement_direction_known:
    sta BIRD_STEP
    lda BIRD_Y_POSITION
    cmp BIRD_TARGET_Y
    beq try_horizontal_scroll
    lda BIRD_TARGET_Y
    sta BIRD_Y_POSITION
    jsr compose_bird
    jsr check_bird_collision
    bcc try_horizontal_scroll
    ; At most four pixels per frame, less than an eight-pixel obstacle.
    ; Thus a free endpoint cannot tunnel through a solid cell. Only a hit
    ; needs the more expensive one-pixel backtrack to the contact position.
backtrack_bird_y:
    lda BIRD_Y_POSITION
    sec
    sbc BIRD_STEP
    sta BIRD_Y_POSITION
    jsr compose_bird
    jsr check_bird_collision
    bcs backtrack_bird_y
    jmp bird_contact
try_horizontal_scroll:
    lda #1
    sta SCROLL_PENDING
    jsr compose_bird
    jsr check_bird_collision
    bcc prepared_frame_done
    lda #0
    sta SCROLL_PENDING
bird_contact:
    lda #GAME_STATE_DEAD
    sta GAME_OVER
    lda #SOUND_DEATH
    sta SOUND_REQUEST
    lda #0
    sta BIRD_Y_FRACTION
    sta BIRD_VELOCITY_FRACTION
    sta BIRD_VELOCITY
    jsr compose_bird
prepared_frame_done:
    rts

; A nonempty candidate glyph may occupy only sky. Since solid obstacle
; faces lie on cell boundaries, this tests actual bird pixels, not its
; padded 32x24 allocation. All three multicolor pipe strips are solid.
; Read current column + 1 when testing the pending matrix wrap.
check_bird_collision:
    lda #BIRD_SCREEN_COLUMN
    ldx SCROLL_PENDING
    beq collision_column_known
    ldx SCROLL_OFFSET
    bne collision_column_known
    clc
    adc #1
collision_column_known:
    sta COLUMN_X
    lda BIRD_TOP_ROW
    sta ROW_INDEX
    lda #0
    sta CELL_INDEX
collision_row:
    lda ROW_INDEX
    cmp #PLAYFIELD_ROWS
    bcs collision_row_cells
    jsr row_to_pointers
collision_row_cells:
    ldy COLUMN_X
collision_cell:
    ldx CELL_INDEX
    lda bird_cell_order,x
    tax
    lda BIRD_OCCUPIED,x
    beq collision_cell_clear
    ; Row 24 is the floor even where the score cell is glyph 0. Reading it
    ; would treat the gaps between digits as sky.
    lda ROW_INDEX
    cmp #PLAYFIELD_ROWS
    bcs bird_collision
    lda (SCREEN_DESTINATION),y
    beq collision_cell_clear
    cmp #GLYPH_BIRD_LEFT_ROW0
    bcc bird_collision
    cmp #GLYPH_BIRD_LAST + 1
    bcs bird_collision
collision_cell_clear:
    inc CELL_INDEX
    iny
    tya
    sec
    sbc COLUMN_X
    cmp #BIRD_COLUMNS
    bcc collision_cell
    inc ROW_INDEX
    lda CELL_INDEX
    cmp #BIRD_CELLS
    bcc collision_row
    clc
    rts
bird_collision:
    sec
    rts
