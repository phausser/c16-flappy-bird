!source "src/hardware.inc"
!source "src/memory.inc"
!source "src/constants.inc"

* = PROGRAM_START
!word basic_end
!word 10
!byte $9e
!text "4109"
!byte 0
basic_end:
!word 0

* = CODE_START

; IRQ stays masked during setup. The raster gradient later installs its
; handler through the hardware IRQ vector; that handler touches only TED color
; and compare registers plus its dedicated gradient state.
start:
    sei
    jsr initialise_input
restart_round:
    sei
    lda #0
    sta GAME_OVER
    jsr initialise_video
    jsr initialise_obstacles
    jsr render_playfield
    ; The hidden buffer must already match the playfield before the bird is
    ; painted, so a later flip never reveals a second bird.
    jsr mirror_playfield_to_back
    jsr prime_back_buffer
    jsr initialise_bird
    jsr initialise_background_gradient

main_loop:
    jsr read_input
    lda GAME_OVER
    beq play_frame
    lda FLAP_PRESSED
    bne restart_round
    jsr wait_for_frame
    jmp main_loop
play_frame:
    jsr prepare_bird_frame
    ; All trial positions are resolved before the border. Only the accepted
    ; frame changes live glyphs, screen RAM and TED registers.
    jsr wait_for_frame
    jsr clear_bird
    lda SCROLL_PENDING
    beq draw_accepted_bird
    jsr advance_scroll
draw_accepted_bird:
    jsr render_bird
    jmp main_loop

!source "src/collision.asm"
!source "src/video.asm"
!source "src/gradient.asm"
!source "src/obstacles.asm"
!source "src/render.asm"
!source "src/bird.asm"
!source "src/input.asm"

; The hidden text buffer starts at $1800. A program that grows into it would
; be overwritten by the first mirror copy.
!if * > BACK_COLOR_RAM {
    !error "program overlaps the hidden text buffer"
}

; Static animation masks live in otherwise unused RAM; the executable code
; itself must stay below the hidden screen buffers.
* = $2000
!source "src/bird_masks.inc"

* = CHARSET_RAM
!fill 8, 0
; Glyphs 1-3 form the playfield. Glyphs 4-15 are the dynamic bird area
; (four columns, each with three rows). Only accepted candidate
; glyphs are copied here; collision probes never modify the live charset.
!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
!byte $7e, $ff, $ff, $ff, $ff, $ff, $ff, $7e
!byte $aa, $55, $aa, $55, $aa, $55, $aa, $55
!fill BIRD_GLYPH_BYTES, 0
!fill CHARSET_SIZE - 32 - BIRD_GLYPH_BYTES, 0
