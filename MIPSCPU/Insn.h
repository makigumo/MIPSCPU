//
// Created by Dan on 2017/06/20.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InsDef;


@interface Insn : NSObject

@property(readonly) InsDef *insDef;
@property(readonly) uint32_t bytes;

- (instancetype)initWithInsDef:(InsDef *)insDef bytes:(uint32_t)bytes;

+ (instancetype)insnWithInsDef:(InsDef *)insDef bytes:(uint32_t)bytes;


- (NSString *)mnemonic;

- (NSNumber *)operandValue:(NSUInteger)index;

@end
