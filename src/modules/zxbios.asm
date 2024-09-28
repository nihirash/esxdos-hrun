; A - char
putC:
    rst #10
    ret

; HL - string
putStringZ:
    ld a, (hl)
    and a
    ret z
    push hl
    call putC
    pop hl
    inc hl
    jr putStringZ

; B - len
; HL - pointer
printLen:
    push bc
    ld a, (hl)
    push hl
    call putC
    pop hl
    inc hl
    pop bc
    djnz printLen
    ret

    macro print pointer
    ld hl, pointer : call putStringZ
    endm