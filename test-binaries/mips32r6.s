#
# compile with: $ mips-elf-as -EL -mips32r6 -meva  %s.s -o %s.o
#
#

        .global _start
        .text
_start:
	bgtz $zero, 0
	addiu $sp,$sp,-8
	nop
#	lapc $t0,data # alias for addiupc
	addiupc $t0,100
	align $t0,$t1,$t4,3
	aluipc $t0,data
	aluipc $t0,12
	aui $t0,$t1,data
	aui $t0,$t1,12
	aui $t0,$zero,data
	lui $t0,data
	.global auipc
auipc:
	auipc $t0,data
	auipc $t0,12
	balc auipc
	bc _start
	bc1eqz $f0,auipc
	nop
	bc1nez $f2,auipc
	nop
	bc2eqz $3,_start
	nop
	bc2nez $3,_start
	nop
	.global compact_branches
compact_branches:
	beqzalc $t0,compact_branches
	bgezalc $t0,_start
	bgtzalc $t0,_start
	blezalc $t0,auipc
	bltzalc $t0,auipc
	bnezalc $t0,compact_branches
	bnezalc $t0,-24
	.global compare_and_branch
compare_and_branch:
	blezc $t0,_start
	bgezc $t0,_start
	bltzc $t0,_start
	bgtzc $t0,_start
	.global compare_and_branch_2
compare_and_branch_2:
	bgec $t0,$t1,0
	bltc $t0,$t1,-4
	bgeuc $t0,$t1,-8
	bltuc $t0,$t1,-12
	beqc $t0,$t1,-16
	beqc $t1,$t0,-20
	bnec $t0,$t1,-24
	beqzc $t0,-28
	bnezc $t0,-32
	nop
	.global bitswap
bitswap:
	bitswap $t0,$t1
	bovc $t0,$t1,-4
	bnvc $t0,$t1,-8
	cache 3,45($t0)
	cachee 3,45($t0)
	ceil.l.s $f0,$f2
	ceil.w.s $f0,$f2
	class.s $f0,$f2
	class.d $f0,$f2
	clo $t0,$t1
	clz $t0,$t1
	.global cmp
cmp:
	cmp.af.s $f0,$f2,$f4
	cmp.af.d $f0,$f2,$f4
	cmp.un.s $f0,$f2,$f4
	cmp.un.d $f0,$f2,$f4
	cmp.eq.s $f0,$f2,$f4
	cmp.eq.d $f0,$f2,$f4
	cmp.ueq.s $f0,$f2,$f4
	cmp.ueq.d $f0,$f2,$f4
	cmp.lt.s $f0,$f2,$f4
	cmp.lt.s $f0,$f2,$f4
	cmp.ult.s $f0,$f2,$f4
        cmp.ult.d $f0,$f2,$f4
        cmp.le.s $f0,$f2,$f4
        cmp.le.d $f0,$f2,$f4
        cmp.ule.s $f0,$f2,$f4
        cmp.ule.d $f0,$f2,$f4
        cmp.saf.s $f0,$f2,$f4
        cmp.saf.d $f0,$f2,$f4
        cmp.sun.s $f0,$f2,$f4
        cmp.sun.d $f0,$f2,$f4
        cmp.seq.s $f0,$f2,$f4
        cmp.seq.d $f0,$f2,$f4
        cmp.sueq.s $f0,$f2,$f4
        cmp.sueq.d $f0,$f2,$f4
        cmp.slt.s $f0,$f2,$f4
        cmp.slt.s $f0,$f2,$f4
        cmp.sult.s $f0,$f2,$f4
        cmp.sult.d $f0,$f2,$f4
        cmp.sle.s $f0,$f2,$f4
        cmp.sle.d $f0,$f2,$f4
        cmp.sule.s $f0,$f2,$f4
        cmp.sule.d $f0,$f2,$f4
        cmp.or.s $f0,$f2,$f4
        cmp.or.d $f0,$f2,$f4
        cmp.une.s $f0,$f2,$f4
        cmp.une.d $f0,$f2,$f4
        cmp.ne.s $f0,$f2,$f4
        cmp.ne.d $f0,$f2,$f4
	cmp.sor.s $f0,$f2,$f4
	cmp.sor.d $f0,$f2,$f4
        cmp.sune.s $f0,$f2,$f4
        cmp.sune.d $f0,$f2,$f4
        cmp.sne.s $f0,$f2,$f4
        cmp.sne.d $f0,$f2,$f4

	.global div
div:
	div $t0,$t1,$t2
	mod $t0,$t1,$t2
	divu $t0,$t1,$t2
	modu $t0,$t1,$t2
	dvp $t0
	evp $t0
	
	.global jalr
jalr:
	jalr $t0
	jalr $t0,$t1
	jalr.hb $t0
	jalr.hb $t0,$t1
	jialc $t0,-32
	jic $t0,-32
	jr $ra
	jr $t0
	jr.hb $ra
	jr.hb $t0
	ldc2 $12,-32($t0)
	ll $t0, -32($t1)
#	llwp $t0,$t1,($t2)
	.byte 0x76,0x48,0x88,0x7e
#       llwpe $t0,$t1,($t2)
        .byte 0x6e,0x48,0x88,0x7e
	lsa $t0,$t1,$t2,3
	lui $t0,128
	lwc2 $12,-32($t0)
	lwpc $t0,jalr
	lwpc $t0,-8

	.global maddf
maddf:
	maddf.s $f0,$f2,$f4
	maddf.d $f0,$f2,$f4
	msubf.s $f0,$f2,$f4
	msubf.d $f0,$f2,$f4

	.global max_min
max_min:
	max.s $f0,$f2,$f4
	max.d $f0,$f2,$f4
        maxa.s $f0,$f2,$f4
        maxa.d $f0,$f2,$f4
        min.s $f0,$f2,$f4
        min.d $f0,$f2,$f4
        mina.s $f0,$f2,$f4
        mina.d $f0,$f2,$f4

	.global mul
mul:
	mul $t0,$t2,$t4
	muh $t0,$t2,$t4
        mulu $t0,$t2,$t4
        muhu $t0,$t2,$t4

	.global pref
pref:
	pref 1, 8($s0)

	.global rint
rint:
	rint.s $f0,$f2
	rint.d $f0,$f2

	.global sc
sc:
	sc $t0,8($s1)
#	scwp $t0, $t1,($s4)
	.byte 0x66,0x48,0x88,0x7e
#       scwpe $t0,$t1,($s4)
        .byte 0x5e,0x48,0x88,0x7e
	sdbbp
	sdbbp 0
	sdbbp 12
	sdc2 $8,-80($t0)
	sel.s $f0,$f2,$f4
	sel.d $f0,$f2,$f4
	seleqz $t0,$t2,$t4
	selnez $t0,$t2,$t4
	seleqz.s $f0,$f2,$f4
        seleqz.d $f0,$f2,$f4
        selnez.s $f0,$f2,$f4
        selnez.d $f0,$f2,$f4
#	sigrie 0
#	sigrie 12 # gcc encodes to 0x0c,0x00,0x70,0x41
	.byte 0x0c,0x00,0x17,0x04
	swc2 $8,-80($t0)

	.data
data:
	.asciz "Hello, world\n"

