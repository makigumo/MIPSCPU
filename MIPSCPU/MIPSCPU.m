//
//  MIPSCPU.m
//  MIPSCPU
//
//  Created by Makigumo on 10/11/2016.
//  Copyright (c) 2016 Makigumo. All rights reserved.
//

#import "MIPSCPU.h"
#import "MIPSCtx.h"
#import "MIPSCSCtx.h"

@implementation MIPSCPU {
    NSObject <HPHopperServices> *_services;
}

- (instancetype)initWithHopperServices:(NSObject <HPHopperServices> *)services {
    if (self = [super init]) {
        _services = services;
    }
    return self;
}

- (NSObject <HPHopperServices> *)hopperServices {
    return _services;
}

- (Class)cpuContextClass {
    return [MIPSCtx class];
}

- (NSObject <CPUContext> *)buildCPUContextForFile:(NSObject <HPDisassembledFile> *)file {
    if ([file.cpuFamily isEqualToString:@"mips"]) {
        if ([file.cpuSubFamily isEqualToString:@"mips32"] ||
                [file.cpuSubFamily isEqualToString:@"mips32r2"] ||
                [file.cpuSubFamily isEqualToString:@"mips32r5"] ||
                [file.cpuSubFamily isEqualToString:@"mips32r6"]) {
            MIPSCtx *mipsCtx = [[MIPSCtx alloc] initWithCPU:self andFile:file];
            return mipsCtx;
        }
    }
    return [[MIPSCSCtx alloc] initWithCPU:self andFile:file];
}

- (HopperUUID *)pluginUUID {
    return [_services UUIDWithString:@"6fc51517-1dbe-4761-989c-905cb83ad096"];
}

- (HopperPluginType)pluginType {
    return Plugin_CPU;
}

- (NSString *)pluginName {
    return @"MIPS";
}

- (NSString *)pluginDescription {
    return @"MIPS CPU support";
}

- (NSString *)pluginAuthor {
    return @"Makigumo";
}

- (NSString *)pluginCopyright {
    return @"©2016-2017 - Makigumo";
}

- (NSArray<NSString *> *)cpuFamilies {
    return @[
            @"mips",
            @"mips (capstone)",
    ];
}

- (NSString *)pluginVersion {
    return @"0.1.0";
}

- (NSArray<NSString *> *)cpuSubFamiliesForFamily:(NSString *)family {
    if ([family isEqualToString:@"mips (capstone)"])
        return @[
                @"mips32",
                //@"mipsIII",
                //@"microMIPS",
                //@"micro32r6",
                //@"mips64"
        ];
    if ([family isEqualToString:@"mips"]) {
        return @[
                @"mips32",
                @"mips32r2",
                @"mips32r5",
                //@"mips32r6",
        ];
    }
    return nil;
}

- (int)addressSpaceWidthInBitsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    if ([family isEqualToString:@"mips (capstone)"]) {
        if ([subFamily isEqualToString:@"mips32"]) return 32;
        if ([subFamily isEqualToString:@"mipsIII"]) return 32;
        if ([subFamily isEqualToString:@"microMIPS"]) return 32;
        if ([subFamily isEqualToString:@"micro32r6"]) return 32;
        //if ([subFamily isEqualToString:@"mips64"]) return 64;
    }
    if ([family isEqualToString:@"mips"]) {
        if ([subFamily isEqualToString:@"mips32"]) return 32;
        if ([subFamily isEqualToString:@"mips32r2"]) return 32;
        if ([subFamily isEqualToString:@"mips32r5"]) return 32;
        if ([subFamily isEqualToString:@"mips32r6"]) return 32;
    }
    return 0;
}

- (CPUEndianess)endianess {
    return CPUEndianess_Little;
}

- (NSUInteger)syntaxVariantCount {
    return 2;
}

- (NSUInteger)cpuModeCount {
    return 1;
}

- (NSArray<NSString *> *)syntaxVariantNames {
    return @[@"generic", @"pseudo instructions"];
}

- (NSArray<NSString *> *)cpuModeNames {
    return @[@"generic"];
}

- (NSString *)framePointerRegisterNameForFile:(NSObject <HPDisassembledFile> *)file {
    return @"gp";
}

- (NSUInteger)registerClassCount {
    return RegClass_MIPS_Cnt;
}

- (NSUInteger)registerCountForClass:(RegClass)reg_class {
    switch (reg_class) {
        case RegClass_GeneralPurposeRegister:
            return 32;
        case (RegClass) RegClass_MIPS_FPU:
            return 32;
        case (RegClass) RegClass_MIPS_HW:
            return 32;
        case (RegClass) RegClass_MIPS_ACC:
            return 4;
        case (RegClass) RegClass_MIPS_COP:
            return 32;
        case (RegClass) RegClass_MIPS_FCC:
        case (RegClass) RegClass_MIPS_DSP:
            return 8;
        case (RegClass) RegClass_MIPS_P:
        case (RegClass) RegClass_MIPS_MPL:
            return 3;
        default:
            break;
    }
    return 0;
}

- (BOOL)registerIndexIsStackPointer:(NSUInteger)reg ofClass:(RegClass)reg_class {
    return reg_class == RegClass_GeneralPurposeRegister && reg == 29;
}

- (BOOL)registerIndexIsFrameBasePointer:(NSUInteger)reg ofClass:(RegClass)reg_class {
    return reg_class == RegClass_GeneralPurposeRegister && reg == 30;
}

- (BOOL)registerIndexIsProgramCounter:(NSUInteger)reg {
    return reg == 1;
}

- (NSString *)registerIndexToString:(NSUInteger)reg
                            ofClass:(RegClass)reg_class
                        withBitSize:(NSUInteger)size
                           position:(DisasmPosition)position
                     andSyntaxIndex:(NSUInteger)syntaxIndex {
    switch (reg_class) {
        case (RegClass) RegClass_MIPS_ACC:
            return [NSString stringWithFormat:@"acc%d", (int) reg];
        case (RegClass) RegClass_MIPS_FCC:
            return [NSString stringWithFormat:@"fcc%d", (int) reg];
        case (RegClass) RegClass_MIPS_COP:
            return [NSString stringWithFormat:@"$%d", (int) reg];
        case (RegClass) RegClass_MIPS_HW:
            return [NSString stringWithFormat:@"$%d", (int) reg];
        case (RegClass) RegClass_MIPS_MPL:
            return [NSString stringWithFormat:@"mpl%d", (int) reg];
        case (RegClass) RegClass_MIPS_P:
            return [NSString stringWithFormat:@"p%d", (int) reg];

        case RegClass_GeneralPurposeRegister:
            if (reg < 32) {
                static NSString *names[] = {
                        @"zero", @"at", @"v0", @"v1",
                        @"a0", @"a1", @"a2", @"a3",
                        @"t0", @"t1", @"t2", @"t3",
                        @"t4", @"t5", @"t6", @"t7",
                        @"s0", @"s1", @"s2", @"s3",
                        @"s4", @"s5", @"s6", @"s7",
                        @"t8", @"t9", @"k0", @"k1",
                        @"gp", @"sp", @"fp", @"ra",
                };
                return names[reg];
            }
            return [NSString stringWithFormat:@"UNKNOWN_REG<%lld>", (long long) reg];
        case (RegClass) RegClass_MIPS_FPU:
            return [NSString stringWithFormat:@"$f%d", (int) reg];
        case (RegClass) RegClass_MIPS_DSP:
            return [NSString stringWithFormat:@"dsp%d", (int) reg];
        case (RegClass) -1:
            break;
        default:
            return [NSString stringWithFormat:@"class%d_reg%d", (int) reg_class, (int) reg];;
    }
    return nil;
}

- (NSString *)cpuRegisterStateMaskToString:(uint32_t)cpuState {
    return @"";
}

- (NSData *)nopWithSize:(NSUInteger)size
                andMode:(NSUInteger)cpuMode
                forFile:(NSObject <HPDisassembledFile> *)file {
    // Instruction size is always a multiple of 4
    if (size % 4 != 0) return nil;
    return [NSMutableData dataWithLength:size];
}

- (BOOL)canAssembleInstructionsForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

- (BOOL)canDecompileProceduresForCPUFamily:(NSString *)family andSubFamily:(NSString *)subFamily {
    return NO;
}

@end
