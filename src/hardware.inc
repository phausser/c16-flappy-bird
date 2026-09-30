; TED (MOS 7360/8360) registers used by the initial PAL C16 build.

TED_CONTROL1 = $ff06
TED_CONTROL2 = $ff07
TED_KEYBOARD = $ff08
; 6529 single-port interface. A 0 bit selects that keyboard row. The column
; latch itself is TED_KEYBOARD: write the same mask there, then read it back.
TED_KEYBOARD_ROW = $fd30
TED_SOUND_CTRL = $ff11
TED_MISC = $ff12
TED_CHAR_ADDR = $ff13
TED_VIDEO_ADDR = $ff14
TED_IRQ_STATUS = $ff09
TED_IRQ_ENABLE = $ff0a
TED_RASTER_COMPARE = $ff0b
TED_COLOR_BG = $ff15
TED_COLOR_MC1 = $ff16
TED_COLOR_MC2 = $ff17
TED_BORDER_COLOR = $ff19
TED_RASTER_LO = $ff1d
TED_RASTER_HORIZONTAL = $ff1e
TED_RAM_ENABLE = $ff3f
HARDWARE_IRQ_VECTOR = $fffe

; Bits 0-2 = vertical scroll 3. Scroll 0 shifts the matrix up and opens
; three scanlines below the playfield; the TED paints the bytes past the
; screen matrix there (a light bar, and on some offsets a black block).
; Bit 3 = 25 rows. Bit 4 = display on.
TED_CONTROL1_TEXT_25_ROWS = $1b
; Bit 3 clear = 38 columns. The border then covers eight pixels on each
; side, which is where a horizontal scroll would otherwise show the partial
; column. The screen matrix stays 40 bytes wide; columns 0 and 39 are the
; hidden guards. Bit 7 stays clear: set, it switches the TED into
; 256-character mode and the chargen base then moves in 2 KiB steps, so
; $3400 cannot be addressed and $0D aliases onto colour RAM at $0800.
; Bit 4 enables mixed multicolor text. Color-RAM bit 3 selects each cell.
TED_CONTROL2_TEXT_38_COLS = $10

TED_BLACK = $00
TED_GREEN = $57
TED_BLUE = $6d
TED_LIGHT_BLUE = $e7
TED_YELLOW = $77

TED_SKY_COLOR = TED_BLUE
; Pipe pairs: 01 = yellow highlight, 10 = dark green, 11 = green.
; Attribute bit 3 enables multicolor; the bird keeps it clear for hires.
TED_PIPE_HIGHLIGHT = $77
TED_PIPE_SHADOW = $25
TED_PIPE_COLOR = $55 | $08

; Black gives the bird the strongest contrast against sky and pipes
; alike, so it stays visible airborne, at the lower screen edge, or
; passing in front of a pipe.
TED_BIRD_COLOR = TED_BLACK
