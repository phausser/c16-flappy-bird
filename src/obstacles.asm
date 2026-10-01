; A 64-column ring stores gap starts (zero means sky). Generate each new
; world column exactly once; rendering and buffer flips never advance RNG.
initialise_obstacles:
    lda #PIPE_RANDOM_SEED
    sta PIPE_RANDOM_STATE
    lda #PIPE_FIRST_COLUMN
    sta PIPE_DISTANCE
    lda #PIPE_START_GAP
    sta PIPE_CURRENT_GAP
    lda #1
    sta PIPE_FIRST
    lda #0
    sta PIPE_REMAINING
    sta PIPE_WRITE_INDEX
initial_obstacle_columns:
    jsr generate_obstacle_column
    lda PIPE_WRITE_INDEX
    cmp #SCREEN_COLUMNS
    bcc initial_obstacle_columns
    rts

generate_obstacle_column:
    lda PIPE_DISTANCE
    beq obstacle_pipe_column
    dec PIPE_DISTANCE
    lda #0
    jmp store_obstacle_column
obstacle_pipe_column:
    lda PIPE_REMAINING
    bne continue_pipe
    lda PIPE_FIRST
    beq randomise_gap
    dec PIPE_FIRST
    jmp start_pipe
randomise_gap:
    ; Maximal-length nonzero 8-bit LFSR; fixed seed makes restarts repeatable.
    lda PIPE_RANDOM_STATE
    asl
    bcc random_gap_ready
    eor #PIPE_LFSR_FEEDBACK
random_gap_ready:
    sta PIPE_RANDOM_STATE
    and #PIPE_GAP_STEP_MASK
    tax
    lda PIPE_CURRENT_GAP
    clc
    adc gap_steps,x
    cmp #PIPE_GAP_MIN
    bcs gap_above_minimum
    lda #PIPE_GAP_MIN
gap_above_minimum:
    cmp #PIPE_GAP_MAX + 1
    bcc store_new_gap
    lda #PIPE_GAP_MAX
store_new_gap:
    sta PIPE_CURRENT_GAP
start_pipe:
    lda #PIPE_WIDTH_COLUMNS
    sta PIPE_REMAINING
continue_pipe:
    dec PIPE_REMAINING
    bne pipe_not_finished
    lda #PIPE_SPACING_COLUMNS - PIPE_WIDTH_COLUMNS
    sta PIPE_DISTANCE
pipe_not_finished:
    lda PIPE_CURRENT_GAP
store_obstacle_column:
    ldx PIPE_WRITE_INDEX
    sta OBSTACLE_BUFFER_RAM,x
    inx
    txa
    and #PIPE_RING_MASK
    sta PIPE_WRITE_INDEX
    rts

gap_steps:
    !byte (0 - PIPE_GAP_MAX_STEP) & $ff, $ff, 1, PIPE_GAP_MAX_STEP
