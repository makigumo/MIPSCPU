//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

@class BitRange;

typedef NS_ENUM(NSUInteger, InsOpType) {
    OTYPE_UNDEFINED,
    OTYPE_INVALID,
    OTYPE_IGNORED,
    OTYPE_REG_DEST, // rd
    OTYPE_REG_TEMP, // rt
    OTYPE_REG_SOURCE, // rs
    OTYPE_HW_REG_DEST, // hardware register rd
    OTYPE_COP_REG_DEST, // COP2 rd
    OTYPE_COP_REG_TEMP, // COP2 rt
    OTYPE_COP_REG_SOURCE, // COP2 rs
    OTYPE_FPU_REG_DEST, // fd
    OTYPE_FPU_REG_TEMP, // ft
    OTYPE_FPU_REG_SOURCE, // fs
    OTYPE_FPU_REG_R, // fr
    OTYPE_IMM16, // signed 16-bit immediate
    OTYPE_IMM16SL16, // signed 16-bit immediate (shifted left by 16 bits)
    OTYPE_IMM19SL2, // signed 19-bit immediate (shifted left by 2 bits)
    OTYPE_OFF9, // signed 9-bit offset
    OTYPE_OFF11, // signed 11-bit offset
    OTYPE_OFF16, // signed 16-bit offset
    OTYPE_OFF18, // signed 18-bit offset (16-bit offset field shifted left by 2 bits)
    OTYPE_OFF18SL3, // sign extended 18-bit offset field shifted left by 3 bits
    OTYPE_OFF21, // signed 21-bit offset (19-bit offset field shifted left by 2 bits)
    OTYPE_OFF23, // signed 23-bit offset (21-bit offset field shifted left by 2 bits)
    OTYPE_OFF28, // signed 28-bit offset (26-bit offset field shifted left by 2 bits)
    OTYPE_FPU_FMT, // ffmt - format
    OTYPE_FPU_FCC, // fcc - condition code register
    OTYPE_FPU_COND, // fcond - compare condition, eq, le, lt,
    OTYPE_FPU_CONDN, // fcondn MIPS32R6
    OTYPE_CODE10, // 10-bit code
    OTYPE_CODE20, // 20-bit code
    OTYPE_MEM_BASE, // base of '(base)offset' memory operand
    OTYPE_MEM_INDEX, // index of 'index(base)' memory operand
    OTYPE_COP_MEM_BASE, // base of (base)offset memory operand
    OTYPE_UIMM, // unsigned immediate (length determined by bitcount)
    OTYPE_UIMM_PLUS_ONE, // unsigned immediate (length determined by bitcount) + 1
    OTYPE_SIZE, // unsigned immediate - 1
    OTYPE_MSBDMINUS32, // size (unsigned immediate) - 1 - 32
    OTYPE_LSBMINUS32, // pos (unsigned immediate) - 32
    OTYPE_MSBMINUS32, // pos + unsigned immediate - 1 - 32
    OTYPE_POSSIZE, // pos + unsigned immediate - 1
    OTYPE_JMP_ADR, // unsigned immediate left shifted by 2 bits
    OTYPE_BYTE_POS, // 2-bit or 3-bit byte position
};

@interface InsOp : NSObject {
}
@property NSArray<BitRange *> *bits;
@property InsOpType type;
@property NSNumber *pos;
@property DisasmAccessMode accessMode;
@property BOOL isBranchDestination;


+ (instancetype)insOpFromString:(NSString *)string;

+ (NSArray<BitRange *> *)bitrangesFromString:(NSString *)string;

+ (InsOpType)getOperandTypeFromString:(NSString *)string;

+ (InsOpType)typeLookup:(NSString *)string;

+ (NSNumber *)getValueFromString:(NSString *)string;

+ (DisasmAccessMode)getAccessModeFromString:(NSString *)string;

+ (NSNumber *)getOperandPositionFromString:(NSString *)string;

+ (BOOL)getIsBranchDestinationFromString:(NSString *)string;

- (NSString *)description;

- (uint32_t)valueFromBytes:(uint32_t)bytes;

- (uint8_t)bitCount;

@end
