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
; and compare registers, HUD scroll and its dedicated gradient state.
start:
    sei
    jsr initialise_input
    lda #0
    sta HIGH_SCORE
    sta HIGH_SCORE + 1
    lda #GAME_STATE_WAITING
    bne initialise_round
restart_round:
    sei
    lda #0
initialise_round:
    sta GAME_OVER
    lda #0
    sta SCORE
    sta SCORE + 1
    sta HUD_BLINK
    sta HUD_TIMER
    sta HUD_DIRTY
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
    ; The floor IRQ leaves $FF07 at scroll 0. Restore the frozen playfield
    ; scroll or the next frame would be stuck there, score row included.
    jsr wait_for_frame
    jsr commit_scroll_offset
    jsr update_footer_blink
    jmp main_loop
play_frame:
    jsr prepare_bird_frame
    lda GAME_OVER
    beq footer_ready
    jsr render_score
footer_ready:
    ; All trial positions are resolved before the border. Only the accepted
    ; frame changes live glyphs, screen RAM and TED registers.
    jsr wait_for_frame
    jsr clear_bird
    lda SCROLL_PENDING
    beq hold_scroll
    jsr advance_scroll
    jmp draw_accepted_bird
hold_scroll:
    jsr commit_scroll_offset
draw_accepted_bird:
    jsr render_bird
    jsr refresh_footer
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

; HUD code and the bird-color helper live above the hidden text buffer.
; Imported masks follow; all stay below the game-state RAM.
* = SCORE_CODE_START
!source "src/score.asm"
!source "src/bird_masks.inc"
!if * > GAME_STATE_RAM {
    !error "score code overlaps game state"
}

!source "src/font.inc"
