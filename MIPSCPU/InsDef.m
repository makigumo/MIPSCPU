//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsDef.h"
#import "NSArray+BitRange.h"
#import "BitRange.h"

#if defined(__linux__)
#include <dispatch/dispatch.h>
#endif

@class BitRange;

@interface InsDef ()
- (void)parseFormat;
@end

@implementation InsDef {
}

NSString *bit_range_pattern = @"(\\d+\\.\\.\\d+(?:=(?:0x)?[a-fA-F\\d]+)?)";
NSString *bit_value_pattern = @"=(?:(0x)([a-fA-F\\d]+)|(\\d+))";

- (instancetype)initWithMnemonic:(NSString *)aMnemonic
                         release:(isa_release)aRelease
                          format:(NSString *)aFormat {
    self = [super init];
    if (self) {
        self._release = aRelease;
        self.mnemonic = aMnemonic;
        self.format = aFormat;
        [self parseFormat];
        NSAssert2(![self bitRangesIntersect], @"bitRanges intersect %@ %@", aMnemonic, aFormat);
    }
    return self;
}

+ (instancetype)defWithMnemonic:(NSString *)aMnemonic
                        release:(isa_release)aRelease
                         format:(NSString *)aFormat {
    return [[self alloc] initWithMnemonic:aMnemonic
                                  release:aRelease
                                   format:aFormat];
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
    return ((self._release & isa1) == isa1) && ((bytes & self.mask) == self.match);
}

- (NSArray<InsOp *> *)operands {
    return [[_op_parts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(InsOp *object, NSDictionary *bindings) {
        oper_type type = object.type;
        return type != OTYPE_UNDEFINED && type != OTYPE_INVALID && type != OTYPE_IGNORED;
    }]] sortedArrayUsingComparator:^NSComparisonResult(InsOp *a, InsOp *b) {
        if (a.pos == nil || b.pos == nil) {
            return NSOrderedSame;
        }
        NSNumber *first = a.pos;
        NSNumber *second = b.pos;
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
            InsOp *insOp = [InsOp alloc];
            insOp.bits = [self bitrangesFromString:comp];
            insOp.type = [self getOperandTypeFromString:comp];
            if (insOp.type == OTYPE_INVALID) {
                NSLog(@"invalid type: in %@ for op %@ in format: %@", self.mnemonic, comp, self.format);
            }
            NSAssert3(insOp.type != OTYPE_INVALID, @"invalid type: in %@ for op %@ in format: %@", self.mnemonic, comp, self.format);
            insOp.pos = [self getOperandPositionFromString:comp];
            insOp.accessMode = [self getAccessModeFromString:comp];
            insOp.isBranchDestination = [self getIsBranchDestinationFromString:comp];

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

- (NSNumber *)getOperandPositionFromString:(NSString *)string {
    NSError *error = nil;
    NSRegularExpression *value_regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\d+)"
                                                                                 options:0
                                                                                   error:&error];
    NSTextCheckingResult *match = [value_regex firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, [string length])];
    if (match == nil) {
        return nil;
    }
    NSString *value = [string substringWithRange:[match rangeAtIndex:1]];

    return @([value intValue]);
}

- (NSArray<BitRange *> *)bitrangesFromString:(NSString *)string {
    NSArray<NSString *> *bitrangeArray = [string componentsSeparatedByString:@","];
    NSMutableArray<BitRange *> *bitRanges = [[NSMutableArray alloc] init];
    for (NSString *bitrangeString in bitrangeArray) {

        NSError *error = nil;
        NSRegularExpression *bit_range_regex = [NSRegularExpression regularExpressionWithPattern:bit_range_pattern
                                                                                         options:0
                                                                                           error:&error];
        NSTextCheckingResult *match = [bit_range_regex firstMatchInString:bitrangeString
                                                                  options:0
                                                                    range:NSMakeRange(0, [bitrangeString length])];
        NSAssert2(match != nil, @"invalid BitRange format: %@ in %@", bitrangeString, self.format);
        NSRange range = [match rangeAtIndex:1];
        if (range.location == NSNotFound) {
            continue;
        }
        NSString *substring = [bitrangeString substringWithRange:range];
        NSArray<NSString *> *bits = [substring componentsSeparatedByString:@".."];
        uint8_t first = (uint8_t) bits[0].intValue;
        uint8_t last = (uint8_t) bits[1].intValue;
        NSNumber *number = [self getValueFromString:substring];
        BitRange *bitRange = [BitRange range32WithFirst:first last:last value:number];
        NSAssert2(bitRange != nil, @"invalid BitRange format: %@ in %@", substring, self.format);
        if (bitRange != nil) {
            [bitRanges addObject:bitRange];
        }
    }
    return bitRanges;
}

- (NSNumber *)getValueFromString:(NSString *)string {
    NSError *error = nil;
    NSRegularExpression *value_regex = [NSRegularExpression regularExpressionWithPattern:bit_value_pattern
                                                                                 options:0
                                                                                   error:&error];
    NSTextCheckingResult *match = [value_regex firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, [string length])];
    if (match == nil) {
        return nil;
    }
    if (/* 0x */ [match rangeAtIndex:1].location != NSNotFound &&
            /* hex value */ [match rangeAtIndex:2].location != NSNotFound) {
        NSString *range = [string substringWithRange:[match rangeAtIndex:2]];
        return @(strtoul([range UTF8String], NULL, 16));
    }
    return @(/* decimal value */[string substringWithRange:[match rangeAtIndex:3]].integerValue);
}

- (oper_type)typeLookup:(NSString *)string {
    static NSDictionary<NSString *, NSNumber *> *types;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = @{
                @"rd": @(OTYPE_REG_DEST),
                @"rt": @(OTYPE_REG_TEMP),
                @"rs": @(OTYPE_REG_SOURCE),
                @"fd": @(OTYPE_FPU_REG_DEST),
                @"ft": @(OTYPE_FPU_REG_TEMP),
                @"fs": @(OTYPE_FPU_REG_SOURCE),
                @"fr": @(OTYPE_FPU_REG_R),
                @"hwrd": @(OTYPE_HW_REG_DEST),
                @"coprd": @(OTYPE_COP_REG_DEST),
                @"coprt": @(OTYPE_COP_REG_TEMP),
                @"coprs": @(OTYPE_COP_REG_SOURCE),
                @"sa": @(OTYPE_UIMM),
                @"uimm": @(OTYPE_UIMM),
                @"pos": @(OTYPE_UIMM),
                @"size": @(OTYPE_SIZE),
                @"possize": @(OTYPE_POSSIZE),
                @"jmpadr": @(OTYPE_JMP_ADR),
                @"imm16": @(OTYPE_IMM16),
                @"imm24": @(OTYPE_IMM24),
                @"off16": @(OTYPE_OFF16),
                @"off9": @(OTYPE_OFF9),
                @"off18": @(OTYPE_OFF18),
                @"ffmt": @(OTYPE_FPU_FMT),
                @"fcc": @(OTYPE_FPU_FCC),
                @"fcond": @(OTYPE_FPU_COND),
                @"code10": @(OTYPE_CODE10),
                @"code20": @(OTYPE_CODE20),
                @"base": @(OTYPE_MEM_BASE),
                @"index": @(OTYPE_MEM_INDEX),
                @"copbase": @(OTYPE_COP_MEM_BASE),
                @"op": @(OTYPE_UIMM),
                @"ignored": @(OTYPE_IGNORED),
        };
    });
    NSNumber *const type = types[string];
    if (type) {
        return (oper_type) type.integerValue;
    }
    return OTYPE_INVALID;
}

- (oper_type)getOperandTypeFromString:(NSString *)string {
    NSError *error = nil;
    NSRegularExpression *value_regex = [NSRegularExpression regularExpressionWithPattern:@":([a-z0-9]+)"
                                                                                 options:0
                                                                                   error:&error];
    NSTextCheckingResult *match = [value_regex firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, [string length])];
    if (match == nil) {
        return OTYPE_UNDEFINED;
    }
    NSString *value = [string substringWithRange:[match rangeAtIndex:1]];
    return [self typeLookup:value];
}

- (DisasmAccessMode)getAccessModeFromString:(NSString *)string {
    NSError *error = nil;
    NSRegularExpression *value_regex = [NSRegularExpression regularExpressionWithPattern:@"(rw|wr|r|w)$"
                                                                                 options:0
                                                                                   error:&error];
    NSTextCheckingResult *match = [value_regex firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, [string length])];
    if (match == nil) {
        return DISASM_ACCESS_NONE;
    }
    NSString *value = [string substringWithRange:[match rangeAtIndex:1]];
    if ([value isEqualToString:@"rw"] || [value isEqualToString:@"wr"]) {
        return DISASM_ACCESS_READ | DISASM_ACCESS_WRITE;
    }
    if ([value isEqualToString:@"r"]) {
        return DISASM_ACCESS_READ;
    }
    if ([value isEqualToString:@"w"]) {
        return DISASM_ACCESS_WRITE;
    }
    return DISASM_ACCESS_NONE;
}

- (BOOL)getIsBranchDestinationFromString:(NSString *)string {
    return [string rangeOfString:@"B"].location != NSNotFound;
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
