; Three PAL one-shot effects, trimmed from c16-sound-fx
; (https://github.com/phausser/c16-sound-fx): 72 flap-double, 50 im-robot
; and 79 life-wobble. One effect plays at a time; a new one replaces it.
;
; Triggers only store SOUND_REQUEST, so callers in the border (the pipe
; point inside swap_buffers) stay on schedule. sound_tick runs once per
; main-loop frame, before wait_for_frame, starts a pending request and
; otherwise advances the current effect by one PAL frame.
;
; Step: frames, tone 1 low/high, tone 2/noise low/high, $FF11 control.
; A zero frame count ends the effect. Bits 2-7 of $FF12 and $FF10 belong
; to the video setup and are preserved.

!macro sound_step .frames, .hz1, .hz2, .control {
    .n1 = 1024 - (TED_PAL_SOUND_CLOCK + .hz1 / 2) / .hz1
    .n2 = 1024 - (TED_PAL_SOUND_CLOCK + .hz2 / 2) / .hz2
    !byte .frames, <.n1, >.n1, <.n2, >.n2, .control
}

; Silence and forget any request. Called at every round start.
sound_silence:
    lda #0
    sta TED_SOUND_CTRL
    sta SOUND_REQUEST
    sta sound_delay
    rts

sound_tick:
    ldx SOUND_REQUEST
    beq sound_advance
    lda #0
    sta SOUND_REQUEST
    lda sound_start_lo - 1,x
    sta sound_read + 1
    lda sound_start_hi - 1,x
    sta sound_read + 2
    jmp sound_step
sound_advance:
    lda sound_delay
    beq sound_done
    dec sound_delay
    bne sound_done
sound_step:
    ldx #0
    jsr sound_read
    sta sound_delay
    beq sound_off
    inx
    jsr sound_read
    sta TED_FREQ1_LO
    inx
    jsr sound_read
    sta sound_high
    lda TED_MISC
    and #$fc
    ora sound_high
    sta TED_MISC
    inx
    jsr sound_read
    sta TED_FREQ2_LO
    inx
    jsr sound_read
    sta sound_high
    lda TED_FREQ2_HI
    and #$fc
    ora sound_high
    sta TED_FREQ2_HI
    inx
    jsr sound_read
    sta TED_SOUND_CTRL
    lda sound_read + 1
    clc
    adc #6
    sta sound_read + 1
    bcc sound_done
    inc sound_read + 2
sound_done:
    rts
sound_off:
    sta TED_SOUND_CTRL
    rts

; Self-modified operand: the current step of the playing effect.
sound_read:
    lda sound_flap,x
    rts

sound_delay:
    !byte 0
sound_high:
    !byte 0

; Indexed by SOUND_FLAP, SOUND_POINT and SOUND_DEATH (1-3).
sound_start_lo:
    !byte <sound_flap, <sound_point, <sound_death
sound_start_hi:
    !byte >sound_flap, >sound_point, >sound_death

; 72 flap-double: two noise wing beats. The library's trailing six-frame
; rest only spaces its loop and is left out.
sound_flap:
    +sound_step 1, 110, 2000, $43
    +sound_step 2, 110, 1200, $42
    +sound_step 2, 110, 110, $00
    +sound_step 1, 110, 1700, $44
    +sound_step 2, 110, 850, $42
    +sound_step 2, 110, 450, $41
    !byte 0

; 50 im-robot, falling tone. Volumes lowered from 6/6/5/5/4/2.
sound_point:
    +sound_step 1, 2100, 110, $14
    +sound_step 1, 1700, 110, $14
    +sound_step 1, 1300, 110, $13
    +sound_step 1, 950, 110, $13
    +sound_step 1, 700, 110, $12
    +sound_step 2, 450, 110, $11
    !byte 0

; 79 life-wobble, two detuned tones sinking.
sound_death:
    +sound_step 3, 330, 345, $34
    +sound_step 3, 294, 308, $33
    +sound_step 3, 311, 326, $33
    +sound_step 4, 247, 260, $32
    +sound_step 4, 262, 275, $32
    +sound_step 7, 165, 174, $31
    !byte 0
