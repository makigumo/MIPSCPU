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
    MIPS64 = 1 << 5,
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

- (uint8_t)instructionLength;

@end
