    device zxspectrum48
    org #2000
    jp _start
    include "modules/version.asm"
ver:
    db "Hobeta run "
    db VERSION_STRING
    db 13
    db "By Alex Nihirash", 13, 0

    include "modules/args.asm"
    include "modules/esxdos.asm"
    include "modules/zxbios.asm"

_start:
    push hl
    print ver
    pop hl

    ld a, l : or h : jp z, noArgs
    ld a, (hl) : or a : jp z, noArgs

    ld de, filename, b, 80
    call Args.parseOne

    print .msg_trying_open
    print filename
    print .newline

    ld hl, filename, b, Dos.FMODE_READ
    call Dos.fopen
    or a : jp z, cantOpen

    ld (.file_handle), a

    ld hl, header, bc, header.struct_len
    call Dos.fread

    print .internal_file_name
    ld hl, header, b, 8 : call printLen
    ld a, ' ' : call putC
    ld a, '<' : call putC
    ld a, (header.ext) : call putC
    ld a, '>' : call putC
    print .newline

    ld hl, (header.start), bc, (header.len),  a, (.file_handle)
    call Dos.fread

    ld a, (.file_handle)
    call Dos.fclose

    ld hl, (header.start)
    jp (hl)

.file_handle:
    db 0
.newline:
    db 13, 0
.msg_trying_open:
    db 13, "Trying open: ", 0
.internal_file_name:
    db "Internal name: ", 0

cantOpen:
    print .msg
    ret
.msg:
    db "Can't open file!", 13, 0

noArgs:
    print .msg
    ret
.msg:
    db "Usage", 13
    db ".hrun filename.$c",13,0
filename:
    ds 80

    db "HEADER WILL BE HERE:"    
    SAVEBIN "hrun", #2000, $ - #2000

header:
.name:
    ds 8 ;; Filename
.ext:
    ds 1 ;; Ext
.start:
    dw 0
.len:
    dw 0
.secs:
    dw 0
.crc:
    dw 0
.struct_len = $ - header