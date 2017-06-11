//
// Created by Dan on 2017/06/11.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BitRange : NSObject {
}
@property uint8_t maxBitCount;  // maximal bit width
@property uint8_t firstBit;     // MSB
@property uint8_t lastBit;      // LSB
@property NSNumber *value;      // value in bitrange

- (instancetype)initWithFirst:(uint8_t)first_bit
                         last:(uint8_t)last_bit
                        value:(NSNumber *)value
                  maxBitCount:(uint8_t)maxBitCount;

+ (instancetype)range32WithFirst:(uint8_t)first_bit
                            last:(uint8_t)last_bit;

+ (instancetype)range32WithFirst:(uint8_t)first_bit
                            last:(uint8_t)last_bit
                           value:(NSNumber *)value;

- (uint8_t)bitCount;

- (uint32_t)asMask;

- (uint32_t)asMatch;

- (uint64_t)maxValue;

- (NSString *)description;
@end
