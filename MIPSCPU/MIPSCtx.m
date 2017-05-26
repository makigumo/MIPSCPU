//
// Created by Dan on 2016/12/16.
// Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Hopper/Hopper.h>
#import "MIPSCtx.h"

enum OpType getInsnType(enum Opcode opcode) {
    switch (opcode) {
        case SPECIAL:
        case COP0:
        case COP1:
        case COP2:
            return RTYPE;
        case J:
        case JAL:
            return JTYPE;
        case REGIMM:
        case BEQ:
        case BNE:
        case BLEZ:
        case BGTZ:
        case ADDI:
        case ADDIU:
        case SLTI:
        case SLTIU:
        case ANDI:
        case ORI:
        case XORI:
        case LUI:
        case BEQL:
        case BLEZL:
        case BGTZL:
        case LB:
        case LH:
        case LW:
        case LBU:
        case LHU:
        case SB:
        case SH:
        case SW:
        case SWC1:
        case SWC2:
        case LDC1:
        case LDC2:
        case LWC1:
        case LWC2:
            return ITYPE;
        case SPECIAL2:
            break;
        case SPECIAL3:
            break;
    }
    return INVALID;
}

void getInsn(uint32_t bytes, struct insn *ret) {
    ret->opcode = (enum Opcode) (bytes >> 26);
    ret->type = getInsnType(ret->opcode);
    switch (ret->type) {
        case RTYPE:
            switch (ret->opcode) {
                case SPECIAL:
                    ret->rtype.rs = (enum Reg) ((bytes >> 21) & 0x1f);
                    ret->rtype.rt = (enum Reg) ((bytes >> 16) & 0x1f);
                    ret->rtype.rd = (enum Reg) ((bytes >> 11) & 0x1f);
                    ret->rtype.shift = (uint8_t) ((bytes >> 6) & 0x1f);
                    ret->rtype.specialFunct = (enum SpecialFunct) (bytes & 0x3f);
                    break;
                case COP0:
                case COP1:
                case COP2:
                    ret->rtype.copFunct = (enum CopFunct) ((bytes >> 21) & 0x1f);
                    ret->rtype.rt = (enum Reg) ((bytes >> 16) & 0x1f);
                    ret->rtype.rd = (enum Reg) ((bytes >> 11) & 0x1f);
                    ret->rtype.sel = (uint8_t) (bytes & 0x07);
                    break;
            }
            break;
        case ITYPE:
            ret->itype.rs = (enum Reg) ((bytes >> 21) & 0x1f);
            if (ret->opcode == REGIMM) {
                ret->itype.regImmFunct = (enum RegImmFunct) ((bytes >> 16) & 0x1f);
            } else {
                ret->itype.rt = (enum Reg) ((bytes >> 16) & 0x1f);
            }
            ret->itype.imm = (uint16_t) (bytes & 0xffff);
            ret->delayslot.type = NONE;
            break;
        case JTYPE:
            ret->jtype.rs = (enum Reg) ((bytes >> 21) & 0x1f);
            ret->jtype.imm = (uint32_t) (bytes & 0x07ffffff);
            break;
        default:
            return;
    }
    setDelaySlot(ret);
}

@implementation MIPSCtx {
    MIPSCPU *_cpu;
    NSObject <HPDisassembledFile> *_file;
}

- (instancetype)initWithCPU:(MIPSCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
    }
    return self;
}

- (void)dealloc {
}

- (NSObject <CPUDefinition> *)cpuDefinition {
    return _cpu;
}

static inline void clear_operands_from(DisasmStruct *disasm, int index) {
    for (; index < DISASM_MAX_OPERANDS; index++) {
        disasm->operand[index].type = DISASM_OPERAND_NO_OPERAND;
        disasm->operand[index].isBranchDestination = 0;
    }
}

- (void)initDisasmStructure:(DisasmStruct *)disasm withSyntaxIndex:(NSUInteger)syntaxIndex {
    bzero(disasm, sizeof(DisasmStruct));
    disasm->syntaxIndex = (uint8_t) syntaxIndex;
    disasm->instruction.addressValue = 0;
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

- (int)disassembleSingleInstruction:(DisasmStruct *)disasm usingProcessorMode:(NSUInteger)mode {
    if (disasm->bytes == NULL) return DISASM_UNKNOWN_OPCODE;

    int len = DISASM_UNKNOWN_OPCODE;
    BOOL isPseudoIns = NO;
    size_t pseudoInsSize = 0;
    disasm->instruction.addressValue = 0;
    disasm->instruction.branchType = DISASM_BRANCH_NONE;
    disasm->instruction.pcRegisterValue = disasm->virtualAddr + 4;

    uint32_t bytes = _MyOSReadInt32(disasm->bytes, 0);
    struct insn *in = calloc(1, sizeof(struct insn));
    if (in == NULL) {
        return DISASM_UNKNOWN_OPCODE;
    }
    getInsn(bytes, in);

    if ([_file userRequestedSyntaxIndex] == 1 /* pseudo instructions */) {

    } else {
        switch (in->type) {

            case RTYPE:
                switch (in->opcode) {
                    case SPECIAL:
                        populateRType(disasm, in);
                        break;
                    case COP0: /* System Control Coprocessor */
                        break;
                    case COP1: /* FPU */
                        switch (in->rtype.copFunct) {
                            case MT:
                                strcpy(disasm->instruction.mnemonic, "mtc1");
                                populateRegOperand(&disasm->operand[0], in->rtype.rt, DISASM_ACCESS_WRITE);
                                populateFpuRegOperand(&disasm->operand[1], (enum FpuReg) in->rtype.rd, DISASM_ACCESS_READ);
                                if (in->rtype.sel != 0) {
                                    disasm->operand[2].type = DISASM_OPERAND_CONSTANT_TYPE;
                                    disasm->operand[2].immediateValue = in->rtype.sel;
                                    disasm->operand[2].size = 3;
                                }
                                break;
                            case MTH:
                                strcpy(disasm->instruction.mnemonic, "mthc1");
                                populateRegOperand(&disasm->operand[0], in->rtype.rt, DISASM_ACCESS_WRITE);
                                populateFpuRegOperand(&disasm->operand[1], (enum FpuReg) in->rtype.rd, DISASM_ACCESS_READ);
                                break;
                        }
                        break;
                }
                break;
            case ITYPE:
                switch (in->opcode) {
                    case REGIMM:
                        switch (in->itype.regImmFunct) {
                            case BLTZ:
                                populateITypeRegLabel(disasm, in, "bltz");
                                break;
                            case BGEZ:
                                populateITypeRegLabel(disasm, in, "bgez");
                                break;
                            case BGEZAL:
                                if (in->itype.rs == ZERO) {
                                    strcpy(disasm->instruction.mnemonic, "bal");
                                    disasm->operand[0].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                                    disasm->operand[0].immediateValue = (int16_t) in->itype.imm;
                                    disasm->operand[0].size = 16;
                                    disasm->operand[0].accessMode = DISASM_ACCESS_READ;
                                    disasm->operand[0].isBranchDestination = 1;

                                    disasm->instruction.addressValue =
                                            disasm->virtualAddr + 4 + (disasm->operand[0].immediateValue << 2);
                                    disasm->instruction.pcRegisterValue = disasm->virtualAddr + 8;
                                    disasm->instruction.branchType = DISASM_BRANCH_CALL;
                                } else {
                                    populateITypeRegLabel(disasm, in, "bgezal");
                                }
                                break;
                            case BLTZALL:
                                populateITypeRegLabel(disasm, in, "bltzall");
                                break;
                        }
                        break;
                    case ADDI:
                        populateITypeS(disasm, in, "addi");
                        break;
                    case ADDIU:
                        if (in->itype.rs == ZERO) {
                            populateITypeSZero(disasm, in, "li");
                        } else {
                            populateITypeS(disasm, in, "addiu");
                            [self buildAddress:disasm withInsn:in andOp:BUILDOP_ADD];
                        }
                        break;
                    case ANDI:
                        populateITypeU(disasm, in, "andi");
                        break;
                    case ORI:
                        populateITypeU(disasm, in, "ori");
                        [self buildAddress:disasm withInsn:in andOp:BUILDOP_OR];
                        break;
                    case XORI:
                        populateITypeU(disasm, in, "xori");
                        break;
                    case BEQ:
                        if (in->itype.rt == ZERO) {
                            if (in->itype.rs == ZERO) {
                                populateITypeLabelZeroZero(disasm, in, "b");
                            } else {
                                populateITypeLabelZero(disasm, in, "beqz");
                            }
                        } else {
                            populateITypeLabel(disasm, in, "beq");
                        }
                        disasm->instruction.branchType = DISASM_BRANCH_JE;
                        break;
                    case BNE:
                        if (in->itype.rt == ZERO) {
                            populateITypeLabelZero(disasm, in, "bnez");
                        } else {
                            populateITypeLabel(disasm, in, "bne");
                        }
                        disasm->instruction.branchType = DISASM_BRANCH_JNE;
                        break;
                    case BLEZ:
                        if (in->rtype.rt == ZERO) {
                            populateITypeRegLabel(disasm, in, "blez");
                            disasm->instruction.branchType = DISASM_BRANCH_JLE;
                        }
                        break;
                    case BGTZ:
                        if (in->rtype.rt == ZERO) {
                            populateITypeRegLabel(disasm, in, "bgtz");
                            disasm->instruction.branchType = DISASM_BRANCH_JGE;
                        }
                        break;
                    case SLTI:
                        strcpy(disasm->instruction.mnemonic, "slti");
                        populateRegOperand(&disasm->operand[0], in->itype.rt, DISASM_ACCESS_WRITE);
                        populateRegOperand(&disasm->operand[1], in->itype.rs, DISASM_ACCESS_READ);
                        populateImm16Operand(&disasm->operand[2], in->itype.imm);
                        break;
                    case SLTIU:
                        strcpy(disasm->instruction.mnemonic, "sltiu");
                        populateRegOperand(&disasm->operand[0], in->itype.rt, DISASM_ACCESS_WRITE);
                        populateRegOperand(&disasm->operand[1], in->itype.rs, DISASM_ACCESS_READ);
                        populateUImm16Operand(&disasm->operand[2], in->itype.imm);
                        break;
                    case LUI:
                        populateITypeImm(disasm, in, "lui");
                        break;
                    case BEQL:
                        if (in->itype.rt == ZERO) {
                            populateITypeLabelZero(disasm, in, "beqzl");
                        } else {
                            populateITypeLabel(disasm, in, "beql");
                        }
                        break;
                    case BLEZL:
                        if (in->rtype.rt == ZERO) {
                            populateITypeRegLabel(disasm, in, "blezl");
                            disasm->instruction.branchType = DISASM_BRANCH_JGE;
                        }
                        break;
                    case BGTZL:
                        if (in->rtype.rt == ZERO) {
                            populateITypeRegLabel(disasm, in, "bgtzl");
                            disasm->instruction.branchType = DISASM_BRANCH_JGE;
                        }
                        break;
                    case LB:
                        populateITypeMemRead(disasm, in, "lb");
                        break;
                    case LH:
                        populateITypeMemRead(disasm, in, "lh");
                        break;
                    case LW:
                        populateITypeMemRead(disasm, in, "lw");
                        [self buildAddress:disasm withInsn:in andOp:BUILDOP_ADD];
                        break;
                    case LBU:
                        populateITypeMemRead(disasm, in, "lbu");
                        break;
                    case LHU:
                        populateITypeMemRead(disasm, in, "lhu");
                        break;
                    case SB:
                        populateITypeMemWrite(disasm, in, "sb");
                        break;
                    case SH:
                        populateITypeMemWrite(disasm, in, "sh");
                        break;
                    case SW:
                        populateITypeMemWrite(disasm, in, "sw");
                        break;
                    case LWC1:
                        populateFPUITypeMemRead(disasm, in, "lwc1");
                        break;
                    case LWC2:
                        populateFPUITypeMemRead(disasm, in, "lwc2");
                        break;
                    case LDC1:
                        populateFPUITypeMemRead(disasm, in, "ldc1");
                        break;
                    case LDC2:
                        populateFPUITypeMemRead(disasm, in, "ldc2");
                        break;
                    case SWC1:
                        populateFPUITypeMemWrite(disasm, in, "swc1");
                        break;
                    case SWC2:
                        populateFPUITypeMemWrite(disasm, in, "swc2");
                        break;
                }
                break;
            case JTYPE:
                switch (in->opcode) {
                    case J:
                    case JAL:
                        populateJType(disasm, in);
                        break;
                }
                break;
        }
    }

    if (in->delayslot.type != NONE) {
        disasm->instruction.pcRegisterValue += 4;
    } else {

    }

    free(in);
    if (disasm->instruction.mnemonic[0] == 0) {
        return DISASM_UNKNOWN_OPCODE;
    }
    return 4;
}

/**
 * Build an address from lui, addiu or lui, ori instructions
 *
 * @param disasm current DisasmStruct
 * @param in current instruction
 */
- (void)buildAddress:(DisasmStruct *)disasm
            withInsn:(const struct insn *)in
               andOp:(const enum BuildOp)op {
    // fetch previous instruction
    uint32_t prev = [_file readUInt32AtVirtualAddress:disasm->virtualAddr - 4];
    struct insn *prevIn = calloc(1, sizeof(struct insn));
    getInsn(prev, prevIn);
    if (prevIn && prevIn->opcode == LUI &&
            prevIn->itype.rt == in->itype.rs) {

        disasm->instruction.addressValue = (op == BUILDOP_ADD) ?
                (uint32_t) ((prevIn->itype.imm << 16) + ((int16_t) in->itype.imm)) :
                (uint32_t) ((prevIn->itype.imm << 16) | in->itype.imm);
        NSObject <HPSegment> *segment = [_file segmentForVirtualAddress:disasm->virtualAddr];
        [segment addReferencesToAddress:(uint32_t) disasm->instruction.addressValue
                            fromAddress:disasm->virtualAddr];
        free(prevIn);
    }
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

static inline int firstBitIndex(const uint64_t mask) {
    for (int i = 0, j = 1; i < 64; i++, j <<= 1) {
        if (mask & j) {
            return i;
        }
    }
    return -1;
}

static inline RegClass regClassFromType(const uint64_t type) {
    return (RegClass) firstBitIndex(DISASM_GET_REGISTER_CLS_MASK(type));
}

static inline int regIndexFromType(const uint64_t type) {
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
                } else {
                    format = Format_Hexadecimal;
                }
                if (operand->type & DISASM_OPERAND_RELATIVE) {
                    format |= Format_Signed;
                }
            }
            [line appendRawString:@"#"];
            [line append:[file formatNumber:(uint64_t) operand->immediateValue
                                         at:disasm->virtualAddr
                                usingFormat:format
                                 andBitSize:operand->size]];
        }
    } else if (operand->type & DISASM_OPERAND_REGISTER_TYPE) {
        RegClass regCls = regClassFromType(operand->type);
        int regIdx = regIndexFromType(operand->type);
        NSString *reg_name = [_cpu registerIndexToString:regIdx
                                                 ofClass:regCls
                                             withBitSize:32
                                                position:operand->position
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
                                                    position:operand->position
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

    for (unsigned int op_index = 0; op_index <= DISASM_MAX_OPERANDS; op_index++) {
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
    return NO;
}

@end
