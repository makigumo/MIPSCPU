//
// Created by Dan on 2017/06/20.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<BitRange> (BitRange)

- (uint8_t)bitCount;

- (uint32_t)asMask;

- (uint32_t)asMatch;

- (uint8_t)highestBit;

- (uint8_t)lowestBit;

- (uint32_t)valueFromBytes:(uint32_t)bytes;

- (NSArray<NSValue *> *)getRanges;

- (NSNumber *)value;

@end
