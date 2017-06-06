//
// Created by Dan on 2016/12/16.
// Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>
#include "MIPSCPU.h"

@class MIPSCPU;

typedef enum Reg {
    X0 = 0, X1, X2, X3, X4, X5, X6, X7, X8,
    X9, X10, X11, X12, X13, X14, X15, X16,
    X17, X18, X19, X20, X21, X22, X23, X24,
    X25, X26, X27, X28, X29, X30, X31,
    /** aliases */
    ZERO = X0, AT, V0, V1, A0, A1, A2, A3,
    T0, T1, T2, T3, T4, T5, T6, T7,
    S0, S1, S2, S3, S4, S5, S6, S7,
    T9, T10, K0, K1, GP, SP, FP, RA
} RegEnum;

typedef enum FpuReg {
    F0 = 0, F1, F2, F3, F4, F5, F6, F7,
    F8, F9, F10, F11, F12, F13, F14, F15,
    F16, F17, F18, F19, F20, F21, F22, F23,
    F24, F25, F26, F27, F28, F29, F30, F31,
} FpuRegEnum;

typedef enum OpType {
    RTYPE,
    ITYPE,
    JTYPE,
    INVALID,
} OpTypeEnum;

typedef enum Opcode {
    SPECIAL = 0b000000,
    REGIMM = 0b000001,

    J = 0b000010,
    JAL = 0b000011,

    ADDI = 0b001000,
    ADDIU = 0b001001,
    ANDI = 0b001100,
    ORI = 0b001101,
    XORI = 0b001110,
    BEQ = 0b000100,
    BNE = 0b000101,
    BLEZ = 0b000110,
    BGTZ = 0b000111,
    SLTI = 0b001010,
    SLTIU = 0b001011,
    LUI = 0b001111,

    COP0 = 0b010000,
    COP1 = 0b010001,
    COP2 = 0b010010,

    LB = 0b100000,
    LH = 0b100001,
    LW = 0b100011,
    LBU = 0b100100,
    LHU = 0b100101,
    SB = 0b101000,
    SH = 0b101001,
    SW = 0b101011,
    LWC1 = 0b110001,
    LWC2 = 0b110010,
    LDC1 = 0b110101,
    LDC2 = 0b110110,
    SWC1 = 0b111001,
    SWC2 = 0b111010,

    // MIPS32R2
    BEQL = 0b010100,
    BLEZL = 0b010110,
    BGTZL = 0b010111,

    SPECIAL2 = 0b011100,
    SPECIAL3 = 0b011111,
} OpcodeEnum;

typedef enum SpecialFunct {
    NOP = 0b000000,
    SRL = 0b000010,
    SRA = 0b000011,
    SLLV = 0b000100,
    SRLV = 0b000110,
    SRAV = 0b000111,

    JR = 0b001000,
    JALR = 0b001001,

    MOVN = 0b001011,

    SYSCALL = 0b001100,
    BREAK = 0b001101,

    MFHI = 0b010000,
    MTHI = 0b010001,
    MFLO = 0b010010,
    MTLO = 0b010011,
    MULT = 0b011000,
    MULTU = 0b011001,
    DIV = 0b011010,
    DIVU = 0b011011,

    ADD = 0b100000,
    ADDU = 0b100001,
    AND = 0b100100,
    OR = 0b100101,
    SLT = 0b101010,
    SLTU = 0b101011,
    SUB = 0b100010,
    SUBU = 0b100011,
    XOR = 0b100110,
    NOR = 0b100111,
} SpecialFunctEnum;

typedef enum RegImmFunct {
    BLTZ = 0b00000,
    BGEZ = 0b00001,
    BGEZAL = 0b10001,
    BLTZALL = 0b10010,
} RegImmFunctEnum;

typedef enum CopFunct {
    MT = 0b00100,
    MTH = 0b00111,
} CopFunctEnum;

typedef enum DelaySlotType {
    NONE,
    BRANCH,
    LOAD,
} DelaySlotTypeEnum;

typedef enum DelaySlotCondition {
    ALWAYS,
    BRANCH_TAKEN,
    BRANCH_NOT_TAKEN,
} DelaySlotConditionEnum;

typedef struct DelaySlot {
    enum DelaySlotType type;
    enum DelaySlotCondition condition;
} DelaySlot;

typedef struct rtype {
    union {
        enum Reg rs; // bits 25..21 source register 1
        enum CopFunct copFunct; // bits 25..21
    };
    enum Reg rt; // bits 20..16 source register 2
    enum Reg rd; // bits 15..11 destination register
    union {
        struct {
            uint8_t shift; // bits 10..6 shift amount
            enum SpecialFunct specialFunct; // bits 5..0 function
        };
        struct {
            uint8_t sel; // bits 2..0 sel
        };
    };
} rtype;

typedef struct itype {
    enum Reg rs; // bits 25..21 source register 1
    union {
        enum Reg rt; // bits 20..16 destination register
        enum RegImmFunct regImmFunct; // bits 20..16
    };
    uint16_t imm; // bits 15..0 immediate
} itype;

typedef struct jtype {
    enum Reg rs; // bits 25..21 source register 1
    uint32_t imm; // bits 20..0 immediate
} jtype;

typedef struct insn {
    enum Opcode opcode; // bits 31..26
    enum OpType type; // instruction format type
    struct DelaySlot delayslot; // delay slot type
    union {
        struct rtype rtype;
        struct itype itype;
        struct jtype jtype;
    };
} insn;

#define REG_MASK(cls, reg) \
    (DISASM_BUILD_REGISTER_CLS_MASK(cls) | DISASM_BUILD_REGISTER_INDEX_MASK(reg))

static DisasmOperandType reg_masks_32[] = {
        REG_MASK(RegClass_MIPS_ZERO, 0) /* zero */,
        REG_MASK(RegClass_MIPS_AT, 0) /* at */,
        REG_MASK(RegClass_MIPS_VAR, 0) /* v0 */,
        REG_MASK(RegClass_MIPS_VAR, 1) /* v1 */,
        REG_MASK(RegClass_MIPS_ARG, 0) /* a0 */,
        REG_MASK(RegClass_MIPS_ARG, 1) /* a1 */,
        REG_MASK(RegClass_MIPS_ARG, 2) /* a2 */,
        REG_MASK(RegClass_MIPS_ARG, 3) /* a3 */,
        REG_MASK(RegClass_MIPS_TMP, 0) /* t0 */,
        REG_MASK(RegClass_MIPS_TMP, 1) /* t1 */,
        REG_MASK(RegClass_MIPS_TMP, 2) /* t2 */,
        REG_MASK(RegClass_MIPS_TMP, 3) /* t3 */,
        REG_MASK(RegClass_MIPS_TMP, 4) /* t4 */,
        REG_MASK(RegClass_MIPS_TMP, 5) /* t5 */,
        REG_MASK(RegClass_MIPS_TMP, 6) /* t6 */,
        REG_MASK(RegClass_MIPS_TMP, 7) /* t7 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 0) /* s0 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 1) /* s1 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 2) /* s2 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 3) /* s3 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 4) /* s4 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 5) /* s5 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 6) /* s6 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 7) /* s7 */,
        REG_MASK(RegClass_MIPS_TMP, 8) /* t8 */,
        REG_MASK(RegClass_MIPS_TMP, 9) /* t9 */,
        REG_MASK(RegClass_MIPS_KERNEL, 0) /* k0 */,
        REG_MASK(RegClass_MIPS_KERNEL, 1) /* k1 */,
        REG_MASK(RegClass_GeneralPurposeRegister, 8) /* gp */,
        REG_MASK(RegClass_GeneralPurposeRegister, 9) /* sp */,
        REG_MASK(RegClass_GeneralPurposeRegister, 10) /* fp */,
        REG_MASK(RegClass_GeneralPurposeRegister, 11) /* ra */,
};


static inline DisasmOperandType getRegMask(enum Reg reg) {
    return reg_masks_32[reg];
}

static inline DisasmOperandType getFpuRegMask(enum FpuReg reg) {
    return REG_MASK(RegClass_MIPS_FPU, reg);
}

static inline void setDelaySlot(struct insn *in) {
    switch (in->type) {
        case RTYPE:
            switch (in->rtype.specialFunct) {
                case JR:
                case JALR:
                    in->delayslot.type = BRANCH;
                    in->delayslot.condition = ALWAYS;
                    break;
            }
            break;
        case ITYPE:
            switch (in->opcode) {
                case REGIMM:
                    switch (in->itype.rt) {
                        case X0 /* BLTZ */:
                        case X1 /* BGEZ */:
                        case X17 /* BGEZAL */:
                            in->delayslot.type = BRANCH;
                            in->delayslot.condition = ALWAYS;
                            break;
                        case X18 /* BLTZALL */:
                            in->delayslot.type = BRANCH;
                            in->delayslot.condition = BRANCH_TAKEN;
                            break;
                    }
                    break;
                case BEQ:
                case BNE:
                case BLEZ:
                case BGTZ:
                    in->delayslot.type = BRANCH;
                    in->delayslot.condition = ALWAYS;
                    break;
                case BEQL:
                case BLEZL:
                case BGTZL:
                    in->delayslot.type = BRANCH;
                    in->delayslot.condition = BRANCH_TAKEN;
                    break;
                case LUI:
                case LB:
                case LH:
                case LW:
                case LBU:
                case LHU:
                    in->delayslot.type = LOAD;
                    in->delayslot.condition = ALWAYS;
                    break;
            }
            break;
        case JTYPE:
            in->delayslot.type = BRANCH;
            in->delayslot.condition = ALWAYS;
            break;
    }
}

static inline void populateRegOperand(DisasmOperand *op, enum Reg reg, DisasmAccessMode accessMode) {
    op->type = DISASM_OPERAND_REGISTER_TYPE;
    op->type |= getRegMask(reg);
    op->accessMode = accessMode;
}

static inline void populateFpuRegOperand(DisasmOperand *op, enum FpuReg reg, DisasmAccessMode accessMode) {
    op->type = DISASM_OPERAND_REGISTER_TYPE;
    op->type |= getFpuRegMask(reg);
    op->accessMode = accessMode;
}

static inline void populateImm16Operand(DisasmOperand *op, int16_t imm) {
    op->type = DISASM_OPERAND_CONSTANT_TYPE;
    op->immediateValue = imm;
    op->size = 16;
    op->accessMode = DISASM_ACCESS_READ;
}

static inline void populateUImm16Operand(DisasmOperand *op, uint16_t imm) {
    op->type = DISASM_OPERAND_CONSTANT_TYPE;
    op->immediateValue = imm;
    op->size = 16;
    op->accessMode = DISASM_ACCESS_READ;
}

static inline void populateRType(DisasmStruct *disasm, struct insn *pInsn) {

    switch (pInsn->rtype.specialFunct) {
        case NOP:
            if (pInsn->rtype.rs == ZERO && pInsn->rtype.rt == ZERO &&
                    pInsn->rtype.rd == ZERO && pInsn->rtype.shift == 0) {
                strcpy(disasm->instruction.mnemonic, "nop");
            } else {
                strcpy(disasm->instruction.mnemonic, "sll");

                populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);

                if (pInsn->rtype.rd == pInsn->rtype.rt) {
                    disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[1].immediateValue = pInsn->rtype.shift;
                    disasm->operand[1].size = 5;
                } else {
                    populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);

                    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[2].immediateValue = pInsn->rtype.shift;
                    disasm->operand[2].size = 5;
                }
            }
            return;
        case SRL:
            strcpy(disasm->instruction.mnemonic, "srl");

            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);

            if (pInsn->rtype.rd == pInsn->rtype.rt) {
                disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[1].immediateValue = pInsn->rtype.shift;
                disasm->operand[1].size = 5;
            } else {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);

                disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[2].immediateValue = pInsn->rtype.shift;
                disasm->operand[2].size = 5;
            }
            return;
        case SRA:
            strcpy(disasm->instruction.mnemonic, "sra");

            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);

            if (pInsn->rtype.rd == pInsn->rtype.rt) {
                disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[1].immediateValue = pInsn->rtype.shift;
                disasm->operand[1].size = 5;
            } else {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);

                disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[2].immediateValue = pInsn->rtype.shift;
                disasm->operand[2].size = 5;
            }
            return;
        case SLLV:
            strcpy(disasm->instruction.mnemonic, "sllv");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
            if (pInsn->rtype.rd == pInsn->rtype.rt) {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
            } else {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                populateRegOperand(&disasm->operand[2], pInsn->rtype.rs, DISASM_ACCESS_READ);
            }
            return;
        case SRLV:
            strcpy(disasm->instruction.mnemonic, "srlv");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
            if (pInsn->rtype.rd == pInsn->rtype.rt) {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
            } else {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                populateRegOperand(&disasm->operand[2], pInsn->rtype.rs, DISASM_ACCESS_READ);
            }
            return;
        case SRAV:
            strcpy(disasm->instruction.mnemonic, "srav");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
            if (pInsn->rtype.rd == pInsn->rtype.rt) {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
            } else {
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                populateRegOperand(&disasm->operand[2], pInsn->rtype.rs, DISASM_ACCESS_READ);
            }
            return;
        case MOVN:
            strcpy(disasm->instruction.mnemonic, "movn");
            break;
        case ADD:
            strcpy(disasm->instruction.mnemonic, "add");
            break;
        case ADDU:
            if (pInsn->rtype.rt == ZERO) {
                strcpy(disasm->instruction.mnemonic, "move");
                populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
                return;
            } else {
                strcpy(disasm->instruction.mnemonic, "addu");
            }
            break;
        case AND:
            strcpy(disasm->instruction.mnemonic, "and");
            break;
        case OR:
            if (pInsn->rtype.rt == ZERO) {
                strcpy(disasm->instruction.mnemonic, "move");
                populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
                return;
            } else {
                strcpy(disasm->instruction.mnemonic, "or");
                if (pInsn->rtype.rd == pInsn->rtype.rs) {
                    populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                    populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                    return;
                }
            }
            break;
        case SLT:
            strcpy(disasm->instruction.mnemonic, "slt");
            break;
        case SLTU:
            strcpy(disasm->instruction.mnemonic, "sltu");
            break;
        case SUB:
            strcpy(disasm->instruction.mnemonic, "sub");
            break;
        case SUBU:
            if (pInsn->rtype.rs == ZERO) {
                strcpy(disasm->instruction.mnemonic, "negu");
                populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                return;
            } else {
                strcpy(disasm->instruction.mnemonic, "subu");
                if (pInsn->rtype.rd == pInsn->rtype.rs) {
                    populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                    populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
                    return;
                }
            }
            break;
        case XOR:
            strcpy(disasm->instruction.mnemonic, "xor");
            break;
        case NOR:
            strcpy(disasm->instruction.mnemonic, "nor");
            break;
        case BREAK:
            strcpy(disasm->instruction.mnemonic, "break");
            return;
        case JR:
            strcpy(disasm->instruction.mnemonic, "jr");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            if (pInsn->rtype.rs == RA) {
                disasm->instruction.branchType = DISASM_BRANCH_RET;
            }
            disasm->instruction.branchType = DISASM_BRANCH_JMP;
            return;
        case JALR:
            strcpy(disasm->instruction.mnemonic, "jalr");
            if (pInsn->rtype.rd == RA) {
                populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            } else {
                populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
                populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
            }

            disasm->instruction.branchType = DISASM_BRANCH_CALL;
            return;
        case SYSCALL:
            strcpy(disasm->instruction.mnemonic, "syscall");
            return;
        case MULT:
            strcpy(disasm->instruction.mnemonic, "mult");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
            return;
        case MULTU:
            strcpy(disasm->instruction.mnemonic, "multu");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
            return;
        case DIV:
            strcpy(disasm->instruction.mnemonic, "div");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
            return;
        case DIVU:
            strcpy(disasm->instruction.mnemonic, "divu");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_WRITE);
            populateRegOperand(&disasm->operand[1], pInsn->rtype.rt, DISASM_ACCESS_READ);
            return;
        case MFHI:
            strcpy(disasm->instruction.mnemonic, "mfhi");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
            return;
        case MTHI:
            strcpy(disasm->instruction.mnemonic, "mthi");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_READ);
            return;
        case MFLO:
            strcpy(disasm->instruction.mnemonic, "mflo");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
            return;
        case MTLO:
            strcpy(disasm->instruction.mnemonic, "mtlo");
            populateRegOperand(&disasm->operand[0], pInsn->rtype.rs, DISASM_ACCESS_READ);
            return;
        default:
            return;
    }

    populateRegOperand(&disasm->operand[0], pInsn->rtype.rd, DISASM_ACCESS_WRITE);
    populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);
    populateRegOperand(&disasm->operand[2], pInsn->rtype.rt, DISASM_ACCESS_READ);
}


static inline void populateJType(DisasmStruct *disasm, struct insn *pInsn) {
    switch (pInsn->opcode) {
        case J:
            strcpy(disasm->instruction.mnemonic, "j");
            disasm->instruction.branchType = DISASM_BRANCH_JMP;
            break;
        case JAL:
            strcpy(disasm->instruction.mnemonic, "jal");
            disasm->instruction.branchType = DISASM_BRANCH_CALL;
            break;
        default:
            strcpy(disasm->instruction.mnemonic, "unk_jtype");
    }

    disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[0].immediateValue = (int32_t) (pInsn->jtype.imm << 6) >> 6;
    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
    disasm->operand[0].size = 26;
    disasm->operand[0].isBranchDestination = 1;
    // target address is a full 32-bit address consisting of
    // * highest 4 bits of PC (instruction after jump)
    // * 2-bit left shifted 26-bit immediate
    disasm->instruction.addressValue = ((disasm->virtualAddr + 4) & 0xff000000)
            + (disasm->operand[0].immediateValue << 2);
}

/**
 * setup for unsigned immediate value
 * @param disasm
 * @param pInsn
 * @param name
 */
static inline void populateITypeU(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->rtype.rt, DISASM_ACCESS_WRITE);

    if (pInsn->itype.rt != pInsn->itype.rs) {
        populateRegOperand(&disasm->operand[1], pInsn->rtype.rs, DISASM_ACCESS_READ);

        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[2].immediateValue = pInsn->itype.imm;
        disasm->operand[2].size = 16;
        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
    } else {
        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
        disasm->operand[1].immediateValue = pInsn->itype.imm;
        disasm->operand[1].size = 16;
        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    }
}

/**
 * setup for signed immediate value
 * @param disasm
 * @param pInsn
 * @param name
 */
static inline void populateITypeS(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rt, DISASM_ACCESS_WRITE);

    if (pInsn->itype.rt != pInsn->itype.rs) {
        populateRegOperand(&disasm->operand[1], pInsn->itype.rs, DISASM_ACCESS_READ);

        disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
        disasm->operand[2].immediateValue = pInsn->itype.imm;
        disasm->operand[2].size = 16;
        disasm->operand[2].accessMode = DISASM_ACCESS_READ;
    } else {
        disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
        disasm->operand[1].immediateValue = pInsn->itype.imm;
        disasm->operand[1].size = 16;
        disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    }
}

/**
 * setup for signed immediate value
 * @param disasm
 * @param pInsn
 * @param name
 */
static inline void populateITypeSZero(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rt, DISASM_ACCESS_WRITE);

    disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[1].immediateValue = pInsn->itype.imm;
    disasm->operand[1].size = 16;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
}

static inline void populateITypeLabel(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rt, DISASM_ACCESS_READ);

    populateRegOperand(&disasm->operand[1], pInsn->itype.rs, DISASM_ACCESS_READ);

    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[2].immediateValue = (int16_t) pInsn->itype.imm;
    disasm->operand[2].size = 16;
    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
    disasm->operand[2].isBranchDestination = 1;
    disasm->instruction.addressValue = disasm->virtualAddr + 4 + (disasm->operand[2].immediateValue << 2);
}

static inline void populateITypeLabelZero(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rs, DISASM_ACCESS_READ);

    disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[1].immediateValue = (int16_t) pInsn->itype.imm;
    disasm->operand[1].size = 16;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[1].isBranchDestination = 1;
    disasm->instruction.addressValue = disasm->virtualAddr + 4 + (disasm->operand[1].immediateValue << 2);
}

static inline void populateITypeLabelZeroZero(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));

    disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[0].immediateValue = (int16_t) pInsn->itype.imm;
    disasm->operand[0].size = 16;
    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
    disasm->operand[0].isBranchDestination = 1;
    disasm->instruction.addressValue = disasm->virtualAddr + 4 + (disasm->operand[0].immediateValue << 2);
}

static inline void populateITypeRegLabel(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rs, DISASM_ACCESS_READ);

    disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[1].immediateValue = (int16_t) pInsn->itype.imm;
    disasm->operand[1].size = 16;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
    disasm->operand[1].isBranchDestination = 1;
    disasm->instruction.addressValue = disasm->virtualAddr + 4 + (disasm->operand[1].immediateValue << 2);
}

static inline void populateITypeImm(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    populateRegOperand(&disasm->operand[0], pInsn->itype.rt, DISASM_ACCESS_WRITE);

    disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
    disasm->operand[1].immediateValue = pInsn->itype.imm;
    disasm->operand[1].size = 16;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
}

static inline void populateITypeMem(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getRegMask(pInsn->itype.rt);

    disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE | DISASM_OPERAND_RELATIVE;
    disasm->operand[1].type |= getRegMask(pInsn->itype.rs);
    disasm->operand[1].memory.baseRegistersMask = getRegMask(pInsn->itype.rs);
    disasm->operand[1].memory.displacement = (int16_t) pInsn->itype.imm;
    disasm->operand[1].size = 16;
}

static inline void populateITypeMemRead(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    populateITypeMem(disasm, pInsn, name);
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
}

static inline void populateITypeMemWrite(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    populateITypeMem(disasm, pInsn, name);
    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
    disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
}

static inline void populateFPUITypeMem(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    strncpy(disasm->instruction.mnemonic, name, sizeof(disasm->instruction.mnemonic));
    disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
    disasm->operand[0].type |= getFpuRegMask((enum FpuReg) pInsn->itype.rt);

    disasm->operand[1].type = DISASM_OPERAND_MEMORY_TYPE;
    disasm->operand[1].type |= getRegMask(pInsn->itype.rs);
    disasm->operand[1].memory.baseRegistersMask = getRegMask(pInsn->itype.rs);
    disasm->operand[1].memory.displacement = (int16_t) pInsn->itype.imm;
    disasm->operand[1].size = 16;
}

static inline void populateFPUITypeMemRead(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    populateFPUITypeMem(disasm, pInsn, name);
    disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
}

static inline void populateFPUITypeMemWrite(DisasmStruct *disasm, struct insn *pInsn, const char *const name) {
    populateFPUITypeMem(disasm, pInsn, name);
    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
    disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
}

static inline uint32_t _MyOSReadInt32(const volatile void *base, uintptr_t byteOffset) {
    return *(volatile uint32_t *) ((uintptr_t) base + byteOffset);
}

@interface MIPSCtx : NSObject <CPUContext>

typedef enum BuildOp {
    BUILDOP_ADD,
    BUILDOP_OR,
} BuildOpEnum;

- (instancetype)initWithCPU:(MIPSCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file;

@end
