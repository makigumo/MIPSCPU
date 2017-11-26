//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InsOp.h"

@class InsOp;
@class BitRange;
@class InsCond;
@class InsCond;

typedef NS_ENUM(NSUInteger, isa_release) {
    MIPS32 = 1 << 0,
    MIPS32R2 = 1 << 1,
    MIPS32R3 = 1 << 2,
    MIPS32R5 = 1 << 3,
    MIPS32R6 = 1 << 4,
    MIPS_I = 1 << 5,
    MIPS_II = 1 << 6,
    MIPS_III = 1 << 7,
    MIPS_IV = 1 << 8,
    MIPS64 = 1 << 9,
    MIPS64R2 = 1 << 10,
    MIPS64R3 = 1 << 11,
    MIPS64R5 = 1 << 12,
    MIPS64R6 = 1 << 13,
    EJTAG = 1 << 14,
};

@interface InsDef : NSObject {
    NSArray<InsOp *> *_op_parts;
}

@property uint32_t mask;
@property uint32_t match;
@property isa_release _release;
@property NSNumber *branchType;
@property NSString *mnemonic;
/**
 * bits a..b,c..d(=value)
 * type (reg, fpureg, imm16, uimm16)
 */
@property NSString *format;
@property NSArray<InsCond *> *conditions;

- (instancetype)initWithMnemonic:(NSString *)aMnemonic
                         release:(isa_release)aRelease
                          format:(NSString *)aFormat
                      conditions:(NSArray<NSString *> *)conditionStrings;

+ (instancetype)defWithMnemonic:(NSString *)aMnemonic
                        release:(isa_release)aRelease
                         format:(NSString *)format;

+ (instancetype)defWithMnemonic:(NSString *)aMnemonic
                        release:(isa_release)aRelease
                         format:(NSString *)aFormat
                     conditions:(NSArray<NSString *> *)conditionStrings;

- (BOOL)matches:(uint32_t)bytes isa:(isa_release)isa;

- (NSArray<InsOp *> *)operands;

- (uint32_t)numberOfMaskBitsSet;

- (NSString *)description;

- (uint8_t)lengthInBytes;

- (uint8_t)length;
@end
