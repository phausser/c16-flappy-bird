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
    lda #0
    sta HIGH_SCORE
    sta HIGH_SCORE + 1
restart_round:
    sei
    lda #0
    sta GAME_OVER
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

; Score drawing lives above the hidden text buffer. The imported masks follow
; it; both stay below the game-state RAM at $3000.
* = $2000
!source "src/score.asm"
!source "src/bird_masks.inc"
!if * > GAME_STATE_RAM {
    !error "score code overlaps game state"
}

* = CHARSET_RAM
!fill 8, 0
; Glyphs 1-3 form the left/middle/right pipe strips from assets/pipe.png.
; Glyphs 4-15 are the dynamic hires bird area
; (four columns, each with three rows). Only accepted candidate
; glyphs are copied here; collision probes never modify the live charset.
; Two-bit pixels: green/yellow/green/yellow, yellow/green/green/green,
; dark/green/dark/dark. Repeat vertically between the end caps.
!fill 8, %11011101
!fill 8, %01111111
!fill 8, %10111010
!fill BIRD_GLYPH_BYTES, 0
; Glyphs 16-25. The ink sits in the lower five pixels, with two-pixel
; strokes and square corners. Bit 7 is the leftmost pixel.
digit_glyphs:
    !byte %00000000, %00000000, %00000000, %01111110, %01100110, %01100110, %01100110, %01111110
    !byte %00000000, %00000000, %00000000, %00011000, %00011000, %00011000, %00011000, %00011000
    !byte %00000000, %00000000, %00000000, %01111110, %00000110, %01111110, %01100000, %01111110
    !byte %00000000, %00000000, %00000000, %01111110, %00000110, %01111110, %00000110, %01111110
    !byte %00000000, %00000000, %00000000, %01100110, %01100110, %01111110, %00000110, %00000110
    !byte %00000000, %00000000, %00000000, %01111110, %01100000, %01111110, %00000110, %01111110
    !byte %00000000, %00000000, %00000000, %01111110, %01100000, %01111110, %01100110, %01111110
    !byte %00000000, %00000000, %00000000, %01111110, %00000110, %00000110, %00000110, %00000110
    !byte %00000000, %00000000, %00000000, %01111110, %01100110, %01111110, %01100110, %01111110
    !byte %00000000, %00000000, %00000000, %01111110, %01100110, %01111110, %00000110, %01111110
!if digit_glyphs <> CHARSET_RAM + GLYPH_DIGIT_0 * 8 {
    !error "score digits must follow the bird glyphs"
}
!if * - digit_glyphs <> 80 {
    !error "score digits must be ten glyphs"
}
; Top eight pixels of assets/pipe.png. The cap is vertically symmetric,
; so the same three glyphs close both pipes next to the gap.
!if * <> CHARSET_RAM + GLYPH_PIPE_CAP_LEFT * 8 {
    !error "pipe caps must follow the score digits"
}
    !byte $bb, $dd, $dd, $dd, $dd, $dd, $dd, $bb
    !byte $ea, $7f, $7f, $7f, $7f, $7f, $7f, $ea
    !byte $aa, $ba, $ba, $ba, $ba, $ba, $ba, $aa
; A-Z: five-pixel-high lettering with the digits' two-pixel strokes.
    !byte $00, $00, $00, $18, $66, $7e, $66, $66 ; A
    !byte $00, $00, $00, $78, $66, $78, $66, $78 ; B
    !byte $00, $00, $00, $1e, $60, $60, $60, $1e ; C
    !byte $00, $00, $00, $78, $66, $66, $66, $78 ; D
    !byte $00, $00, $00, $7e, $60, $78, $60, $7e ; E
    !byte $00, $00, $00, $7e, $60, $78, $60, $60 ; F
    !byte $00, $00, $00, $1e, $60, $66, $66, $1e ; G
    !byte $00, $00, $00, $66, $66, $7e, $66, $66 ; H
    !byte $00, $00, $00, $7e, $18, $18, $18, $7e ; I
    !byte $00, $00, $00, $06, $06, $06, $66, $18 ; J
    !byte $00, $00, $00, $66, $66, $78, $66, $66 ; K
    !byte $00, $00, $00, $60, $60, $60, $60, $7e ; L
    !byte $00, $00, $00, $66, $7e, $7e, $66, $66 ; M
    !byte $00, $00, $00, $66, $7e, $7e, $7e, $66 ; N
    !byte $00, $00, $00, $18, $66, $66, $66, $18 ; O
    !byte $00, $00, $00, $78, $66, $78, $60, $60 ; P
    !byte $00, $00, $00, $18, $66, $66, $7e, $1e ; Q
    !byte $00, $00, $00, $78, $66, $78, $66, $66 ; R
    !byte $00, $00, $00, $1e, $60, $18, $06, $78 ; S
    !byte $00, $00, $00, $7e, $18, $18, $18, $18 ; T
    !byte $00, $00, $00, $66, $66, $66, $66, $7e ; U
    !byte $00, $00, $00, $66, $66, $66, $66, $18 ; V
    !byte $00, $00, $00, $66, $66, $7e, $7e, $66 ; W
    !byte $00, $00, $00, $66, $66, $18, $66, $66 ; X
    !byte $00, $00, $00, $66, $66, $18, $18, $18 ; Y
    !byte $00, $00, $00, $7e, $06, $18, $60, $7e ; Z
!fill CHARSET_SIZE - (* - CHARSET_RAM), 0
