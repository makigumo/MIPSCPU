//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsOp.h"
#import "NSArray+BitRange.h"
#import "BitRange.h"
#import "NSString+MIPSHelper.h"

#if defined(__linux__)
#include <dispatch/dispatch.h>
#endif

@implementation InsOp {
}

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
    const NSArray<NSString *> *bitrangeArray = [string componentsSeparatedByString:@","];
    const NSMutableArray<BitRange *> *bitRanges = [[NSMutableArray alloc] init];
    for (NSString *const bitrangeString in bitrangeArray) {
        const NSArray<NSString *> *bits = [bitrangeString componentsSeparatedByString:@".."];
        NSAssert2([bits count] == 2, @"invalid bitrange: '%@' in '%@'", bitrangeString, string);
        NSAssert2([bits[0] length] > 0, @"invalid bitrange start: %@ in %@", bits[0], bitrangeString);
        NSAssert2([bits[0] isDigitAtIndex:0], @"invalid bitrange start: %@ in %@", bits[0], bitrangeString);
        const uint8_t first = (uint8_t) bits[0].intValue;
        NSAssert2([bits[1] length] > 0, @"invalid bitrange end: %@ in %@", bits[1], bitrangeString);
        NSAssert2([bits[1] isDigitAtIndex:0], @"invalid bitrange end: %@ in %@", bits[1], bitrangeString);
        const uint8_t last = (uint8_t) bits[1].intValue;
        NSNumber *const number = [self getValueFromString:bitrangeString];
        BitRange *const bitRange = [BitRange range32WithFirst:first last:last value:number];
        NSAssert1(bitRange != nil, @"invalid BitRange format: %@", bitrangeString);
        if (bitRange != nil) {
            [bitRanges addObject:bitRange];
        }
    }
    return [bitRanges copy];
}

+ (InsOpType)getOperandTypeFromString:(NSString *)string {
    const NSRange range = [string rangeOfString:@":"];
    if (range.location == NSNotFound) {
        return OTYPE_UNDEFINED;
    }
    NSString *const opTypeString = [string substringFromIndex:range.location];
    if ([opTypeString length] == 0) {
        return OTYPE_UNDEFINED;
    } else if ([opTypeString characterAtIndex:0] != ':') {
        return OTYPE_UNDEFINED;
    }
    NSString *const value = [opTypeString substringFromIndex:1];
    const NSRange opTypeRange = [value rangeOfTypeString];
    if (opTypeRange.location == NSNotFound) {
        return OTYPE_INVALID;
    }
    NSString *typeValue = [value substringWithRange:opTypeRange];
    return [self typeLookup:typeValue];
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
                @"lsb": @(OTYPE_UIMM),
                @"lsbminus32": @(OTYPE_LSBMINUS32),
                @"size": @(OTYPE_SIZE),
                @"msb": @(OTYPE_POSSIZE),
                @"msbd": @(OTYPE_SIZE),
                @"msbdminus32": @(OTYPE_MSBDMINUS32),
                @"msbminus32": @(OTYPE_MSBMINUS32),
                @"possize": @(OTYPE_POSSIZE),
                @"jmpadr": @(OTYPE_JMP_ADR),
                @"imm16": @(OTYPE_IMM16),
                @"imm16sl16": @(OTYPE_IMM16SL16),
                @"imm19sl2": @(OTYPE_IMM19SL2),
                @"off9": @(OTYPE_OFF9),
                @"off11": @(OTYPE_OFF11),
                @"off16": @(OTYPE_OFF16),
                @"off18": @(OTYPE_OFF18),
                @"off18sl3": @(OTYPE_OFF18SL3),
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
    const NSRange range = [string rangeOfString:@"="];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *const valueString = [string substringFromIndex:range.location];
    if (/* hex value */ [valueString hasPrefix:@"=0x"]) {
        if ([valueString length] > 3 && [valueString isHexAtIndex:3]) {
            NSString *const hexString = [valueString substringFromIndex:3];
            return @(strtoul([hexString UTF8String], NULL, 16));
        } else {
            return nil;
        }
    }
    if ([valueString length] > 1) {
        return @(/* decimal value */[valueString substringFromIndex:1].integerValue);
    }
    return nil;
}

+ (DisasmAccessMode)getAccessModeFromString:(NSString *)string {
    DisasmAccessMode accessMode = DISASM_ACCESS_NONE;
    if ([string length] == 0) {
        return accessMode;
    }
    if ([string characterAtIndex:[string length] - 1] == 'r') {
        accessMode = DISASM_ACCESS_READ;
        if ([string length] > 1 && [string characterAtIndex:[string length] - 2] == 'w') {
            accessMode |= DISASM_ACCESS_WRITE;
        }
    }
    if ([string characterAtIndex:[string length] - 1] == 'w') {
        accessMode = DISASM_ACCESS_WRITE;
        if ([string length] > 1 && [string characterAtIndex:[string length] - 2] == 'r') {
            accessMode |= DISASM_ACCESS_READ;
        }
    }
    return accessMode;
}

+ (NSNumber *)getOperandPositionFromString:(NSString *)string {
    const NSRange range = [string rangeOfString:@"#"];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *const opPosString = [string substringFromIndex:range.location];
    if (![opPosString isOpIndexAtIndex:0]) {
        return nil;
    }
    return @([[opPosString substringFromIndex:1] intValue]);
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
