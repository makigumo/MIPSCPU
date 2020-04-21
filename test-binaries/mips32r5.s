#
# compile with: $ mips-elf-as -EL -mips32r5 -meva  %s.s -o %s.o
#
#

	.global _start
	.text
_start:
	li $t0,1
	b 0
	nop
	.global label
label:
	li $t1,5
	li $t3,-5
	nop
	b label
	nop
	beqz $t1,label
	nop
	bnez $zero,label
	nop

	.global jump
jump:
	bal jump
	nop
	bgezal $t1,-8 

	.global hello
hello:
	li $v0,1
	li $a0,1
	la $a1, message
	li $a2,13
	syscall
	break
	break 12
	break 0x3ff
	nal
	.global tests
tests:
	addiu $sp,5
	addiu $sp,$sp,5
	move $at,$at #nop
	move $t1,$t2
	add $t1,$t2,$t3
	addu $t1,$t2,$t3
	or $t4,$t3,$t2
	or $t4,$zero,$t2
	or $at,$zero,$at
	or $at,$at,$zero #nop
	and $t2,$t3,$t4
	andi $t2,$t3,64
	ori $t6,$t8,164
	.global mtc1
mtc1:
	mtc1 $t4, $f2
	mthc1 $t2, $f4
	.global fpu
fpu:
	bc1f start
	bc1f $fcc3, start
	.global fpu_add
fpu_add:
	add.s $f0,$f2,$f4
	add.d $f0,$f4,$f6
	.global fpu_add_mips32r2
fpu_add_mips32r2:
	add.ps $f6,$f8,$f8
	.global fpu_abs
fpu_abs:
	abs.s $f0,$f30
	abs.d $f16,$f18
	.global fpu_abs_mips32r2
fpu_abs_mips32r2:
	abs.ps $f12,$f14
	.global fpu_compare
fpu_compare:
	c.eq.s $f0,$f2
	c.eq.s $fcc3,$f4,$f6
	c.le.s $f0,$f2
	c.lt.s $f0,$f2
	c.ueq.d $f6,$f8
	c.seq.ps $fcc6,$f8,$f6
	.global fpu_ceil
fpu_ceil:
	ceil.l.s $f0,$f4
	ceil.l.d $f4,$f6
	ceil.w.s $f0,$f4
	ceil.w.d $f4,$f6
	.global fpu_cfc
fpu_cfc:
	cfc1 $a1,$f6
	clo $a1,$t1
	clz $a3,$t4
	ctc1 $a1,$f6
	.global fpu_cvt
fpu_cvt:
	cvt.d.s $f0,$f8
	cvt.d.w $f4,$f22
	cvt.d.l $f22,$f8
	cvt.l.s $f0,$f8
	cvt.l.d $f4,$f22
	cvt.ps.s $f4,$f22,$f12
	cvt.s.d $f12,$f6
	cvt.s.w $f14,$f10
	cvt.s.l $f16,$f28
	cvt.s.pl $f0,$f4
	cvt.s.pu $f0,$f4
	cvt.w.s $f0,$f2
	cvt.w.d $f0,$f2
	.global deret
deret:
	deret
	eret
	.global di
di:
	di
	di $a1
	ei
	ei $a2
	.global div
div:
	div $a1,$a2
	divu $t5,$t6
	div.s $f0,$f2,$f4
	div.d $f0,$f2,$f4
	ehb
	.global ext
ext:
	ext $a3,$t1,2,3
	ins $a3,$t3,4,5
	nop
	j start
	nop
	jal ext
	nop
	jalr $a1
	nop
	jalr $a1,$a2
	nop
	jalr.hb $a1
	nop
	jalr.hb $a1,$a2
	nop
	.global jalx
jalx:
#	jalx jalx
#	nop
	jr $ra
	jr $t9
	nop
	jr.hb $t1
	nop
	.global lb
lb:
	lb $gp,12($t1)
	lbe $sp,128($t0)
	lbu $t1,12($t2)
	ldc1 $f0,128($t2)
	ldc2 $31,128($a1)
	ldxc1 $f8,$s7($15)
	lh $gp,12($t1)
	lhe $sp,128($t0)
	lhu $t1,12($t2)
	ll $gp,12($t1)
	lui $t1,0xffff
	luxc1 $f18,$s6($s5)
	lw $gp,12($t1)
	lwc1 $f0,128($t0)
	lwc2 $18,-841($s6)
	lwe $s2,12($t1)
	lwl $s2,12($t1)
	lwr $s2,12($t1)
	lwxc1 $f12,$s1($s7)
	.global madd
madd:
	madd $t1,$t2
	madd $zero,$a1
	madd.s $f0,$f2,$f4,$f6
	madd.d $f0,$f2,$f4,$f6
	madd.ps $f0,$f2,$f4,$f6
	maddu $t1,$t2
	.global msub
msub:
	msub $t1,$t2
	msub $zero,$a1
	msub.s $f0,$f2,$f4,$f6
        msub.d $f0,$f2,$f4,$f6
        msub.ps $f0,$f2,$f4,$f6
        msubu $t1,$t2
	.global mfc
mfc:
	mfc0 $11,$2
	mfc0 $11,$2,0
	mfc0 $11,$2,1
	mfc1 $t1,$f16
	mfhc0 $11,$2
	mfhc0 $11,$2,0
	mfhc0 $11,$2,1
	mfhc1 $t1,$f16
	mfhi $t1
	mflo $t2
	movf $gp,$8,$fcc7
	movf.s $f0,$f4,$fcc2
	movf.d $f0,$f4,$fcc7
	movf.ps $f0,$f4,$fcc0
	movn $v1,$s1,$s0
	movn.s $f0,$f2,$t1
	movn.d $f0,$f2,$t1
	movn.ps $f0,$f2,$t1
	movt $gp,$8,$fcc7
	movt.s $f0,$f4,$fcc2
        movt.d $f0,$f4,$fcc7
        movt.ps $f0,$f4,$fcc0
	movz $v1,$s1,$s0
        movz.s $f0,$f2,$t1
        movz.d $f0,$f2,$t1
        movz.ps $f0,$f2,$t1

	.global mtc
mtc:
	mtc0 $t1,$2
	mtc0 $t1,$2,0
	mtc0 $t4,$6,3
	mtc1 $t4,$f8
	mthc0 $11,$2
        mthc0 $11,$2,0
        mthc0 $11,$2,1
        mthc1 $t1,$f16
	mthi $s0
	mtlo $s1
	.global mul
mul:
	mul $t1,$t2,$t3
	mul.s $f0,$f2,$f4
	mul.d $f0,$f2,$f4
	mul.ps $f0,$f2,$f4
	mult $t0,$t2
	multu $t0,$t2
	.global neg
neg:
	neg.s $f0,$f2
	neg.d $f0,$f2
	neg.ps $f0,$f2
nmadd:
	nmadd.s $f0,$f2,$f4,$f6
	nmadd.d $f0,$f2,$f4,$f6
	nmadd.ps $f0,$f2,$f4,$f6
nmsub:
        nmsub.s $f0,$f2,$f4,$f6
        nmsub.d $f0,$f2,$f4,$f6
        nmsub.ps $f0,$f2,$f4,$f6
nor:
	nor $s0,$s1,$s2
	nor $a3,$zero,$a3
	not $s1,$s2
	not $s1
	.global or
or:
	or $t4,$s0,$sp
	or $v0,4
	ori $v0,$v0,4
	ori $0,$a0,4
	pause
	pll.ps $f0,$f2,$f4
	plu.ps $f0,$f2,$f4
	pul.ps $f0,$f2,$f4
	puu.ps $f0,$f2,$f4
	pref 1, 8($s0)
	prefe 1, 8($s0)
	prefx 1, $t0($s0)

	.global rdhwr
rdhwr:
	rdhwr $sp,$1
	rdpgpr $sp,$t1
	recip.s $f0,$f2
	recip.d $f0,$f2
	rotr $s0,1
	rotr $s0,$s0,1
	rotrv $s0,$s1,$t0
	round.l.s $f0,$f2
	round.l.d $f0,$f2
	round.w.s $f0,$f2
	round.w.d $f0,$f2
	rsqrt.s $f0,$f2
	rsqrt.d $f0,$f2

	.global sb
sb:
	sb $t0,8($s1)
	sbe $t0,8($s1)
	sc $t0,8($s1)
	sce $t0,8($s1)

	.global floor
floor:
	floor.l.s $f0,$f2
	floor.l.d $f4,$f6
	floor.w.s $f0,$f2
	floor.w.d $f4,$f6

	.global cache
cache:
	cache 5, -10($a1)
	cachee 11, -32($t5)
	cachee 11, 255($t5)
	cachee 11, -1($t5)
	cachee 11, -256($t5)
sdbbp:
	sdbbp
	sdbbp 0
	sdbbp 256
sdcx:
	sdc1 $f30,30574($t5)
	sdc2 $20,23157($s2)
	sdxc1 $f10,$t2($14)
seb:
	seb $s0,$s1
	seb $s0,$s0
	seb $s0
        seh $s0,$s1
        seh $s0,$s0
        seh $s0
	sh $t1,32($t3)
	she $t0,8($s1)

	.global sll
sll:
	sll $t1,$t1,12
	sll $t1,$t1,0
	nop
	ssnop
	sllv $t1,$t1,$t2
	sllv $t1,$t2,$t3
	slt $t1,$t2,$t0
	slti $t1,$t2,0xffff
	sltiu $t1,$t2,0xffff
	sltu $t1,$t2,$t3
	sqrt.s $f0,$f2
	sqrt.d $f0,$f2
	sra $t1,$t2,4
	srav $t1,$t2,$t3
	srl $t1,$t2,4
	srlv $t1,$t2,$t3
	sub $t1,$t2,$t3
	sub.s $f0,$f2,$f4
	sub.d $f0,$f2,$f4
	sub.ps $f0,$f2,$f4
	subu $t1,$t2,$t3
	suxc1 $f0, $t1($s0)
	sw $t1, 128($t3)
	swc1 $f0, 128($t3)
	swc2 $14, 128($t3)
	swe $t0, 128($t0)
	swl $t1, 128($t3)
	swle $t0, 128($t0)
        swr $t1, 128($t3)
        swre $t0, 128($t0)
	swxc1 $f0, $s0($t0)

	.global sync
sync:
	sync
	sync 0
	sync 1
	synci 12($t0)
	syscall
	syscall 0
	syscall 256
	teq $t0, $t1
	teq $t0, $t1, 0
	teq $t0, $t1, 128
	teqi $t0, 0xffff
        tge $t0, $t1
        tge $t0, $t1, 0
        tge $t0, $t1, 128
        tgei $t0, 0xffff
        tgeiu $t0, 0xffff
        tgeu $t0, $t1
        tgeu $t0, $t1, 0
        tgeu $t0, $t1, 128
	tlbinv
	tlbinvf
	tlbp
	tlbr
	tlbwi
	tlbwr
        tlt $t0, $t1
        tlt $t0, $t1, 0
        tlt $t0, $t1, 128
        tlti $t0, 0xffff
        tltiu $t0, 0xffff
	tltu $t0, $t1
	tltu $t0, $t1, 0
	tltu $t0, $t1, 128
	tne $t0, $t1
	tne $t0, $t1, 0
	tne $t0, $t1, 128
	tnei $t0, 0xffff

	.global trunc
trunc:
	trunc.l.s $f0,$f2
	trunc.l.d $f0,$f2
	trunc.w.s $f0,$f2
	trunc.w.d $f0,$f2
	wait
	wrpgpr $t0,$t1
	wsbh $t0,$t1
	xor $s2,$a0,$fp
	xor $s2,$s2,$fp
	xor $s2,$fp
	xor $s2,4
	xori $s2,$s2,4
	xori $s2,$s0,0xffff
cop1x:
	alnv.ps $f0,$f2,$f4,$t1
rfe:
	rfe

	.data
message:
	.asciz "Hello, world\n"

