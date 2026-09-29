initialise_input:
    lda #0
    sta FLAP_HELD
    sta FLAP_PRESSED
    rts

; SPACE is row 7, column 4 in the C16 keyboard matrix. A new press produces
; exactly one frame of FLAP_PRESSED; holding the key does not retrigger it.
read_input:
    lda #0
    sta FLAP_PRESSED
    lda #$ef
    sta TED_KEYBOARD
    lda TED_KEYBOARD
    and #$80
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
