initialise_input:
    lda #0
    sta FLAP_HELD
    sta FLAP_PRESSED
    rts

; SPACE is row 7, column 4 of the C16 matrix (same map the KERNAL scans).
; The row is driven by the 6529 at $FD30, active low; writing $FF08 only
; latches whatever row $FD30 is already driving. A new press produces
; exactly one frame of FLAP_PRESSED; holding the key does not retrigger it.
read_input:
    lda #0
    sta FLAP_PRESSED
    lda #$7f
    sta TED_KEYBOARD_ROW
    sta TED_KEYBOARD
    lda TED_KEYBOARD
    and #$10
    bne flap_released

    lda FLAP_HELD
    bne input_done
    lda #1
    sta FLAP_HELD
    sta FLAP_PRESSED
    rts

flap_released:
    lda #0
    sta FLAP_HELD
input_done:
    rts
