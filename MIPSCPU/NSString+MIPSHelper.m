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

- (BOOL)isLowercaseLetterAtIndex:(NSUInteger)index {
    unichar i = [self characterAtIndex:index];
    return i >= 'a' && i <= 'z';
}

- (NSRange)rangeOfTypeString {
    if ([self length] <= 0 ||
            ![self isLowercaseLetterAtIndex:0]) {
        return NSMakeRange(NSNotFound, 0);
    }
    unsigned int i = 1;
    for (NSUInteger j = 1; j < [self length]; ++j) {
        if ([self isLowercaseLetterAtIndex:j] ||
                [self isDigitAtIndex:j]) {
            i++;
        } else {
            break;
        }
    }
    return NSMakeRange(0, i);
}


@end
