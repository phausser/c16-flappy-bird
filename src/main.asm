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

; Interrupts stay off for the whole run: frame sync is a raster poll and
; input is a direct matrix read, so nothing here needs the KERNAL's default
; IRQ. Leaving it enabled would let its jiffy-clock/keyboard-scan handler
; fire ~50x/sec against our own zero-page state and screen RAM at
; unpredictable points, which is a likely source of intermittent corruption.
start:
    sei
    jsr initialise_input
restart_round:
    lda #0
    sta GAME_OVER
    jsr initialise_video
    jsr render_playfield
    ; The hidden buffer must already match the playfield before the bird is
    ; painted, so a later flip never reveals a second bird.
    jsr mirror_playfield_to_back
    jsr prime_back_buffer
    jsr initialise_bird

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
!source "src/render.asm"
!source "src/bird.asm"
!source "src/input.asm"

; The hidden text buffer starts at $1800. A program that grows into it would
; be overwritten by the first mirror copy.
!if * > BACK_COLOR_RAM {
    !error "program overlaps the hidden text buffer"
}

* = CHARSET_RAM
!fill 8, 0
; Glyphs 1-3 form the playfield. Glyphs 4-12 are the dynamic bird area
; (left, right, tail columns, each with three rows). Only accepted candidate
; glyphs are copied here; collision probes never modify the live charset.
!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
!byte $7e, $ff, $ff, $ff, $ff, $ff, $ff, $7e
!byte $aa, $55, $aa, $55, $aa, $55, $aa, $55
!fill 72, 0
!fill CHARSET_SIZE - 104, 0
