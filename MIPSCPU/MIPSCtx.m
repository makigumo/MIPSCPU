//
// Created by Dan on 2016/12/16.
// Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Hopper/Hopper.h>
#import <Hopper/DisasmStruct.h>
#import "MIPSCtx.h"
#import "NSArray+BitRange.h"
#import "Insn.h"

#if defined(__linux__)
#include <dispatch/dispatch.h>
#endif

@implementation MIPSCtx {
    MIPSCPU *_cpu;
    NSObject <HPDisassembledFile> *_file;
};

+ (NSArray<NSString *> *const)condStrings {
    static NSArray<NSString *> *_condStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _condStrings = @[
                @"f",
                @"un",
                @"eq",
                @"ueq",
                @"olt",
                @"ult",
                @"ole",
                @"ule",
                @"sf",
                @"ngle",
                @"seq",
                @"ngl",
                @"lt",
                @"nge",
                @"le",
                @"ngt",
        ];
    });
    return _condStrings;
}

+ (NSArray<NSString *> *const)condR6Strings {
    static NSArray<NSString *> *_condStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _condStrings = @[
                @"af",
                @"un",
                @"eq",
                @"ueq",
                @"lt",
                @"ult",
                @"le",
                @"ule",

                @"saf",
                @"sun",
                @"seq",
                @"sueq",
                @"slt",
                @"sult",
                @"sle",
                @"sule",

                @"at",
                @"or",
                @"une",
                @"ne",
                @"uge",
                @"oge",
                @"ugt",
                @"ogt",

                @"sat",
                @"sor",
                @"sune",
                @"sne",
                @"suge",
                @"soge",
                @"sugt",
                @"sogt",
        ];
    });
    return _condStrings;
}

+ (NSDictionary<NSString *, NSNumber *> *const)isaReleases {
    static NSDictionary<NSString *, NSNumber *> *_releases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _releases = @{
                @"MIPS32": @(MIPS32),
                @"MIPS32R2": @(MIPS32R2),
                @"MIPS32R3": @(MIPS32R3),
                @"MIPS32R5": @(MIPS32R5),
                @"MIPS32R6": @(MIPS32R6),
                @"MIPSI": @(MIPS_I),
                @"MIPSII": @(MIPS_II),
                @"MIPSIII": @(MIPS_III),
                @"MIPSIV": @(MIPS_IV),
                @"MIPS64": @(MIPS64),
                @"MIPS64R2": @(MIPS64R2),
                @"MIPS64R3": @(MIPS64R3),
                @"MIPS64R5": @(MIPS64R5),
                @"MIPS64R6": @(MIPS64R6),
                @"EJTAG": @(EJTAG), // CPU in debug mode
        };
    });
    return _releases;
}

+ (NSDictionary<NSString *, NSNumber *> *const)branchTypes {
    static NSDictionary<NSString *, NSNumber *> *branchTypeLookup;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branchTypeLookup = @{
                @"ALWAYS": @(DISASM_BRANCH_JMP),
                @"EQUAL_ZERO": @(DISASM_BRANCH_JECXZ),
                @"GREATER_EQUAL": @(DISASM_BRANCH_JGE),
                @"GREATER_EQUAL_ZERO": @(DISASM_BRANCH_JGE),
                @"GREATER_ZERO": @(DISASM_BRANCH_JG),
                @"LESS_EQUAL_ZERO": @(DISASM_BRANCH_JLE),
                @"LESS": @(DISASM_BRANCH_JL),
                @"LESS_ZERO": @(DISASM_BRANCH_JL),
                @"EQUAL": @(DISASM_BRANCH_JE),
                @"NOT_EQUAL": @(DISASM_BRANCH_JNE),
                @"NOT_EQUAL_ZERO": @(DISASM_BRANCH_JNE),
                @"OVERFLOW": @(DISASM_BRANCH_JO),
                @"NO_OVERFLOW": @(DISASM_BRANCH_JNO),
                @"CALL": @(DISASM_BRANCH_CALL),
                @"RET": @(DISASM_BRANCH_RET),
                @"FALSE": @(DISASM_BRANCH_JNE),
                @"TRUE": @(DISASM_BRANCH_JE),
        };
    });
    return branchTypeLookup;
}

- (instancetype)initWithCPU:(MIPSCPU *)cpu
                    andFile:(NSObject <HPDisassembledFile> *)file {
    if (self = [super init]) {
        _cpu = cpu;
        _file = file;
        if ([_file.cpuFamily isEqualToString:@"mipsel"]) {
            self.cpuEndianess = CPUEndianess_Little;
        } else if ([_file.cpuFamily isEqualToString:@"mipseb"]) {
            self.cpuEndianess = CPUEndianess_Big;
        }
        if ([_file.cpuSubFamily isEqualToString:@"mips32r2"]) {
            self.isaRelease = MIPS32R2;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips32r5"]) {
            self.isaRelease = MIPS32R5;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips32r6"]) {
            self.isaRelease = MIPS32R6;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips I"]) {
            self.isaRelease = MIPS_I;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips II"]) {
            self.isaRelease = MIPS_II;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips III"]) {
            self.isaRelease = MIPS_III;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips IV"]) {
            self.isaRelease = MIPS_IV;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips64"]) {
            self.isaRelease = MIPS64;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips64r2"]) {
            self.isaRelease = MIPS64R2;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips64r3"]) {
            self.isaRelease = MIPS64R3;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips64r5"]) {
            self.isaRelease = MIPS64R5;
        } else if ([_file.cpuSubFamily isEqualToString:@"mips64r6"]) {
            self.isaRelease = MIPS64R6;
        } else {
            self.isaRelease = MIPS32;
        }
    }
    return self;
}

- (NSArray<InsDef *> *const)getInstructions {
    static NSArray<InsDef *> *instructions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *const opcodesPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"opcodes" ofType:@"plist"];
        NSArray<NSDictionary *> *const opcodes = [NSArray arrayWithContentsOfFile:opcodesPath];
        NSMutableArray *const _instructions = [NSMutableArray arrayWithCapacity:opcodes.count];
        for (NSDictionary *const opDict in opcodes) {
            NSString *const key = [opDict valueForKey:@"mnemonic"];
            NSAssert1(key != nil, @"missing key 'mnemonic' in %@", opDict);
            isa_release __release = (isa_release) 0;
            NSArray<NSString *> *const releases = (NSArray<NSString *> *) [opDict valueForKey:@"release"];
            NSAssert1(releases != nil, @"missing key 'release' in %@", opDict);
            NSAssert1(releases.count > 0, @"no releases specified in %@", opDict);
            for (NSString *const r in releases) {
                NSNumber *const type = [MIPSCtx isaReleases][r];
                NSAssert1(type != nil, @"unknown isa release: %@", r);
                __release |= type.integerValue;
            }
            NSString *const format = opDict[@"format"];
            NSAssert1(format != nil, @"missing key 'format' in %@", opDict);
            NSArray<NSString *> *const conditions = opDict[@"condition"];
            InsDef *const insDef = [InsDef defWithMnemonic:key
                                                   release:__release
                                                    format:format
                                                conditions:conditions];
            NSString *const branchtype = [opDict valueForKey:@"branchtype"];
            insDef.branchType = [MIPSCtx branchTypes][branchtype];
            if (branchtype && !insDef.branchType) {
                NSLog(@"unknown `branchtype' in %@", opDict);
            }
            NSAssert1(branchtype == nil || (branchtype && insDef.branchType), @"unknown `branchtype' in %@", opDict);
            [_instructions addObject:insDef];
        }
        // order instructions by mask bit count
        instructions = [_instructions sortedArrayUsingComparator:^NSComparisonResult(InsDef *const a, InsDef *const b) {
            return [@([b numberOfMaskBitsSet]) compare:@([a numberOfMaskBitsSet])];
        }];
    });
    return instructions;
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
    return (word == 0x0 /* nop */ || word == 0x25082000 /* move at,at (loongson)*/) ? 4 : 0;
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
    int pseudoInsSize = 0;
    disasm->instruction.addressValue = 0;
    disasm->instruction.branchType = DISASM_BRANCH_NONE;
    disasm->instruction.pcRegisterValue = disasm->virtualAddr + 4;

    uint32_t bytes = (self.cpuEndianess == CPUEndianess_Little) ?
            disasm->bytes[0] | disasm->bytes[1] << 8 | disasm->bytes[2] << 16 | disasm->bytes[3] << 24 :
            disasm->bytes[3] | disasm->bytes[2] << 8 | disasm->bytes[1] << 16 | disasm->bytes[0] << 24;

    Insn *const insn = [self getInsnForBytes:bytes];
    if (insn) {
        NSArray<InsOp *> *const operands = insn.insDef.operands;
        strcpy(disasm->instruction.mnemonic, [insn.mnemonic UTF8String]);
        [operands enumerateObjectsUsingBlock:^(InsOp *operand, NSUInteger idx, BOOL *stop) {
            const uint32_t operandValue = [insn operandValue:idx].unsignedIntValue;
            switch (operand.type) {

                case OTYPE_UNDEFINED:
                    break;
                case OTYPE_INVALID:
                    break;
                case OTYPE_IGNORED:
                    break;
                case OTYPE_REG_DEST:
                case OTYPE_REG_TEMP:
                case OTYPE_REG_SOURCE:
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[idx].type |= getRegMask((enum Reg) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_HW_REG_DEST:
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[idx].type |= getHwRegMask((uint8_t) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_COP_REG_DEST:
                case OTYPE_COP_REG_TEMP:
                case OTYPE_COP_REG_SOURCE:
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[idx].type |= getCopRegMask((uint8_t) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_FPU_REG_DEST:
                case OTYPE_FPU_REG_TEMP:
                case OTYPE_FPU_REG_SOURCE:
                case OTYPE_FPU_REG_R:
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[idx].type |= getFpuRegMask((enum FpuReg) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_BYTE_POS:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = [operand bitCount];
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_IMM16:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = 16;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_IMM16SL16:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = 16;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    disasm->instruction.addressValue = (Address) disasm->virtualAddr + (
                            (int32_t) (operandValue << 13) >> 11);
                    break;
                case OTYPE_IMM19SL2:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = operandValue << 2;
                    disasm->operand[idx].size = 19;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    disasm->instruction.addressValue = (Address) disasm->virtualAddr + 4 + (
                            (int32_t) (operandValue << 13) >> 11);
                    break;
                case OTYPE_OFF9:
                    if (idx > 0 && operands[idx - 1].type == OTYPE_MEM_BASE) {
                        disasm->operand[idx - 1].type |= DISASM_OPERAND_RELATIVE;
                        disasm->operand[idx - 1].size = 9;
                        disasm->operand[idx - 1].memory.displacement =
                                (int16_t) (operandValue << 7) >> 7;
                    }
                    break;
                case OTYPE_OFF11:
                    if (idx > 0 && operands[idx - 1].type == OTYPE_MEM_BASE) {
                        disasm->operand[idx - 1].type |= DISASM_OPERAND_RELATIVE;
                        disasm->operand[idx - 1].size = 11;
                        disasm->operand[idx - 1].memory.displacement =
                                (int16_t) (operandValue << 5) >> 5;
                    }
                    break;
                case OTYPE_OFF16:
                    if (idx > 0 && operands[idx - 1].type == OTYPE_MEM_BASE) {
                        disasm->operand[idx - 1].type |= DISASM_OPERAND_RELATIVE;
                        disasm->operand[idx - 1].size = 16;
                        disasm->operand[idx - 1].memory.displacement = (int16_t) operandValue;
                    } else {
                        disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                        disasm->operand[idx].immediateValue = operandValue;
                        disasm->operand[idx].size = 16;
                        disasm->operand[idx].accessMode = operand.accessMode;
                    }
                    break;
                case OTYPE_OFF18:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    const int16_t int16 = (int16_t) operandValue;
                    disasm->operand[idx].immediateValue = disasm->virtualAddr + 4 + (int16 << 2);
                    disasm->operand[idx].size = 32;
                    disasm->instruction.addressValue = disasm->virtualAddr + 4 + (int16 << 2);
                    if (operand.isBranchDestination) {
                        disasm->operand[idx].isBranchDestination = 1;
                    }
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_OFF18SL3: //memory[ (PC&~0x7) + sign_extend( offset << 3) ]
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = ((int32_t) (operandValue << 14)) >> 11;
                    disasm->operand[idx].size = 21;
                    disasm->instruction.addressValue = (Address) (disasm->virtualAddr & ~0x7) + (
                            ((int32_t) (operandValue << 14)) >> 11);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_OFF21:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue =
                            disasm->virtualAddr + (((int32_t) (operandValue << 13)) >> 11);
                    disasm->operand[idx].size = 21;
                    disasm->instruction.addressValue = (Address) (disasm->virtualAddr +
                            ((int32_t) (operandValue << 13) >> 11));
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_OFF23:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = ((int32_t) (operandValue << 11)) >> 9;
                    disasm->operand[idx].size = 23;
                    disasm->instruction.addressValue = (Address) (disasm->virtualAddr + 4) +
                            (((int32_t) (operandValue << 11) >> 9));
                    if (operand.isBranchDestination) {
                        disasm->operand[idx].isBranchDestination = 1;
                    }
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_OFF28:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue = ((int32_t) (operandValue << 6)) >> 4;
                    disasm->operand[idx].size = 28;
                    disasm->instruction.addressValue = (Address) (disasm->virtualAddr + 4) +
                            (((int32_t) (operandValue << 6) >> 4));
                    if (operand.isBranchDestination) {
                        disasm->operand[idx].isBranchDestination = 1;
                    }
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_FPU_FMT:
                    break;
                case OTYPE_FPU_FCC:
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE;
                    disasm->operand[idx].type |= getFccRegMask((uint8_t) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_FPU_COND: {
                    uint32_t cond_index = operandValue;
                    NSString *const condString = [MIPSCtx condStrings][cond_index];
                    const char *const mnemonicCString = [[NSString stringWithFormat:insn.mnemonic, condString] UTF8String];
                    strcpy(disasm->instruction.mnemonic, mnemonicCString);
                }
                case OTYPE_FPU_CONDN: {
                    uint32_t cond_index = operandValue;
                    NSString *const condString = [MIPSCtx condR6Strings][cond_index];
                    const char *const mnemonicCString = [[NSString stringWithFormat:insn.mnemonic, condString] UTF8String];
                    strcpy(disasm->instruction.mnemonic, mnemonicCString);
                }
                    break;
                case OTYPE_CODE10:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = 10;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_CODE20:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = 20;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_MEM_BASE:
                    if (idx > 0 &&
                            (disasm->operand[idx - 1].type & DISASM_OPERAND_REGISTER_INDEX)) {
                        // index(base)
                        disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_REGISTER_BASE;
                        disasm->operand[idx].type |= getRegMask((enum Reg) operandValue);
                        disasm->operand[idx].accessMode = operand.accessMode;
                    } else {
                        // offset(base)
                        disasm->operand[idx].type = DISASM_OPERAND_MEMORY_TYPE;
                        disasm->operand[idx].type |= getRegMask((enum Reg) operandValue);
                        disasm->operand[idx].memory.baseRegistersMask = getRegMask((enum Reg) operandValue);
                    }
                    break;
                case OTYPE_COP_MEM_BASE: // index(base)
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_REGISTER_BASE;
                    disasm->operand[idx].type |= getCopRegMask((uint8_t) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_MEM_INDEX: // index(base)
                    // TODO use indexRegistersMask
                    //if (operands.count - 1 > idx) {
                    //    disasm->operand[idx - 1].memory.indexRegistersMask = getRegMask((enum Reg) [operand.bits valueFromBytes:bytes]);
                    //} else {
                    disasm->operand[idx].type = DISASM_OPERAND_REGISTER_TYPE | DISASM_OPERAND_REGISTER_INDEX;
                    disasm->operand[idx].type |= getRegMask((enum Reg) operandValue);
                    disasm->operand[idx].accessMode = operand.accessMode;
                    //}
                    break;
                case OTYPE_UIMM:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue;
                    disasm->operand[idx].size = [operand bitCount];
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_UIMM_PLUS_ONE:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue + 1;
                    disasm->operand[idx].size = [operand bitCount] + 1;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_SIZE:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue + 1;
                    disasm->operand[idx].size = [operand bitCount] + 1;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_MSBDMINUS32:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue + 1 + 32;
                    disasm->operand[idx].size = [operand bitCount] + 1;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_LSBMINUS32:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                    disasm->operand[idx].immediateValue = operandValue + 32;
                    disasm->operand[idx].size = [operand bitCount] + 1;
                    disasm->operand[idx].accessMode = operand.accessMode;
                    break;
                case OTYPE_POSSIZE:
                    if (idx > 0) {
                        uint8_t pos = (uint8_t) [insn operandValue:idx - 1].unsignedIntValue;
                        disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                        disasm->operand[idx].immediateValue = operandValue - pos + 1;
                        disasm->operand[idx].size = [operand bitCount] + 1;
                        disasm->operand[idx].accessMode = operand.accessMode;
                    }
                    break;
                case OTYPE_MSBMINUS32:
                    if (idx > 0) {
                        uint8_t pos = (uint8_t) [insn operandValue:idx - 1].unsignedIntValue;
                        disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE;
                        disasm->operand[idx].immediateValue = operandValue - pos + 1 + 32;
                        disasm->operand[idx].size = [operand bitCount] + 1;
                        disasm->operand[idx].accessMode = operand.accessMode;
                    }
                    break;
                case OTYPE_JMP_ADR:
                    disasm->operand[idx].type = DISASM_OPERAND_CONSTANT_TYPE | DISASM_OPERAND_RELATIVE;
                    disasm->operand[idx].immediateValue =
                            (int32_t) (operandValue << 6) >> 6;
                    disasm->operand[idx].size = [operand bitCount];
                    disasm->operand[idx].accessMode = operand.accessMode;
                    disasm->operand[idx].isBranchDestination = 1;
                    // target address is a full 32-bit address consisting of
                    // * highest 4 bits of PC (instruction after jump)
                    // * 2-bit left shifted 26-bit immediate
                    disasm->instruction.addressValue = ((disasm->virtualAddr + 4) & 0xff000000)
                            + (disasm->operand[idx].immediateValue << 2);

                    break;
            }
        }];
        disasm->instruction.pcRegisterValue = disasm->virtualAddr + [insn.insDef lengthInBytes];
        disasm->instruction.length = [insn.insDef lengthInBytes];
        if (insn.insDef.branchType) {
            disasm->instruction.branchType = (DisasmBranchType) insn.insDef.branchType.integerValue;
        }
        if ([insn.mnemonic isEqualToString:@"addiu"] ||
                [insn.mnemonic isEqualToString:@"lw"]) {
            [self calculateAddress:disasm withInsn:insn andOp:BUILDOP_ADD];
        }
        if ([insn.mnemonic isEqualToString:@"ori"]) {
            [self calculateAddress:disasm withInsn:insn andOp:BUILDOP_OR];
        }

        len = [insn.insDef lengthInBytes];
    }


    if (disasm->instruction.mnemonic[0] == 0) {
        return DISASM_UNKNOWN_OPCODE;
    }
    if (isPseudoIns) {
        return pseudoInsSize;
    }
    return len;
}

/**
 * Calculate an address from lui, addiu or lui, ori instructions
 *
 * @param disasm current DisasmStruct
 * @param in current instruction
 * @param op how to calculate the address
 */

- (void)calculateAddress:(DisasmStruct *)disasm
                withInsn:(const Insn *)in
                   andOp:(const enum BuildOp)op {
    const uint8_t STEPS_BACK = 2;
    for (int stepBack = 1; stepBack <= STEPS_BACK; stepBack++) {
        // fetch previous instruction
        Insn *prevIn = [self getInsnAtAddress:disasm->virtualAddr - ([in.insDef lengthInBytes] * stepBack)];
        if (prevIn) {
            if ([self calculateAddress:disasm withPrev:prevIn andInsDef:in andOp:op]) {
                break;
            }
        }
    }
}


/**
 * Calculate an address from lui, addiu or lui, ori instructions
 *
 * @param disasm current DisasmStruct
 * @param prev a previous instruction
 * @param in current instruction
 * @param op how to calculate the address
 */

- (BOOL)calculateAddress:(DisasmStruct *)disasm
                withPrev:(const Insn *)prev
               andInsDef:(const Insn *)in
                   andOp:(const enum BuildOp)op {
    if ([prev.mnemonic isEqualToString:@"lui"]) {
        NSNumber *in_reg = [in operandValue:1];
        if (!in_reg) {
            return NO;
        }
        NSNumber *prev_reg = [prev operandValue:0];
        if (!prev_reg) {
            return NO;
        }
        if ([in_reg unsignedIntValue] != [prev_reg unsignedIntValue]) {
            return NO;
        }
        const unsigned int prev_imm = [prev operandValue:1].unsignedIntValue;
        const unsigned int in_imm = [in operandValue:2].unsignedIntValue;
        disasm->instruction.addressValue = (op == BUILDOP_ADD) ?
                (uint32_t) ((prev_imm << 16) + ((int16_t) in_imm)) :
                (uint32_t) ((prev_imm << 16) | in_imm);
        NSObject <HPSegment> *segment = [_file segmentForVirtualAddress:disasm->virtualAddr];
        [segment addReferencesToAddress:(uint32_t) disasm->instruction.addressValue
                            fromAddress:disasm->virtualAddr];
        NSString *comment = [NSString stringWithFormat:@"%@ = %08x",
                                                       [self getRegNameFromOperand:disasm->operand
                                                                    andSyntaxIndex:disasm->syntaxIndex],
                                                       (uint32_t) disasm->instruction.addressValue];
        [_file setInlineComment:comment
               atVirtualAddress:disasm->virtualAddr
                         reason:CCReason_Automatic];
        return YES;
    }
    return NO;
}

- (Insn *const)getInsnAtAddress:(Address)address {
    return [self getInsnForBytes:[_file readUInt32AtVirtualAddress:address]];
}

- (Insn *const)getInsnForBytes:(uint32_t)bytes {
    for (InsDef *const ins_def in [self getInstructions]) {
        if ([ins_def matches:bytes isa:self.isaRelease]) {
            return [Insn insnWithInsDef:ins_def bytes:bytes];
        }
    }
    return nil;
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
                calledAddresses:(NSMutableArray<NSObject <HPCallDestination> *> *)calledAddresses
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

- (NSString *)getRegNameFromOperand:(DisasmOperand *)operand
                     andSyntaxIndex:(NSUInteger)syntaxIndex {
    RegClass regCls = regClassFromType(operand->type);
    int regIdx = regIndexFromType(operand->type);
    if (regIdx < 0) {
        return @"invalid_reg";
    }
    return [_cpu registerIndexToString:(NSUInteger) regIdx
                               ofClass:regCls
                           withBitSize:32
                              position:operand->position
                        andSyntaxIndex:syntaxIndex];
}

- (NSObject <HPASMLine> *)buildMnemonicString:(DisasmStruct *)disasm
                                       inFile:(NSObject <HPDisassembledFile> *)file {
    NSObject <HPHopperServices> *services = _cpu.hopperServices;
    NSObject <HPASMLine> *line = [services blankASMLine];
    const BOOL isJump = (disasm->instruction.branchType != DISASM_BRANCH_NONE);
    [line appendMnemonic:@(disasm->instruction.mnemonic) isJump:isJump];
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
            //[line appendRawString:@"#"];
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

            BOOL varNameAdded = NO;
            if ([reg_name isEqualToString:@"sp"]) {
                if (((format & Format_Default) == Format_Default) || (format & Format_StackVariable)) {
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
            }

            if (operand->type & DISASM_OPERAND_RELATIVE) {
                format |= Format_Signed;
            }
            if (!varNameAdded) {
                [line append:[file formatNumber:(uint64_t) operand->memory.displacement
                                             at:disasm->virtualAddr
                                    usingFormat:format
                                     andBitSize:operand->size]];
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
        NSString *symbol = [_file nameForVirtualAddress:(Address) operand->immediateValue];
        if (symbol) {
            [line appendName:symbol atAddress:(Address) operand->immediateValue];
        } else {
            if (format == Format_Default) format = Format_Address;
            [line append:[file formatNumber:(uint64_t) operand->immediateValue
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
            // index(base)
            if ((disasm->operand[op_index].type & DISASM_OPERAND_REGISTER_BASE) &&
                    (disasm->operand[op_index - 1].type & DISASM_OPERAND_REGISTER_INDEX)) {
                [line appendRawString:@"("];
                [line append:part];
                [line appendRawString:@")"];

            } else {
                [line appendRawString:@", "];
                [line append:part];
            }
        } else {
            [line append:part];
        }
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

- (BOOL)instructionManipulatesFloat:(DisasmStruct *)disasmStruct {
    return NO;
}

- (BOOL)instructionConditionsCPUModeAtTargetAddress:(DisasmStruct *)disasmStruct
                                      resultCPUMode:(uint8_t *)cpuMode {
    return NO;
}

- (uint8_t)cpuModeForNextInstruction:(DisasmStruct *)disasmStruct {
    return 0;
}

- (BOOL)instructionMayBeASwitchStatement:(DisasmStruct *)disasmStruct {
    return NO;
}

// Helper functions
#pragma mark - Helper functions -

@end
