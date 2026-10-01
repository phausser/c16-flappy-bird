; TED (MOS 7360/8360) registers used by the PAL C16 build.

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
