//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "BitRange.h"


@implementation BitRange {

}
- (instancetype)initWithFirst:(uint8_t)first_bit
                         last:(uint8_t)last_bit
                        value:(NSNumber *)value
                  maxBitCount:(uint8_t)maxBitCount {
    self = [super init];
    if (self) {
        self.firstBit = first_bit;
        self.lastBit = last_bit;
        self.value = value;
        self.maxBitCount = maxBitCount;
    }
    NSAssert(first_bit <= self.maxBitCount - 1, @"invalid first bit: 0 <= %d <= %d", first_bit, self.maxBitCount - 1);
    NSAssert(last_bit <= self.maxBitCount - 1, @"invalid last bit: 0 <= %d <= %d", last_bit, self.maxBitCount);
    NSAssert(last_bit <= first_bit, @"invalid BitRange: %d..%d", first_bit, last_bit);
    if (value != nil) {
        uint64_t maxValue = [self maxValue];
        if (value.unsignedIntValue > maxValue) {
            NSLog(@"invalid BitRange value: %d..%d=%d > %llu", first_bit, last_bit, value.unsignedIntValue, maxValue);
        }
        NSAssert(value.unsignedIntValue <= maxValue, @"invalid BitRange value: %d..%d=%d", first_bit, last_bit, value.unsignedIntValue);
    }
    return self;
}

+ (instancetype)range32WithFirst:(uint8_t)first_bit
                            last:(uint8_t)last_bit {
    return [[self alloc] initWithFirst:first_bit last:last_bit value:nil maxBitCount:32];
}

+ (instancetype)range32WithFirst:(uint8_t)first_bit
                            last:(uint8_t)last_bit
                           value:(NSNumber *)value {
    return [[self alloc] initWithFirst:first_bit last:last_bit value:value maxBitCount:32];
}

- (uint8_t)bitCount {
    return (uint8_t) ((self.firstBit - self.lastBit) + 1);
}

- (uint32_t)asMask {
    uint64_t i = (uint64_t) 1 << [self bitCount];
    return (uint32_t) (--i << self.lastBit);
}

- (uint32_t)asMatch {
    if (self.value) {
        return [self.value unsignedIntValue] << self.lastBit;
    }
    return 0;
}

- (uint64_t)maxValue {
    uint64_t i = ((uint64_t) 1) << [self bitCount];
    return (uint64_t) --i;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.maxBitCount=%d", self.maxBitCount];
    [description appendFormat:@", self.firstBit=%d", self.firstBit];
    [description appendFormat:@", self.lastBit=%d", self.lastBit];
    [description appendFormat:@", self.value=%@", self.value];
    [description appendString:@">"];
    return description;
}
@end
