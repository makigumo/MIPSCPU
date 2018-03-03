#
# compile with: $ mips-elf-as -EL -mips64r6  %s.s -o %s.o
#
#

        .global _start
        .text
_start:
	daui $t0, $t2, 0x400
	dahi $t0, $t0, 0x400
	dati $t0, $t0, 0x80
	dclo $t0, $t2

	nop
	ldpc $t0, 8
	ldpc $t2, -24
	lld $t2, 24($t4)
	#lldp $t2, $t4, ($t6)
	.byte 0x77,0x48,0x88,0x7e
	nop
	lwupc $t0, _data + 8
	lwupc $t0, 48

	.global _data
	.data
	.align 8
_data:
	.word 0
	.word 0
	.word 0
	.word 0

