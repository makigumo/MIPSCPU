//
// Created by Dan on 2017/11/05.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "NSString+MIPSHelper.h"


@implementation NSString (MIPSHelper)

- (BOOL)isDigitAtIndex:(NSUInteger)index {
    unichar i = [self characterAtIndex:index];
    return i >= '0' && i <= '9';
}

- (BOOL)isHexAtIndex:(NSUInteger)index {
    unichar i = [self characterAtIndex:index];
    return [self isDigitAtIndex:index] ||
            (i >= 'a' && i <= 'f') ||
            (i >= 'A' && i <= 'F');
}

- (BOOL)isOpIndexAtIndex:(NSUInteger)index {
    return [self length] > index + 1 &&
            [self characterAtIndex:index] == '#' && [self isDigitAtIndex:index + 1];
}


@end
