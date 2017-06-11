//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsOp.h"
#import "BitRange.h"
#import "NSArray+BitRange.h"


@implementation InsOp {
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.bits=%@", self.bits];
    [description appendFormat:@", self.type=%d", self.type];
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
