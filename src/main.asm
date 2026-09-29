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

start:
    sei
    jsr initialise_video
    jsr render_playfield
    jsr initialise_bird
    cli

main_loop:
    jsr wait_for_frame
    jsr clear_bird
    jsr advance_scroll
    jsr render_bird
    jmp main_loop

!source "src/video.asm"
!source "src/render.asm"
!source "src/bird.asm"

* = CHARSET_RAM
!fill 8, 0
; Glyphs 1-3 form the playfield; glyphs 4-7 are the dynamic bird.
!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
!byte $7e, $ff, $ff, $ff, $ff, $ff, $ff, $7e
!byte $aa, $55, $aa, $55, $aa, $55, $aa, $55
!byte $00, $00, $03, $0f, $1f, $3f, $3f, $3f
!byte $00, $00, $c0, $f0, $f8, $fc, $fc, $fc
!byte $3f, $3f, $1f, $0f, $03, $00, $00, $00
!byte $fc, $fc, $f8, $f0, $c0, $00, $00, $00
!fill CHARSET_SIZE - 64, 0
