//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsOp.h"
#import "NSArray+BitRange.h"
#import "BitRange.h"

#if defined(__linux__)
#include <dispatch/dispatch.h>
#endif

@implementation InsOp {
}

static NSString *const bit_range_pattern = @"(\\d+\\.\\.\\d+(?:=(?:0x)?[a-fA-F\\d]+)?)";
static NSString *const bit_value_pattern = @"=(?:(0x)([a-fA-F\\d]+)|(\\d+))";
static NSString *const type_pattern = @":([a-z0-9+]+)";

+ (instancetype)insOpFromString:(NSString *)string {
    InsOp *const insOp = [[self alloc] init];
    insOp.bits = [self bitrangesFromString:string];
    insOp.type = [self getOperandTypeFromString:string];
    insOp.pos = [self getOperandPositionFromString:string];
    insOp.accessMode = [self getAccessModeFromString:string];
    insOp.isBranchDestination = [self getIsBranchDestinationFromString:string];

    return insOp;
}

+ (NSArray<BitRange *> *)bitrangesFromString:(NSString *)string {
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
        NSAssert1(match != nil, @"invalid BitRange format: %@", bitrangeString);
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
        NSAssert1(bitRange != nil, @"invalid BitRange format: %@", substring);
        if (bitRange != nil) {
            [bitRanges addObject:bitRange];
        }
    }
    return bitRanges;
}

+ (InsOpType)getOperandTypeFromString:(NSString *)string {
    NSError *error = nil;
    NSRegularExpression *value_regex = [NSRegularExpression regularExpressionWithPattern:type_pattern
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

+ (InsOpType)typeLookup:(NSString *)string {
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
                @"bp": @(OTYPE_BYTE_POS),
                @"sa": @(OTYPE_UIMM),
                @"sa+1": @(OTYPE_UIMM_PLUS_ONE),
                @"uimm": @(OTYPE_UIMM),
                @"pos": @(OTYPE_UIMM),
                @"size": @(OTYPE_SIZE),
                @"possize": @(OTYPE_POSSIZE),
                @"jmpadr": @(OTYPE_JMP_ADR),
                @"imm16": @(OTYPE_IMM16),
                @"imm16sl16": @(OTYPE_IMM16SL16),
                @"imm19sl2": @(OTYPE_IMM19SL2),
                @"off9": @(OTYPE_OFF9),
                @"off11": @(OTYPE_OFF11),
                @"off16": @(OTYPE_OFF16),
                @"off18": @(OTYPE_OFF18),
                @"off21": @(OTYPE_OFF21),
                @"off23": @(OTYPE_OFF23),
                @"off28": @(OTYPE_OFF28),
                @"ffmt": @(OTYPE_FPU_FMT),
                @"fcc": @(OTYPE_FPU_FCC),
                @"fcond": @(OTYPE_FPU_COND),
                @"fcondn": @(OTYPE_FPU_CONDN),
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
        return (InsOpType) type.integerValue;
    }
    return OTYPE_INVALID;
}

+ (NSNumber *)getValueFromString:(NSString *)string {
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

+ (DisasmAccessMode)getAccessModeFromString:(NSString *)string {
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

+ (NSNumber *)getOperandPositionFromString:(NSString *)string {
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

+ (BOOL)getIsBranchDestinationFromString:(NSString *)string {
    return [string rangeOfString:@"B"].location != NSNotFound;
}


- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.bits=%@", self.bits];
    [description appendFormat:@", self.type=%lu", (unsigned long) self.type];
    [description appendFormat:@", self.pos=%@", self.pos];
    [description appendFormat:@", self.accessMode=%d", self.accessMode];
    [description appendFormat:@", self.isBranchDestination=%d", self.isBranchDestination];
    [description appendString:@">"];
    return description;
}

- (uint32_t)valueFromBytes:(uint32_t)bytes {
    return [self.bits valueFromBytes:bytes];
}

- (uint8_t)bitCount {
    return [self.bits bitCount];
}

@end
