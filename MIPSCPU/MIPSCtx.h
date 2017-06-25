//
// Created by Dan on 2016/12/16.
// Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>
#include "MIPSCPU.h"
#import "InsDef.h"

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

// custom types: left most 16 bits, see DISASM_OPERAND_TYPE_MASK
#define DISASM_OPERAND_REGISTER_BASE    0x0001000000000000llu
#define DISASM_OPERAND_REGISTER_INDEX   0x0002000000000000llu

#define REG_MASK(cls, reg) \
    (DISASM_BUILD_REGISTER_CLS_MASK(cls) | DISASM_BUILD_REGISTER_INDEX_MASK(reg))

static inline DisasmOperandType getRegMask(enum Reg reg) {
    return REG_MASK(RegClass_GeneralPurposeRegister, reg);
}

static inline DisasmOperandType getFpuRegMask(enum FpuReg reg) {
    return REG_MASK(RegClass_MIPS_FPU, reg);
}

static inline DisasmOperandType getCopRegMask(uint8_t reg) {
    return REG_MASK(RegClass_MIPS_COP, reg);
}

static inline DisasmOperandType getHwRegMask(uint8_t reg) {
    return REG_MASK(RegClass_MIPS_HW, reg);
}

static inline DisasmOperandType getFccRegMask(uint8_t reg) {
    return REG_MASK(RegClass_MIPS_FCC, reg);
}

static inline uint32_t _MyOSReadInt32(const volatile void *base, uintptr_t byteOffset) {
    return *(volatile uint32_t *) ((uintptr_t) base + byteOffset);
}

@interface MIPSCtx : NSObject <CPUContext>

typedef enum BuildOp {
    BUILDOP_ADD,
    BUILDOP_OR,
} BuildOpEnum;

@property isa_release isaRelease;

- (instancetype)initWithCPU:(MIPSCPU *)cpu andFile:(NSObject <HPDisassembledFile> *)file;

- (NSArray<InsDef *> *const)getInstructions;
@end
