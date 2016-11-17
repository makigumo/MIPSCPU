//
//  MIPSCtx.h
//  MIPSCPU
//
//  Created by Makigumo on 10/11/2016.
//  Copyright (c) 2016 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Hopper/Hopper.h>

@class MIPSCPU;

@interface MIPSCtx : NSObject<CPUContext>

- (instancetype)initWithCPU:(MIPSCPU *)cpu andFile:(NSObject<HPDisassembledFile> *)file;

@end
