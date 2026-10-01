; RAM character set. Each glyph has eight rows, bit 7 is the left pixel.
; Edit binary bytes directly; glyph order must match constants.inc.

* = CHARSET_RAM

; Sky / blank glyph 0
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
; Glyphs 1-3 form the left/middle/right pipe strips from assets/pipe.png.
; Glyphs 4-15 are the dynamic hires bird area
; (four columns, each with three rows). Only accepted candidate
; glyphs are copied here; collision probes never modify the live charset.
; Two-bit pixels select base/highlight/base/highlight,
; highlight/base/base/base, shadow/base/shadow/shadow. Palette values are
; configured in constants.inc; the body repeats between the end caps.

; Pipe body glyph 1 (left)
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101

; Pipe body glyph 2 (middle)
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111

; Pipe body glyph 3 (right)
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010

; Dynamic bird glyph 4 (column 0, row 0)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 5 (column 0, row 1)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 6 (column 0, row 2)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 7 (column 1, row 0)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 8 (column 1, row 1)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 9 (column 1, row 2)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 10 (column 2, row 0)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 11 (column 2, row 1)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 12 (column 2, row 2)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 13 (column 3, row 0)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 14 (column 3, row 1)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000

; Dynamic bird glyph 15 (column 3, row 2)
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000000
; Glyphs 16-25. The ink sits in the lower five pixels, with two-pixel
; strokes in the initial design. Bit 7 is the leftmost pixel.
digit_glyphs:

; Digit 0
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01111110

; Digit 1
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00111000
    !byte %00011000
    !byte %00011000
    !byte %00011000
    !byte %00011000

; Digit 2
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %00000110
    !byte %01111110
    !byte %01100000
    !byte %01111110

; Digit 3
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %00000110
    !byte %01111110
    !byte %00000110
    !byte %01111110

; Digit 4
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01111110
    !byte %00000110
    !byte %00000110

; Digit 5
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01111110
    !byte %00000110
    !byte %01111110

; Digit 6
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01111110
    !byte %01100110
    !byte %01111110

; Digit 7
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %00000110
    !byte %00000110
    !byte %00000110
    !byte %00000110

; Digit 8
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111110
    !byte %01100110
    !byte %01111110

; Digit 9
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111110
    !byte %00000110
    !byte %01111110
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

; Pipe cap (left)
    !byte %10111011
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %11011101
    !byte %10111011

; Pipe cap (middle)
    !byte %11101010
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %01111111
    !byte %11101010

; Pipe cap (right)
    !byte %10101010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10111010
    !byte %10101010
; A-Z: editable hires letters; eight binary rows per glyph.

; Letter A
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111110
    !byte %01100110
    !byte %01100110

; Letter B
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111100
    !byte %01100110
    !byte %01111110

; Letter C
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01100000
    !byte %01100000
    !byte %01111110

; Letter D
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111100
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01111100

; Letter E
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01111000
    !byte %01100000
    !byte %01111110

; Letter F
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01111000
    !byte %01100000
    !byte %01100000

; Letter G
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01100110
    !byte %01100110
    !byte %01111110

; Letter H
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01111110
    !byte %01100110
    !byte %01100110

; Letter I
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00111100
    !byte %00011000
    !byte %00011000
    !byte %00011000
    !byte %00111100

; Letter J
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %00000110
    !byte %00000110
    !byte %00000110
    !byte %01100110
    !byte %01111110

; Letter K
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01111100
    !byte %01100110
    !byte %01100110

; Letter L
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100000
    !byte %01100000
    !byte %01100000
    !byte %01100000
    !byte %01111110

; Letter M
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01111110
    !byte %01111110
    !byte %01100110
    !byte %01100110

; Letter N
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01100110

; Letter O
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01111110

; Letter P
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111110
    !byte %01100000
    !byte %01100000

; Letter Q
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01100110
    !byte %01111110
    !byte %00000111

; Letter R
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100110
    !byte %01111100
    !byte %01100110
    !byte %01100110

; Letter S
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %01100000
    !byte %01111110
    !byte %00000110
    !byte %01111110

; Letter T
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %00011000
    !byte %00011000
    !byte %00011000
    !byte %00011000

; Letter U
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %01111110

; Letter V
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01100110
    !byte %00111100
    !byte %00011000

; Letter W
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01111110
    !byte %01111110
    !byte %01100110

; Letter X
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %00111100
    !byte %01100110
    !byte %01100110

; Letter Y
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01100110
    !byte %01100110
    !byte %01111110
    !byte %00011000
    !byte %00011000

; Letter Z
    !byte %00000000
    !byte %00000000
    !byte %00000000
    !byte %01111110
    !byte %00000110
    !byte %01111110
    !byte %01100000
    !byte %01111110
!fill CHARSET_SIZE - (* - CHARSET_RAM), 0
