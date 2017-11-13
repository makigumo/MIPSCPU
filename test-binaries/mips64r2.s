#
# compile with: $ mips-elf-as -EL -mips64r2  %s.s -o %s.o
#
#

	.global _start
	.text
_start:
	li $t0,1
	dli $t1,2
	b 0
	nop
	.global label
label:
	break
	break 32
	dext $t0, $t2, 0, 2
	dext $t0, $t2, 0, 32
	dext $t0, $t2, 31, 12
	dextm $t0, $t2, 0, 62
	dext $t0, $t2, 45, 12
	dextu $t0, $t2, 45, 12
	.global _dins
_dins:
	dins $t0, $t1, 2, 1
	dins $t0, $t1, 21, 16
	dinsm $t0, $t1, 21, 16
	dins $t0, $t2, 45, 12
	dinsu $t0, $t2, 45, 12
	.global _drotr
_drotr:
	drotr $t0, $t2, 16
	drotr32 $t0, $t2, 16
	drotrv $t0, $t2, $t4
	dsbh $t0, $t4
	dshd $t0, $t4

