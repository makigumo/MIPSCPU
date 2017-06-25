//
//  MIPSCPU.h
//  MIPSCPU
//
//  Created by Makigumo on 10/11/2016.
//  Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

typedef NS_ENUM(NSUInteger, MIPSRegClass) {
    RegClass_MIPS_FPU = RegClass_FirstUserClass,
    RegClass_MIPS_ACC,
    RegClass_MIPS_DSP,
    RegClass_MIPS_COP,
    RegClass_MIPS_HW,
    RegClass_MIPS_FCC,
    RegClass_MIPS_P,
    RegClass_MIPS_MPL,
    RegClass_MIPS_Cnt
};

@interface MIPSCPU : NSObject<CPUDefinition>

- (NSObject<HPHopperServices> *)hopperServices;

@end
