; (c) 2024 Aleksandr Sharikhin
; This plugin licensed by GNU GPL
;
; Based on .mid plugin by Bob Fossil
;
;******************************************************************************
;*
;* Copyright(c) 2020 Bob Fossil. All rights reserved.
;*                                        
;* This program is free software; you can redistribute it and/or modify it
;* under the terms of version 2 of the GNU General Public License as
;* published by the Free Software Foundation.
;*
;* This program is distributed in the hope that it will be useful, but WITHOUT
;* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
;* more details.
;*
;* You should have received a copy of the GNU General Public License along with
;* this program; if not, write to the Free Software Foundation, Inc.,
;* 51 Franklin Street, Fifth Floor, Boston, MA 02110, USA
;*
;*
;******************************************************************************/

	include "plugin.asm"
	include "esxdos.asm"
	output "$c"
hrun_DEST = 23512		; address used by NMI.SYS

	org PLUGIN_ORG

	jr _plugin_start

_plugin_info:

	defb "BP"			; id
	defb 0				; spare
	defb 0				; spare
					; flags
	defb PLUGIN_FLAGS1_MMC_ONLY
	defb 0				; flags2
	defb ".C file plugin - nihirash", $0

_plugin_start:

					; filename in hl
	push hl

	inc bc
	ld a, (bc)			; are we running from NMI?
	and a

	ld a, 2

	jr z, _plugin_not_nmi
	xor a

_plugin_not_nmi:

	ld (_plugin_hob_page_restore + 1), a
	ld (_plugin_hob_page_restore2 + 1), a


	ld hl, _hrun_command 	; append 'snapload '
	ld de, hrun_DEST
	ld bc, _hrun_command_end - _hrun_command
	ldir
	
	pop hl

_plugin_hob_copy:

	ld a, (hl)			; append filename
	ld (de), a
	inc hl
	inc de
	and a
	jr nz, _plugin_hob_copy

	dec de				; stick a $d on the end to keep
	ld a, $d			; the .playmid command line parser happy
	ld (de), a

					; backup 8k at 24576 and 8k at 40960
	ld a, MMC_MEMORY_PLUGIN_PAGE2 + 128
	out (MMC_MEMORY_PORT), a

	ld hl, 40960			; backup existing memory at 40960
	ld bc, DIV_MMC_BANK_SIZE
	ld de, 8192

	ldir

	ld a, MMC_MEMORY_PLUGIN_PAGE3 + 128
	out (MMC_MEMORY_PORT), a

	ld hl, 24576
	ld bc, DIV_MMC_BANK_SIZE
	ld de, 8192

	ldir

_plugin_hob_page_restore:

	ld a, 0
	add a, 128
	out (MMC_MEMORY_PORT), a

	ld (_plugin_hob_sp + 1), sp

	ld hl, _plugin_hob_screen_player
	ld de, 16384
	ld bc, _plugin_hob_screen_player_end - _plugin_hob_screen_player
	ldir
	
	jp 16384
	
_plugin_hob_screen_player:

	ld sp, $ff40			;16384 + 512
	ei

	ld hl, hrun_DEST		; hl points to command string

	rst ESXDOS_SYS_CALL		; undocumented hook code to execute a command?
	defb $8f			; adc a, a

					; restore memory banks before we exit
	ld a, MMC_MEMORY_PLUGIN_PAGE2 + 128
	out (MMC_MEMORY_PORT), a

	ld de, 40960
	ld bc, DIV_MMC_BANK_SIZE
	ld hl, 8192

	ldir

	ld a, MMC_MEMORY_PLUGIN_PAGE3 + 128
	out (MMC_MEMORY_PORT), a

	ld de, 24576
	ld bc, DIV_MMC_BANK_SIZE
	ld hl, 8192

	ldir

_plugin_hob_page_restore2:

	ld a, 0				; 0 -nmi, 2 - .dot
	add a, 128
	out (MMC_MEMORY_PORT), a

_plugin_hob_sp:

	ld sp, 00000			; restore the old stack

	ld a, PLUGIN_OK|PLUGIN_RESTORE_SCREEN|PLUGIN_RESTORE_BUFFERS
	ret

_plugin_hob_screen_player_end:

_hrun_command:
	defb "hrun "

_hrun_command_end:

; 20b4 ret out of .playmid
; 2939 code that writes over the stack
