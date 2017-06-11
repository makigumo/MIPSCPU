//
// Created by Dan on 2017/06/20.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "NSArray+BitRange.h"
#import "BitRange.h"


@implementation NSArray (BitRange)

- (uint8_t)bitCount {
    uint8_t res = 0;
    for (BitRange *b in self) res += [b bitCount];
    return res;
}

- (uint32_t)asMask {
    uint32_t res = 0;
    for (BitRange *b in self) res |= [b asMask];
    return res;
}

- (uint32_t)asMatch {
    uint32_t res = 0;
    for (BitRange *b in self) res |= [b asMatch];
    return res;
}

- (uint8_t)highestBit {
    uint8_t res = 0;
    for (BitRange *b in self) {
        if (b.firstBit > res) {
            res = b.firstBit;
        }
    }
    return res;
}

- (uint8_t)lowestBit {
    uint8_t res = 31;
    for (BitRange *b in self) {
        if (b.lastBit < res) {
            res = b.lastBit;
        }
    }
    return res;
}

- (uint32_t)valueFromBytes:(uint32_t)bytes {
    return ((bytes & [self asMask]) >> [self lowestBit]);
}

- (NSArray<NSValue *> *)getRanges {
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:self.count];
    for (BitRange *b in self) {
        [res addObject:[NSValue valueWithRange:NSMakeRange(b.lastBit, (NSUInteger) (b.firstBit - b.lastBit + 1))]];
    }
    return res;
}

- (NSNumber *)value {
    uint32_t res = 0;
    BOOL hasValue = NO;
    for (BitRange *b in self) {
        if (b.value) {
            hasValue = YES;
            res |= b.value.unsignedIntValue << b.lastBit;
        }
    }
    if (hasValue) {
        return @(res);
    } else {
        return nil;
    }
}

@end