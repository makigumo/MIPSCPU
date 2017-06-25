//
//  MIPSCSCtx.m
//  MIPSCPU
//
//  Created by Makigumo on 10/11/2016.
//  Copyright (c) 2016 Makigumo. All rights reserved.
//

#import "MIPSCSCtx.h"
#import "MIPSCPU.h"
#import <capstone/capstone.h>
#import <Hopper/Hopper.h>

#define OPERAND(insn, op_index) insn.detail->mips.operands[op_index]
#define OPERAND_IS_REG(insn, op_index, op_reg) \
    (OPERAND(insn, op_index).type == MIPS_OP_REG && OPERAND(insn, op_index).reg == op_reg)
#define REG_MASK(reg) \
    (capstoneRegisterToRegIndex(reg) != (uint32_t) -1 ) ? \
    (DISASM_BUILD_REGISTER_CLS_MASK(capstoneRegisterToRegClass(reg)) | DISASM_BUILD_REGISTER_INDEX_MASK(capstoneRegisterToRegIndex(reg))) : \
    0

@implementation MIPSCSCtx {
    MIPSCPU *_cpu;
    NSObject <HPDisassembledFile> *_file;
    csh _handle;
}

- (instancetype)initWithCPU:(MIPSCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
        cs_mode mode = CS_MODE_MIPS32;
        if ([file.cpuSubFamily isEqualToString:@"microMIPS"]) {
            mode += CS_MODE_MICRO;
        } else if ([file.cpuSubFamily isEqualToString:@"mipsIII"]) {
            mode += CS_MODE_MIPS3;
        } else if ([file.cpuSubFamily isEqualToString:@"microMIPS"]) {
            mode += CS_MODE_MICRO;
        } else if ([file.cpuSubFamily isEqualToString:@"micro32r6"]) {
            mode += CS_MODE_MIPS32R6;
        }
        cs_mode endianess = (_cpu.endianess == CPUEndianess_Little) ? CS_MODE_LITTLE_ENDIAN : CS_MODE_BIG_ENDIAN;
        if (cs_open(CS_ARCH_MIPS, mode + endianess, &_handle) != CS_ERR_OK) {
            return nil;
        }
        cs_option(_handle, CS_OPT_DETAIL, CS_OPT_ON);
    }
    return self;
}

- (void)dealloc {
    cs_close(&_handle);
}

- (NSObject <CPUDefinition> *)cpuDefinition {
    return _cpu;
}

static inline void clear_operands_from(DisasmStruct *disasm, int index) {
    for (; index < DISASM_MAX_OPERANDS; index++) {
        disasm->operand[index].type = DISASM_OPERAND_NO_OPERAND;
    }
}

- (void)initDisasmStructure:(DisasmStruct *)disasm withSyntaxIndex:(NSUInteger)syntaxIndex {
    bzero(disasm, sizeof(DisasmStruct));
    disasm->syntaxIndex = (uint8_t) syntaxIndex;
    clear_operands_from(disasm, 0);
}

// Analysis
#pragma mark - Analysis -

- (Address)adjustCodeAddress:(Address)address {
    // Instructions are always aligned to a multiple of 4.
    return address & ~3;
}

- (uint8_t)cpuModeFromAddress:(Address)address {
    return 0;
}

- (BOOL)addressForcesACPUMode:(Address)address {
    return NO;
}

- (Address)nextAddressToTryIfInstructionFailedToDecodeAt:(Address)address forCPUMode:(uint8_t)mode {
    return ((address & ~3) + 4);
}

- (int)isNopAt:(Address)address {
    uint32_t word = [_file readUInt32AtVirtualAddress:address];
    return (word == 0x0) ? 4 : 0;
}

- (BOOL)hasProcedurePrologAt:(Address)address {
/*
    // a typical function might save registers it wants to preserve on the stack, e.g. ra
    uint32_t word = [_file readUInt32AtVirtualAddress:address];
    BOOL hasPrecedingRet = NO;
    if ([_file hasCodeAt:address - 4]) {
        uint32_t prev_word = [_file readUInt32AtVirtualAddress:address - 4];
        hasPrecedingRet = prev_word == 0x03e00008; // jr ra = return from procedure
    }
    return (word & 0xff000000) == 0x3c000000 // lui reg, n
            || (word & 0xffff8000) == 0x27bd8000 // addiu sp, sp, -n = allocate space on stack for n/4 registers
            || hasPrecedingRet;
*/
    return NO;
}

- (NSUInteger)detectedPaddingLengthAt:(Address)address {
    Address i = address & 3;
    if (i) {
        return 4 - i;
    }
    return 0;
}

- (void)analysisBeginsAt:(Address)entryPoint {

}

- (void)analysisEnded {

}

- (void)procedureAnalysisBeginsForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfPrologForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisOfEpilogForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisEndedForProcedure:(NSObject <HPProcedure> *)procedure atEntryPoint:(Address)entryPoint {

}

- (void)procedureAnalysisContinuesOnBasicBlock:(NSObject <HPBasicBlock> *)basicBlock {

}

- (Address)getThunkDestinationForInstructionAt:(Address)address {
    return BAD_ADDRESS;
}

- (void)resetDisassembler {

}

- (uint8_t)estimateCPUModeAtVirtualAddress:(Address)address {
    return 0;
}

static inline uint32_t capstoneRegisterToRegIndex(mips_reg reg) {
    RegClass idx[] = {
            (RegClass) -1,

            // PC
            0,

            // zero, at, v0..v1
            0, 1, 2, 3,
            // a0..a3
            4, 5, 6, 7,
            // t0..t7
            8, 9, 10, 11,
            12, 13, 14, 15,
            // s0..s7
            16, 17, 18, 19,
            20, 21, 22, 23,
            // t8..t9, k0..k1
            24, 25, 26, 27,
            // gp, sp, s8/fp, ra
            28, 29, 30, 31,

            // DSP
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10,

            // ACC = HI, LO
            0, 1, 2, 3,

            // COP
            0, 1, 2, 3,
            4, 5, 6, 7,

            // FP0..FP31
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11,
            12, 13, 14, 15,
            16, 17, 18, 19,
            20, 21, 22, 23,
            24, 25, 26, 27,
            28, 29, 30, 31,

            // FCC
            0, 1, 2, 3,
            4, 5, 6, 7,

            // AFPR0..AFPR31 // TODO
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11,
            12, 13, 14, 15,
            16, 17, 18, 19,
            20, 21, 22, 23,
            24, 25, 26, 27,
            28, 29, 30, 31,

            // HI..LO
            0, 1,

            // P
            0, 1, 2,

            // MPL
            0, 1, 2,
    };

    if ((int) reg >= 0 && (int) reg < MIPS_REG_ENDING) {
        return idx[reg];
    }

    return (uint32_t) -1;
}

static inline RegClass capstoneRegisterToRegClass(mips_reg reg) {
    RegClass cls[] = {
            (RegClass) -1,

            // PC
            (RegClass) RegClass_GeneralPurposeRegister,

            // zero, at, v0..v1
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,

            // a0..a3
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,

            // t0..t7
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,

            // s0..s7
            RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister,
            RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister,

            // t8..t9, k0..k1
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,

            // gp, sp, s8/fp, ra
            RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister, RegClass_GeneralPurposeRegister,

            // DSP
            (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP,
            (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP,
            (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP, (RegClass) RegClass_MIPS_DSP,

            // ACC = HI, LO
            (RegClass) RegClass_MIPS_ACC, (RegClass) RegClass_MIPS_ACC, (RegClass) RegClass_MIPS_ACC, (RegClass) RegClass_MIPS_ACC,

            // COP
            (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP,
            (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP, (RegClass) RegClass_MIPS_COP,

            // FP0..FP31 (fpu registers)
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,

            // FCC
            (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC,
            (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC, (RegClass) RegClass_MIPS_FCC,

            // AFPR0..AFPR31 (aliased fpu registers)
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,
            (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU, (RegClass) RegClass_MIPS_FPU,

            // HI..LO
            (RegClass) RegClass_GeneralPurposeRegister, (RegClass) RegClass_GeneralPurposeRegister,

            // P
            (RegClass) RegClass_MIPS_P, (RegClass) RegClass_MIPS_P, (RegClass) RegClass_MIPS_P,

            // MPL
            (RegClass) RegClass_MIPS_MPL, (RegClass) RegClass_MIPS_MPL, (RegClass) RegClass_MIPS_MPL

    };

    if ((int) reg < MIPS_REG_ENDING) {
        return cls[reg];
    }

    return (RegClass) -1;
}

- (int)disassembleSingleInstruction:(DisasmStruct *)disasm
                 usingProcessorMode:(NSUInteger)mode {
    if (disasm->bytes == NULL) return DISASM_UNKNOWN_OPCODE;

    cs_insn *insn;
    size_t count = cs_disasm(_handle, disasm->bytes, 32, disasm->virtualAddr, 4, &insn);
    if (count == 0) return DISASM_UNKNOWN_OPCODE;

    BOOL isPseudoIns = NO;
    size_t pseudoInsSize = 0;
    disasm->instruction.addressValue = 0;
    disasm->instruction.branchType = DISASM_BRANCH_NONE;

    if (mode == 1 /* pseudo instructions */) {
        // addiu xx, zero, yy -> li xx, yy
        if (insn[0].id == MIPS_INS_ADDIU && OPERAND(insn[0], 1).type == MIPS_OP_REG && OPERAND(insn[0], 1).reg == MIPS_REG_ZERO) {
            strcpy(disasm->instruction.mnemonic, "li");
            disasm->operand[0].type = DISASM_OPERAND_REGISTER_TYPE;
            disasm->operand[0].type |= REG_MASK(OPERAND(insn[0], 0).reg);
            disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
            disasm->operand[1].type = DISASM_OPERAND_CONSTANT_TYPE;
            disasm->operand[1].immediateValue = OPERAND(insn[0], 2).imm;
            disasm->operand[1].accessMode = DISASM_ACCESS_READ;
            isPseudoIns = YES;
            pseudoInsSize = 4;
        } else if (count > 1) {
            // pseudo instruction
            // load immediate
            // li $gp, 0x4a6aa0 -> lui gp, 0x4a; addiu gp, gp, 0x6aa0
            // la $t9, 0x405720 -> lui t9, 0x40; addiu t9, t9, 0x5720
            if (insn[0].id == MIPS_INS_LUI && insn[1].id == MIPS_INS_ADDIU) {
                if (OPERAND(insn[0], 0).type == MIPS_OP_REG && OPERAND(insn[0], 1).type == MIPS_OP_IMM) {
                    mips_reg li_reg = OPERAND(insn[0], 0).reg;

                    if (OPERAND(insn[1], 0).type == MIPS_OP_REG && OPERAND(insn[1], 1).type == MIPS_OP_REG) {
                        if (OPERAND(insn[1], 0).reg == li_reg && OPERAND(insn[1], 1).reg == li_reg) {
                            if (OPERAND(insn[1], 2).type == MIPS_OP_IMM) {
                                uint32_t li_imm = (uint32_t) ((OPERAND(insn[0], 1).imm
                                        << 16) + OPERAND(insn[1], 2).imm);

                                strcpy(disasm->instruction.mnemonic, "li");
                                disasm->instruction.branchType = DISASM_BRANCH_NONE;
                                if (li_reg == MIPS_REG_GP) {
                                    disasm->instruction.addressValue = li_imm;
                                } else {
                                    disasm->instruction.addressValue = 0;
                                }
                                disasm->instruction.pcRegisterValue = disasm->virtualAddr + insn[0].size + insn[1].size;
                                disasm->instruction.length = 8;

                                DisasmOperand *reg_op = disasm->operand;
                                reg_op->type = DISASM_OPERAND_REGISTER_TYPE;
                                reg_op->type |= REG_MASK(li_reg);
                                reg_op->accessMode = DISASM_ACCESS_WRITE;

                                DisasmOperand *imm_op = disasm->operand + 1;
                                imm_op->type = DISASM_OPERAND_CONSTANT_TYPE;
                                imm_op->immediateValue = li_imm & 0xffffffff;
                                imm_op->size = 32;
                                imm_op->accessMode = DISASM_ACCESS_READ;
                                isPseudoIns = YES;
                                pseudoInsSize = 8;
                            }
                        }
                    }
                }
            }
            // load byte upper from address
            // lbu $v0, 49eb50 -> lui v0, #0x4a; lbu v0, -0x14b0(v0)
            if (insn[0].id == MIPS_INS_LUI && insn[1].id == MIPS_INS_LBU) {
                if (OPERAND(insn[0], 0).type == MIPS_OP_REG && OPERAND(insn[0], 1).type == MIPS_OP_IMM) {
                    mips_reg li_reg = OPERAND(insn[0], 0).reg;
                    int64_t lui_imm = OPERAND(insn[0], 1).imm;

                    if (OPERAND(insn[1], 0).type == MIPS_OP_REG && OPERAND(insn[1], 0).reg == li_reg) {
                        if (OPERAND(insn[1], 1).type == MIPS_OP_MEM) {
                            strcpy(disasm->instruction.mnemonic, "lbu");
                            disasm->instruction.branchType = DISASM_BRANCH_NONE;
                            disasm->instruction.addressValue = 0;
                            disasm->instruction.pcRegisterValue = disasm->virtualAddr + insn[0].size + insn[1].size;
                            disasm->instruction.length = 8;

                            DisasmOperand *reg_op = disasm->operand;
                            reg_op->type = DISASM_OPERAND_REGISTER_TYPE;
                            reg_op->type |= REG_MASK(li_reg);
                            reg_op->accessMode = DISASM_ACCESS_WRITE;

                            DisasmOperand *mem_op = disasm->operand + 1;
                            mem_op->type = DISASM_OPERAND_MEMORY_TYPE;
                            mem_op->memory.displacement = (uint32_t) ((lui_imm
                                    << 16) + (int32_t) OPERAND(insn[1], 1).mem.disp);
                            mem_op->size = 32;
                            mem_op->accessMode = DISASM_ACCESS_READ;
                            isPseudoIns = YES;
                            pseudoInsSize = 8;
                        }
                    }
                }
            }
            // branch to L1 if $t1 < $t2
            // blt $t1, $t2, L1 -> slt $at, $t1, $t2; bne $at, $0, L1
            // blt $t1, $t2, L1 -> slt $at, $t1, $t2; bnez $at, L1
            // also bgt, bge, ble
            // slt = set on less then
            if (insn[0].id == MIPS_INS_SLT) {

                mips_insn branch = (insn[1].id == MIPS_INS_BNEZ) || (insn[1].id == MIPS_INS_BNE && OPERAND_IS_REG(insn[1], 1, MIPS_REG_ZERO)) ?
                        MIPS_INS_BNEZ : MIPS_INS_INVALID;

                if (branch && OPERAND(insn[0], 0).type == OPERAND(insn[1], 0).type == MIPS_OP_REG &&
                        OPERAND(insn[0], 0).reg == OPERAND(insn[1], 0).reg) {

                    mips_reg left_reg = OPERAND(insn[0], 1).reg;
                    mips_reg right_reg = OPERAND(insn[0], 2).reg;
                    int64_t imm = OPERAND(insn[1], 1).imm;

                    switch (branch) {
                        case MIPS_INS_BNEZ:
                            strcpy(disasm->instruction.mnemonic, "blt");
                            disasm->instruction.branchType = DISASM_BRANCH_JL;
                            break;
                    }
                    disasm->instruction.addressValue = (Address) imm;
                    disasm->instruction.pcRegisterValue = disasm->virtualAddr + insn[0].size + insn[1].size;
                    disasm->instruction.length = 8;

                    DisasmOperand *left_op = disasm->operand;
                    left_op->type = DISASM_OPERAND_REGISTER_TYPE;
                    left_op->type |= REG_MASK(left_reg);
                    left_op->accessMode = DISASM_ACCESS_READ;

                    DisasmOperand *middle_op = disasm->operand + 1;
                    middle_op->type = DISASM_OPERAND_REGISTER_TYPE;
                    middle_op->type |= REG_MASK(right_reg);
                    middle_op->accessMode = DISASM_ACCESS_READ;

                    DisasmOperand *right_op = disasm->operand + 2;
                    right_op->type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    right_op->immediateValue = imm;
                    right_op->size = 32;
                    right_op->accessMode = DISASM_ACCESS_READ;
                    isPseudoIns = YES;
                    pseudoInsSize = 8;
                }
            }
        }
        if (count > 2) {
            // and $t0, $t0, 0xFFFFFF00 -> lui $at, 0xFFFF; ori $at, 0xFF00; and $t0, $t0, $at
        }
    }

    if (!isPseudoIns) {
        disasm->instruction.pcRegisterValue = disasm->virtualAddr + insn[0].size;
        disasm->instruction.length = 4;

/*
        void *insn_copy = malloc(insn[0].size);
        if (insn_copy) {
            disasm->instruction.userData = (uintptr_t) memcpy(&insn_copy, &insn[0], insn[0].size);
        }
*/

        int op_index;
        for (op_index = 0; op_index < insn[0].detail->mips.op_count; op_index++) {
            cs_mips_op *op = insn[0].detail->mips.operands + op_index;
            DisasmOperand *hop_op = disasm->operand + op_index;

            switch (op->type) {
                case MIPS_OP_IMM:
                    hop_op->type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    hop_op->immediateValue = op->imm;
                    hop_op->size = 16;
                    break;

                case MIPS_OP_REG:
                    hop_op->type = DISASM_OPERAND_REGISTER_TYPE;
                    hop_op->type |= REG_MASK(op->reg);
                    break;

                case MIPS_OP_MEM:
                    hop_op->type = DISASM_OPERAND_MEMORY_TYPE;
                    hop_op->type |= REG_MASK(op->mem.base);
                    hop_op->memory.baseRegistersMask = DISASM_BUILD_REGISTER_INDEX_MASK(capstoneRegisterToRegIndex(op->mem.base));
                    hop_op->memory.displacement = op->mem.disp;
                    break;

                default:
                    hop_op->type = DISASM_OPERAND_OTHER;
                    break;
            }

        }

        strcpy(disasm->instruction.mnemonic, insn->mnemonic);

        if (cs_insn_group(_handle, insn, MIPS_GRP_JUMP)) {
            int lastOperand = insn->detail->mips.op_count - 1;
            cs_mips_op lastOp = insn->detail->mips.operands[lastOperand];
            if (lastOp.type == MIPS_OP_IMM) {
                disasm->instruction.addressValue = (Address) lastOp.imm;
                disasm->operand[lastOperand].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[lastOperand].immediateValue = (Address) lastOp.imm;
                disasm->operand[lastOperand].size = 32;
            } else if (lastOp.type == MIPS_OP_REG) {
                disasm->operand[lastOperand].type = DISASM_OPERAND_REGISTER_TYPE;
                disasm->operand[lastOperand].type |= REG_MASK(lastOp.reg);
            }
            disasm->operand[lastOperand].isBranchDestination = 1;

            // jumps
            // TODO handle branch delay slot
            // Compact branches do not have delay slots.
            // disasm->instruction.pcRegisterValue = disasm->virtualAddr + insn[0].size + insn[1].size;
            switch (insn->id) {
                case MIPS_INS_BNE: //  Branch on Not Equal
                case MIPS_INS_BNEZ: //  Branch on Not Equal to Zero
                    disasm->instruction.condition = DISASM_INST_COND_NE;
                    disasm->instruction.branchType = DISASM_BRANCH_JNE;
                    break;
                case MIPS_INS_BEQ: //  Branch on Equal
                case MIPS_INS_BEQZ: //  Branch on Equal to Zero
                case MIPS_INS_BEQL: //  Branch on Equal Likely
                    disasm->instruction.condition = DISASM_INST_COND_EQ;
                    disasm->instruction.branchType = DISASM_BRANCH_JE;
                    break;
                case MIPS_INS_BGTZ:
                    disasm->instruction.condition = DISASM_INST_COND_GT;
                    disasm->instruction.branchType = DISASM_BRANCH_JNL;
                    break;
                case MIPS_INS_BGEZ:
                    disasm->instruction.condition = DISASM_INST_COND_GE;
                    disasm->instruction.branchType = DISASM_BRANCH_JGE;
                    break;
                case MIPS_INS_BLEZ:
                    disasm->instruction.condition = DISASM_INST_COND_LE;
                    disasm->instruction.branchType = DISASM_BRANCH_JLE;
                    break;
                case MIPS_INS_BLTZ:
                case MIPS_INS_BLTZAL:
                    disasm->instruction.condition = DISASM_INST_COND_LT;
                    disasm->instruction.branchType = DISASM_BRANCH_JL;
                    break;
                case MIPS_INS_JAL:
                case MIPS_INS_JALR:
                case MIPS_INS_BAL:
                    disasm->instruction.condition = DISASM_INST_COND_AL;
                    disasm->instruction.branchType = DISASM_BRANCH_CALL;
                    break;
                case MIPS_INS_JR:
                    disasm->instruction.condition = DISASM_INST_COND_AL;
                    if (insn->detail->mips.operands[0].reg == MIPS_REG_RA) {
                        disasm->instruction.branchType = DISASM_BRANCH_RET;
                    } else {
                        disasm->instruction.branchType = DISASM_BRANCH_JMP;
                    }
                    break;
                case MIPS_INS_BC1F:
                    // TODO
                    break;
                default:
                    disasm->instruction.condition = DISASM_INST_COND_AL;
                    disasm->instruction.branchType = DISASM_BRANCH_JMP;
            }

        } else if (cs_insn_group(_handle, &insn[0], MIPS_GRP_CALL)) {
            int lastOperand = insn[0].detail->mips.op_count;
            cs_mips_op lastOp = insn[0].detail->mips.operands[lastOperand];
            if (lastOp.type == MIPS_OP_IMM) {
                disasm->instruction.addressValue = (Address) lastOp.imm;
                disasm->operand[lastOperand].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[lastOperand].immediateValue = disasm->instruction.addressValue;
            } else if (lastOp.type == MIPS_OP_REG) {
                disasm->operand[lastOperand].type = DISASM_OPERAND_REGISTER_TYPE;
                disasm->operand[lastOperand].type |= REG_MASK(lastOp.reg);
            }
            disasm->operand[lastOperand].isBranchDestination = 1;
            disasm->instruction.branchType = DISASM_BRANCH_CALL;
        } else if (cs_insn_group(_handle, &insn[0], MIPS_GRP_RET) || cs_insn_group(_handle, &insn[0], MIPS_GRP_IRET)) {
            disasm->instruction.condition = DISASM_INST_COND_AL;
            disasm->instruction.branchType = DISASM_BRANCH_RET;
        }

        switch (insn[0].id) {
            case MIPS_INS_ABS: //  Floating Point Absolute Value
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_ADD: //  Add Word
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_ADDU: //  Add Unsigned Word
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_ADDI: //  Add Immediate Word
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                break;
            case MIPS_INS_ADDIU: //  Add Immediate Word Unsigned
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                break;
            case MIPS_INS_ADDIUPC: //  Add Immediate to PC (unsigned - non-trapping)
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 19;
                disasm->operand[2].shiftAmount = 2;
                disasm->operand[2].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_ALIGN: //  Concatenate two GPRs, and extract a contiguous subset at a byte position
                break;
            case MIPS_INS_ALUIPC: //  IAligned Add Upper Immediate to PC
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 16;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_AND: //  and
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_ANDI: //  and immediate
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                break;
            case MIPS_INS_AUI: //  Add Immediate to Upper Bits
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                disasm->operand[2].shiftAmount = 16;
                disasm->operand[2].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_AUIPC: //  Add Upper Immediate to PC
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 16;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_B: //  Unconditional Branch
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].size = 16;
                disasm->operand[0].shiftAmount = 2;
                disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                break;
            case MIPS_INS_BAL: //  Branch and Link
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[0].immediateValue = (Address) insn->detail->mips.operands[0].imm;
                disasm->operand[0].size = 32;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                disasm->instruction.addressValue = (Address) insn->detail->mips.operands[0].imm;
                disasm->instruction.condition = DISASM_INST_COND_AL;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->implicitlyWrittenRegisters[0] |= REG_MASK(MIPS_REG_RA);
                break;
            case MIPS_INS_BALC: //  Branch and Link, Compact
                disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE;
                disasm->operand[0].immediateValue = (Address) insn->detail->mips.operands[0].imm;
                disasm->operand[0].size = 32;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                disasm->instruction.addressValue = (Address) insn->detail->mips.operands[0].imm;
                disasm->instruction.condition = DISASM_INST_COND_AL;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->implicitlyWrittenRegisters[0] |= REG_MASK(MIPS_REG_RA);
                break;
            case MIPS_INS_BC: //  Branch, Compact
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].size = 26;
                disasm->operand[0].shiftAmount = 2;
                disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                disasm->instruction.addressValue = disasm->virtualAddr + 4 + disasm->operand[0].immediateValue;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 4;
                disasm->instruction.condition = DISASM_INST_COND_AL;
                disasm->instruction.branchType = DISASM_BRANCH_CALL;
                disasm->implicitlyWrittenRegisters[0] |= REG_MASK(MIPS_REG_RA);
                break;
            case MIPS_INS_BC1EQZ: //  Branch if Coprocessor 1 (FPU) Register Bit 0 Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                break;
            case MIPS_INS_BC1NEZ: //  Branch if Coprocessor 1 (FPU) Register Bit 0 Not Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_NE;
                disasm->instruction.branchType = DISASM_BRANCH_JNE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                break;
            case MIPS_INS_BC1F: //  Branch on FP False
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC1FL: // Branch on FP False Likely
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC1T: //  Branch on FP True
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC1TL: // Branch on FP True Likely
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC2EQZ: //  Branch if Coprocessor 2 Condition (Register) Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BC2NEZ: //  Branch if Coprocessor 2 Condition (Register) Not Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_NE;
                disasm->instruction.branchType = DISASM_BRANCH_JNE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BC2F: // Branch on COP2 False
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC2FL: // Branch on COP2 False Likely
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC2T: // Branch on COP2 True
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_BC2TL: // Branch on COP2 True Likely
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                if (disasm->operand[1].type == DISASM_OPERAND_NO_OPERAND) {
                    // one operand = offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[0].size = 16;
                    disasm->operand[0].shiftAmount = 2;
                    disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                } else {
                    // two operands = cc, offset
                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                    disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                    disasm->operand[1].size = 16;
                    disasm->operand[1].shiftAmount = 2;
                    disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                }
                break;
            case MIPS_INS_JAL: //  Jump and Link
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[0].size = 26;
                disasm->operand[0].shiftAmount = 2;
                disasm->operand[0].shiftMode = DISASM_SHIFT_LSL;
                disasm->operand[0].isBranchDestination = 1;
                disasm->instruction.addressValue = (Address) disasm->operand[0].immediateValue;
                disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                disasm->implicitlyWrittenRegisters[0] |= REG_MASK(MIPS_REG_RA);
                [_file addPotentialProcedure:(Address) disasm->operand[0].immediateValue];
                break;
            case MIPS_INS_BEQ: //  Branch on Equal
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;

                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                disasm->operand[2].shiftAmount = 2;
                disasm->operand[2].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BEQL: //  Branch on Equal Likely
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;

                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].size = 16;
                disasm->operand[2].shiftAmount = 2;
                disasm->operand[2].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BEQZ: //  Branch on Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BEQC: //  Compact Compare-and-Branch Instructions Equal
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BGEZ: //  Branch on Greater Than or Equal to Zero
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BGEZAL: //  Branch on Greater Than or Equal to Zero and Link
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BNEC: //  Compact Compare-and-Branch Instructions Not Equal
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BLTC: //  Compact Compare-and-Branch Instructions Less Than
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BGEC: //  Compact Compare-and-Branch Instructions Greater or Equal
                disasm->instruction.condition = DISASM_INST_COND_EQ;
                disasm->instruction.branchType = DISASM_BRANCH_JE;
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;

                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].shiftAmount = 2;
                disasm->operand[1].shiftMode = DISASM_SHIFT_LSL;
                break;
            case MIPS_INS_BLTUC: //  Compact Compare-and-Branch Instructions Less Than Unsigned
            case MIPS_INS_BGEUC: //  Compact Compare-and-Branch Instructions Greater or Equal Unsigned
            case MIPS_INS_BNE: //  Branch on Not Equal
            case MIPS_INS_BNEL: //  Branch on Not Equal Likely
            case MIPS_INS_BOVC: //  Branch on Overflow, Compact
            case MIPS_INS_BNVC: //  Branch on No Overflow, Compact
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_JR: //  Jump Register
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->instruction.branchType = DISASM_BRANCH_JMP;
                disasm->instruction.condition = DISASM_INST_COND_AL;
                break;
            case MIPS_INS_LB: //  Load Byte
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_LBU: //  Load Byte Unsigned
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_LW: //  Load Word
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                // is previous instruction a lui into same reg as op2 reg ?
                break;
            case MIPS_INS_LWU: //  Load Word Unsigned
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_SB: //  Store Byte
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
                break;
            case MIPS_INS_SC: //  Store Conditional Word
                // writes operand 0 to memory
                // if memory modified operand 0 is set to 1 else to 0
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
                break;
            case MIPS_INS_SW: //  Store Word
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].size = 16;
                disasm->operand[1].accessMode = DISASM_ACCESS_WRITE;
                break;
            case MIPS_INS_BITSWAP: //  Swaps (reverses) bits in each byte
            case MIPS_INS_LH: //  Load
            case MIPS_INS_LHU: //
            case MIPS_INS_LUI: //
            case MIPS_INS_LL: //
            case MIPS_INS_CEIL: //  Fixed Point Ceiling Convert to Long Fixed Point
            case MIPS_INS_CFC1: //  Move Control Word From Floating Point
                disasm->operand[0].accessMode = DISASM_ACCESS_WRITE;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_BLEZALC: //  Compact Zero-Compare and Branch-and-Link Less Than or Equal to Zero
            case MIPS_INS_BGEZALC: //  Compact Zero-Compare and Branch-and-Link Greater Than or Equal to Zero
            case MIPS_INS_BGTZALC: //  Compact Zero-Compare and Branch-and-Link Greater Than Zero
            case MIPS_INS_BLTZALC: //  Compact Zero-Compare and Branch-and-Link Less Than Zero
            case MIPS_INS_BEQZALC: //  Compact Zero-Compare and Branch-and-Link Equal to Zero
            case MIPS_INS_BNEZALC: //  Compact Zero-Compare and Branch-and-Link Not Equal to Zero
            case MIPS_INS_BGEZALL: //  Branch on Greater Than or Equal to Zero and Link Likely
            case MIPS_INS_BLEZC: //  Compact Compare-and-Branch Instructions Less Than or Equal to Zero
            case MIPS_INS_BLTZC: //  Compact Compare-and-Branch Instructions Less Than Zero
            case MIPS_INS_BGEZC: //  Compact Compare-and-Branch Instructions Greater Than or Equal to Zero
            case MIPS_INS_BGTZC: //  Compact Compare-and-Branch Instructions Greater Than Zero
            case MIPS_INS_BEQZC: //  Compact Compare-and-Branch Instructions Equal to Zero
            case MIPS_INS_BNEZC: //  Compact Compare-and-Branch Instructions Not Equal to Zero
            case MIPS_INS_BGEZL: //  Branch on Greater Than or Equal to Zero Likely
            case MIPS_INS_BGTZ: //  Branch on Greater Than Zero
            case MIPS_INS_BGTZL: //  Branch on Greater Than Zero Likely
            case MIPS_INS_BLEZ: //  Branch on Less Than or Equal to Zero
            case MIPS_INS_BLEZL: //  Branch on Less Than or Equal to Zero Likely
            case MIPS_INS_BLTZ: //  Branch on Less Than Zero
            case MIPS_INS_BLTZL: //  Branch on Less Than Zero Likely
            case MIPS_INS_BLTZALL: //  Branch on Less Than Zero and Link Likely
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                if (disasm->operand[2].type != DISASM_OPERAND_NO_OPERAND) {
                    disasm->operand[2].accessMode = DISASM_ACCESS_READ;
                }
                break;
            case MIPS_INS_CACHE: //  Perform Cache Operation
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                disasm->operand[1].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_SDBBP: //  Software Debug Breakpoint
                disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                break;
            case MIPS_INS_BREAK: //  Breakpoint
                break;
        }


        cs_regs regs_read, regs_write;
        uint8_t read_count, write_count;
        if (cs_regs_access(_handle, &insn[0], regs_read, &read_count, regs_write, &write_count) == 0) {
            // read registers
            if (read_count > 0) {
                for (int reg_nr = 0; reg_nr < read_count && reg_nr < DISASM_MAX_REG_CLASSES; reg_nr++) {
                    disasm->implicitlyReadRegisters[reg_nr] |= REG_MASK(regs_read[reg_nr]);
                }
            }

            // written registers
            if (write_count > 0) {
                for (int reg_nr = 0; reg_nr < write_count && reg_nr < DISASM_MAX_REG_CLASSES; reg_nr++) {
                    disasm->implicitlyWrittenRegisters[reg_nr] |= REG_MASK(regs_write[reg_nr]);
                }
            }
        }
    }
    int len = isPseudoIns ? (int) pseudoInsSize : (int) insn[0].size;
    cs_free(insn, count);

    return len;
}

- (BOOL)instructionHaltsExecutionFlow:(DisasmStruct *)disasm {
    return NO;
}

- (void)performBranchesAnalysis:(DisasmStruct *)disasm
           computingNextAddress:(Address *)next
                    andBranches:(NSMutableArray<NSNumber *> *)branches
                   forProcedure:(NSObject <HPProcedure> *)procedure
                     basicBlock:(NSObject <HPBasicBlock> *)basicBlock
                      ofSegment:(NSObject <HPSegment> *)segment
                calledAddresses:(NSMutableArray<NSNumber *> *)calledAddresses
                      callsites:(NSMutableArray<NSNumber *> *)callSitesAddresses {
/*
    cs_insn *insn = (cs_insn*)disasm->instruction.userData;
    if (insn) {
        switch(insn->id) {
            case MIPS_INS_J:
                *next = BAD_ADDRESS;
                [branches addObject:[NSNumber numberWithUnsignedLongLong:disasm->virtualAddr + (int16_t)insn->detail->mips.operands[0].imm]];
                break;
        }
    }
*/
}

- (void)performInstructionSpecificAnalysis:(DisasmStruct *)disasm
                              forProcedure:(NSObject <HPProcedure> *)procedure
                                 inSegment:(NSObject <HPSegment> *)segment {

}

- (void)performProcedureAnalysis:(NSObject <HPProcedure> *)procedure
                      basicBlock:(NSObject <HPBasicBlock> *)basicBlock
                          disasm:(DisasmStruct *)disasm {

}

- (void)updateProcedureAnalysis:(DisasmStruct *)disasm {

}

// -- Printing
#pragma mark - Printing -

static inline int firstBitIndex(uint64_t mask) {
    for (int i = 0, j = 1; i < 64; i++, j <<= 1) {
        if (mask & j) {
            return i;
        }
    }
    return -1;
}

static inline RegClass regClassFromType(uint64_t type) {
    return (RegClass) firstBitIndex(DISASM_GET_REGISTER_CLS_MASK(type));
}

static inline int regIndexFromType(uint64_t type) {
    return firstBitIndex(DISASM_GET_REGISTER_INDEX_MASK(type));
}

- (NSObject <HPASMLine> *)buildMnemonicString:(DisasmStruct *)disasm
                                       inFile:(NSObject <HPDisassembledFile> *)file {
    NSObject <HPHopperServices> *services = _cpu.hopperServices;
    NSObject <HPASMLine> *line = [services blankASMLine];
    [line appendMnemonic:@(disasm->instruction.mnemonic)];
    return line;
}

- (NSObject <HPASMLine> *)buildOperandString:(DisasmStruct *)disasm
                             forOperandIndex:(NSUInteger)operandIndex
                                      inFile:(NSObject <HPDisassembledFile> *)file
                                         raw:(BOOL)raw {
    if (operandIndex >= DISASM_MAX_OPERANDS) return nil;
    DisasmOperand *operand = disasm->operand + operandIndex;
    if (operand->type == DISASM_OPERAND_NO_OPERAND) return nil;

    // Get the format requested by the user
    ArgFormat format = [file formatForArgument:operandIndex atVirtualAddress:disasm->virtualAddr];

    NSObject <HPHopperServices> *services = _cpu.hopperServices;

    NSObject <HPASMLine> *line = [services blankASMLine];

    if (operand->type & DISASM_OPERAND_CONSTANT_TYPE) {
        if (operand->isBranchDestination) {
            if (format == Format_Default) {
                format = Format_Address;
            }
            [line append:[file formatNumber:disasm->instruction.addressValue
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:32]];
        } else {
            if (format == Format_Default) {
                // small values in decimal
                if (operand->immediateValue > -100 && operand->immediateValue < 100) {
                    format = Format_Decimal;
                }
                if (strncmp(disasm->instruction.mnemonic, "addiu", 5) == 0) {
                    format |= Format_Signed;
                }
            }
            [line appendRawString:@"#"];
            [line append:[file formatNumber:(uint64_t) operand->immediateValue
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:32]];
        }
    } else if (operand->type & DISASM_OPERAND_REGISTER_TYPE) {
        RegClass regCls = regClassFromType(operand->type);
        int regIdx = regIndexFromType(operand->type);
        NSString *reg_name = [_cpu registerIndexToString:regIdx
                                                 ofClass:regCls
                                             withBitSize:32
                                                position:DISASM_LOWPOSITION
                                          andSyntaxIndex:disasm->syntaxIndex];
        [line appendRegister:reg_name
                     ofClass:regCls
                    andIndex:regIdx];

    } else if (operand->type & DISASM_OPERAND_MEMORY_TYPE) {

        if (operand->type & DISASM_OPERAND_REGISTER_INDEX_MASK) {
            RegClass regCls = regClassFromType(operand->type);
            int regIdx = regIndexFromType(operand->type);

            NSString *reg_name = [_cpu registerIndexToString:regIdx
                                                     ofClass:regCls
                                                 withBitSize:32
                                                    position:DISASM_LOWPOSITION
                                              andSyntaxIndex:disasm->syntaxIndex];

            if (format == Format_Default) {
                if ([reg_name isEqualToString:@"sp"]) {
                    format = Format_StackVariable;
                } else {
                    format = Format_Offset;
                }
            }

            if (operand->memory.displacement != 0) {
                BOOL varNameAdded = NO;
                if (format & Format_StackVariable) {
                    NSObject <HPProcedure> *proc = [file procedureAt:disasm->virtualAddr];
                    if (proc) {
                        NSString *varName = [proc resolvedVariableNameForDisplacement:operand->memory.displacement
                                                                      usingCPUContext:self];
                        if (varName) {
                            [line appendVariableName:varName
                                    withDisplacement:operand->memory.displacement];
                            varNameAdded = YES;
                        }
                    }
                }
                if (!varNameAdded) {
                    [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                                 at:disasm->virtualAddr
                                        usingFormat:format
                                         andBitSize:operand->size]];
                }
            }

            [line appendRawString:@"("];
            [line appendRegister:reg_name
                         ofClass:regCls
                        andIndex:regIdx];

            [line appendRawString:@")"];
        } else {
            if (operand->memory.displacement != 0) {
                [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                             at:disasm->virtualAddr
                                    usingFormat:format
                                     andBitSize:operand->size]];
            }
        }
    } else {
        NSString *symbol = [_file nameForVirtualAddress:(Address) operand->memory.displacement];
        if (symbol) {
            [line appendName:symbol atAddress:(Address) operand->memory.displacement];
        } else {
            if (format == Format_Default) format = Format_Address;
            [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:32]];
        }
    }

    [file setFormat:format forArgument:operandIndex atVirtualAddress:disasm->virtualAddr];
    [line setIsOperand:operandIndex startingAtIndex:0];

    return line;
}

- (NSObject <HPASMLine> *)buildCompleteOperandString:(DisasmStruct *)disasm
                                              inFile:(NSObject <HPDisassembledFile> *)file
                                                 raw:(BOOL)raw {
    NSObject <HPHopperServices> *services = _cpu.hopperServices;

    NSObject <HPASMLine> *line = [services blankASMLine];

    for (int op_index = 0; op_index <= DISASM_MAX_OPERANDS; op_index++) {
        NSObject <HPASMLine> *part = [self buildOperandString:disasm
                                              forOperandIndex:op_index
                                                       inFile:file
                                                          raw:raw];
        if (part == nil) break;
        if (op_index) {
            [line appendRawString:@", "];
        }
        [line append:part];
    }

    return line;
}

// Decompiler
#pragma mark - Decompiler -

- (BOOL)canDecompileProcedure:(NSObject <HPProcedure> *)procedure {
    return NO;
}

- (Address)skipHeader:(NSObject <HPBasicBlock> *)basicBlock
          ofProcedure:(NSObject <HPProcedure> *)procedure {
    return basicBlock.from;
}

- (Address)skipFooter:(NSObject <HPBasicBlock> *)basicBlock
          ofProcedure:(NSObject <HPProcedure> *)procedure {
    return basicBlock.to;
}

- (ASTNode *)decompileInstructionAtAddress:(Address)a
                                    disasm:(DisasmStruct *)d
                                 addNode_p:(BOOL *)addNode_p
                           usingDecompiler:(Decompiler *)decompiler {
    return nil;
}

// Assembler
#pragma mark - Assembler -

- (NSData *)assembleRawInstruction:(NSString *)instr
                         atAddress:(Address)addr
                           forFile:(NSObject <HPDisassembledFile> *)file
                       withCPUMode:(uint8_t)cpuMode
                usingSyntaxVariant:(NSUInteger)syntax
                             error:(NSError **)error {
    return nil;
}

- (BOOL)instructionCanBeUsedToExtractDirectMemoryReferences:(DisasmStruct *)disasmStruct {
    return YES;
}

- (BOOL)instructionOnlyLoadsAddress:(DisasmStruct *)disasmStruct {
    // TODO
    return NO;
}

- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasmStruct {
    if (strncmp(disasmStruct->instruction.mnemonic, "jr", 2) == 0) {
        return YES;
    }
    if (strncmp(disasmStruct->instruction.mnemonic, "jalr", 4) == 0) {
        return YES;
    }
    return NO;
}

@end
