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
TED_COLOR_BG = $ff15
TED_BORDER_COLOR = $ff19
TED_RASTER_LO = $ff1d

; Bits 0-2 = vertical scroll 3. Scroll 0 shifts the matrix up and opens
; three scanlines under the ground; the TED paints the bytes past the
; screen matrix there (a light bar, and on some offsets a black block).
; Bit 3 = 25 rows. Bit 4 = display on.
TED_CONTROL1_TEXT_25_ROWS = $1b
; Bit 3 = 40 columns. Bit 7 stays clear: set, it switches the TED into
; 256-character mode and the chargen base then moves in 2 KiB steps, so
; $3400 cannot be addressed and $0D aliases onto colour RAM at $0800.
TED_CONTROL2_TEXT_40_COLS = $08

TED_BLACK = $00
TED_GREEN = $57
TED_BLUE = $67
TED_LIGHT_BLUE = $e7
TED_YELLOW = $77

TED_SKY_COLOR = TED_LIGHT_BLUE
TED_PIPE_COLOR = TED_GREEN
TED_GROUND_COLOR = TED_YELLOW

; Black gives the bird the strongest contrast against sky, ground and pipes
; alike, so it stays visible airborne, resting on the ground clamp, or
; passing in front of a pipe.
TED_BIRD_COLOR = TED_BLACK
