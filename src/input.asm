initialise_input:
    lda #0
    sta FLAP_HELD
    sta FLAP_PRESSED
    rts

; SPACE is row 7, column 4 of the C16 matrix (same map the KERNAL scans).
; The row is driven by the 6529 at $FD30, active low; writing $FF08 only
; latches whatever row $FD30 is already driving. A new press produces
; exactly one frame of FLAP_PRESSED; holding the key does not retrigger it.
; A press during play requests the flap sound. Every call then advances
; the sound by one frame; the main loop calls this once per frame. Outside
; play, a press only counts once no sound is playing.
read_input:
    lda #0
    sta FLAP_PRESSED
    lda #SPACE_KEY_ROW_MASK
    sta TED_KEYBOARD_ROW
    sta TED_KEYBOARD
    lda TED_KEYBOARD
    and #SPACE_KEY_COLUMN_MASK
    bne flap_released

    lda FLAP_HELD
    bne input_done
    lda #1
    sta FLAP_HELD
    sta FLAP_PRESSED
    lda GAME_OVER
    bne input_done
    lda #SOUND_FLAP
    sta SOUND_REQUEST
    jmp sound_tick

flap_released:
    lda #0
    sta FLAP_HELD
input_done:
    jsr sound_tick
    ; After a crash the sound plays out first: a press during it does not
    ; restart, and a fresh press is needed afterwards.
    lda sound_delay
    beq input_ready
    lda #0
    sta FLAP_PRESSED
input_ready:
    rts
