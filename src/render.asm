render_playfield:
    ldx #0
render_initial_column:
    jsr render_world_column
    inx
    cpx #SCREEN_COLUMNS
    bcc render_initial_column
    rts

; X is the screen column to write. WORLD_COLUMN identifies its leftmost
; logical world column, so the same deterministic pipe pattern is used when
; a new right-edge column is prepared.
render_world_column:
    lda #GLYPH_SKY
    ldy #0
clear_sky:
    sta SCREEN_RAM + (0 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (1 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (2 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (3 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (4 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (5 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (6 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (7 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (8 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (9 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (10 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (11 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (12 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (13 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (14 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (15 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (16 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (17 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (18 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (19 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (20 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (21 * SCREEN_COLUMNS),x
    lda #TED_LIGHT_BLUE
    sta COLOR_RAM + (0 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (1 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (2 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (3 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (4 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (5 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (6 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (7 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (8 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (9 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (10 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (11 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (12 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (13 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (14 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (15 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (16 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (17 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (18 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (19 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (20 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (21 * SCREEN_COLUMNS),x

    lda #GLYPH_GROUND
    sta SCREEN_RAM + (22 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (23 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (24 * SCREEN_COLUMNS),x
    lda #TED_YELLOW
    sta COLOR_RAM + (22 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (23 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (24 * SCREEN_COLUMNS),x

    txa
    clc
    adc WORLD_COLUMN
    and #PIPE_PATTERN_MASK
    cmp #PIPE_PATTERN_START
    bcc no_pipe
    cmp #PIPE_PATTERN_END
    bcs no_pipe

    lda #GLYPH_PIPE_BODY
    sta SCREEN_RAM + (1 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (2 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (3 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (4 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (5 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (17 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (18 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (19 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (20 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (21 * SCREEN_COLUMNS),x
    lda #GLYPH_PIPE_CAP
    sta SCREEN_RAM + (6 * SCREEN_COLUMNS),x
    sta SCREEN_RAM + (16 * SCREEN_COLUMNS),x
    lda #TED_GREEN
    sta COLOR_RAM + (1 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (2 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (3 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (4 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (5 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (6 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (16 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (17 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (18 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (19 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (20 * SCREEN_COLUMNS),x
    sta COLOR_RAM + (21 * SCREEN_COLUMNS),x
no_pipe:
    rts
