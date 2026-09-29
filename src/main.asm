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
    cli

main_loop:
    jsr wait_for_frame
    jsr advance_scroll
    jmp main_loop

!source "src/video.asm"
!source "src/render.asm"

* = CHARSET_RAM
!fill 8, 0
; Glyph 1 is a pipe body, glyph 2 its cap, and glyph 3 the ground.
!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
!byte $7e, $ff, $ff, $ff, $ff, $ff, $ff, $7e
!byte $aa, $55, $aa, $55, $aa, $55, $aa, $55
!fill CHARSET_SIZE - 32, 0
