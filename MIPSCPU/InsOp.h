//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

@class BitRange;

typedef NS_ENUM(NSUInteger, oper_type) {
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
    OTYPE_IMM24, // signed 24-bit immediate
    OTYPE_OFF9, // signed 9-bit offset
    OTYPE_OFF16, // signed 16-bit offset
    OTYPE_OFF18, // signed 18-bit offset (16-bit offset field shifted left by 2 bits)
    OTYPE_FPU_FMT, // ffmt - format
    OTYPE_FPU_FCC, // fcc - condition code register
    OTYPE_FPU_COND, // fcond - compare condition, eq, le, lt,
    OTYPE_CODE10, // 10-bit code
    OTYPE_CODE20, // 20-bit code
    OTYPE_MEM_BASE, // base of '(base)offset' memory operand
    OTYPE_MEM_INDEX, // index of 'index(base)' memory operand
    OTYPE_COP_MEM_BASE, // base of (base)offset memory operand
    OTYPE_UIMM, // unsigned immediate (length determined by bitcount)
    OTYPE_SIZE, // unsigned immediate - 1
    OTYPE_POSSIZE, // pos + unsigned immediate - 1
    OTYPE_JMP_ADR, // unsigned immediate left shifted by 2 bits
};

@interface InsOp : NSObject {
}
@property NSArray<BitRange *> *bits;
@property oper_type type;
@property NSNumber *pos;
@property DisasmAccessMode accessMode;
@property BOOL isBranchDestination;

- (NSString *)description;

- (uint32_t)valueFromBytes:(uint32_t)bytes;

- (uint8_t)bitCount;

@end
