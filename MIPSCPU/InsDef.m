//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsDef.h"
#import "NSArray+BitRange.h"
#import "NSArray+InsCond.h"
#import "InsCond.h"

#if defined(__linux__)
#include <dispatch/dispatch.h>
#endif

@class BitRange;

@interface InsDef ()
- (void)parseFormat;
@end

@implementation InsDef {
}

- (instancetype)initWithMnemonic:(NSString *)aMnemonic
                         release:(isa_release)aRelease
                          format:(NSString *)aFormat
                      conditions:(NSArray<NSString *> *)conditionStrings {
    self = [super init];
    if (self) {
        self._release = aRelease;
        self.mnemonic = aMnemonic;
        self.format = aFormat;
        [self parseFormat];
        if (conditionStrings) {
            NSMutableArray *conds = [NSMutableArray arrayWithCapacity:conditionStrings.count];
            for (NSString *const condString in conditionStrings) {
                [conds addObject:[InsCond condWith:condString andOps:_op_parts]];
            }
            self.conditions = conds;
        } else {
            self.conditions = @[];
        }
        NSAssert2(![self bitRangesIntersect], @"bitRanges intersect %@ %@", aMnemonic, aFormat);
    }
    return self;
}

+ (instancetype)defWithMnemonic:(NSString *)aMnemonic
                        release:(isa_release)aRelease
                         format:(NSString *)aFormat {
    return [[self alloc] initWithMnemonic:aMnemonic
                                  release:aRelease
                                   format:aFormat
                               conditions:nil];
}

+ (instancetype)defWithMnemonic:(NSString *)aMnemonic
                        release:(isa_release)aRelease
                         format:(NSString *)aFormat
                     conditions:(NSArray<NSString *> *)conditionStrings {
    return [[self alloc] initWithMnemonic:aMnemonic
                                  release:aRelease
                                   format:aFormat
                               conditions:conditionStrings];
}

- (NSArray<NSValue *> *)rangesFromBitRanges {
    NSMutableArray<NSValue *> *res = [NSMutableArray array];
    NSArray<InsOp *> *const insOpArray = _op_parts;
    for (NSUInteger idx = 0; idx < insOpArray.count; idx++) {
        [res addObjectsFromArray:[insOpArray[idx].bits getRanges]];
    }
    return res;
}

- (BOOL)bitRangesIntersect {
    NSArray<NSValue *> *const rangesArray = [self rangesFromBitRanges];
    for (NSUInteger idx = 0; idx < rangesArray.count; idx++) {
        const NSRange range = rangesArray[idx].rangeValue;
        for (NSUInteger i = idx + 1; i < rangesArray.count; ++i) {
            const NSRange next = rangesArray[i].rangeValue;
            if (NSIntersectionRange(range, next).length > 0) {
                NSLog(@"bit ranges intersect %@, %@", self.mnemonic, self.format);
                return YES;
            }
        }
    };
    return NO;
}

- (BOOL)matches:(uint32_t)bytes isa:(isa_release)isa1 {
    return ((self._release & isa1) == isa1) &&
            ((bytes & self.mask) == self.match) &&
            [self.conditions satisfiedWith:bytes];
}

- (NSArray<InsOp *> *)operands {
    return [[_op_parts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(InsOp *object, NSDictionary *bindings) {
        InsOpType type = object.type;
        return type != OTYPE_UNDEFINED && type != OTYPE_INVALID && type != OTYPE_IGNORED && object.pos;
    }]] sortedArrayUsingComparator:^NSComparisonResult(InsOp *a, InsOp *b) {
        if (a.pos == nil || b.pos == nil) {
            return NSOrderedSame;
        }
        NSNumber *first = a.pos;
        NSNumber *second = b.pos;
        NSAssert2(a.pos != b.pos, @"same position value in %@: %@", self.mnemonic, self.format);
        return [first compare:second];
    }];
}

- (uint32_t)numberOfMaskBitsSet {
    uint32_t i = self.mask;
    __asm__(
    "popcnt %0, %0  \n\t"
    : "+r" (i)
    );
    return i;
}

- (void)parseFormat {
    if ([self.format length] != 0) {
        self.mask = 0;
        self.match = 0;
        NSMutableArray<InsOp *> *ret = [[NSMutableArray alloc] init];
        NSArray<NSString *> *compArray = [self.format componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        for (NSString *comp in compArray) {
            InsOp *insOp = [InsOp insOpFromString:comp];
            if (insOp.type == OTYPE_INVALID) {
                NSLog(@"invalid type: in %@ for op %@ in format: %@", self.mnemonic, comp, self.format);
            }
            NSAssert3(insOp.type != OTYPE_INVALID, @"invalid type: in %@ for op %@ in format: %@", self.mnemonic, comp, self.format);

            // all parts with values build the mask
            if ([insOp.bits value]) {
                self.mask |= [insOp.bits asMask];
                self.match |= [insOp.bits asMatch];
            }

            [ret addObject:insOp];
        }
        _op_parts = ret;
    } else {
        _op_parts = @[];
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_op_parts=%@", _op_parts];
    [description appendFormat:@", self.mask=%u", self.mask];
    [description appendFormat:@", self.match=%u", self.match];
    [description appendFormat:@", self._release=%lu", (unsigned long) self._release];
    [description appendFormat:@", self.mnemonic=%@", self.mnemonic];
    [description appendFormat:@", self.format=%@", self.format];
    [description appendString:@">"];
    return description;
}

- (uint8_t)instructionLength {
    uint8_t len = 0;
    for (InsOp *iop in _op_parts) len += iop.bits.bitCount;
    return (uint8_t) (len / 8);
}

@end
