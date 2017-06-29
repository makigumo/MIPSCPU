//
// Created by Dan on 2017/06/20.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "Insn.h"
#import "InsDef.h"

@interface Insn ()
@property(readwrite) InsDef *insDef;
@property(readwrite) uint32_t bytes;
@end

@implementation Insn {

}

- (instancetype)initWithInsDef:(InsDef *)insDef bytes:(uint32_t)bytes {
    self = [super init];
    if (self) {
        self.insDef = insDef;
        self.bytes = bytes;
    }

    return self;
}

+ (instancetype)insnWithInsDef:(InsDef *)insDef bytes:(uint32_t)bytes {
    return [[self alloc] initWithInsDef:insDef bytes:bytes];
}


- (NSString *)mnemonic {
    return self.insDef.mnemonic;
}

- (NSNumber *)operandValue:(NSUInteger)index {
    NSArray<InsOp *> *const operands = [self.insDef operands];
    if (index > operands.count - 1) {
        return nil;
    }
    InsOp *const op = operands[index];
    if (op) {
        return @([op valueFromBytes:self.bytes]);
    } else {
        return nil;
    }
}


@end
