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

	.global _mul
_mul:
	mul $t0, $t1, $t2
        muh $t0, $t1, $t2
        mulu $t0, $t1, $t2
        muhu $t0, $t1, $t2
        dmul $t0, $t1, $t2
        dmuh $t0, $t1, $t2
        dmulu $t0, $t1, $t2
        dmuhu $t0, $t1, $t2

	.global _scd
_scd:
	scd $t4, 8($t5)
	#scdp $t0, $t1, $t3
	.byte 0x67, 0x58, 0x09, 0x7d

	.global _data
	.data
	.align 8
_data:
	.word 0
	.word 0
	.word 0
	.word 0

