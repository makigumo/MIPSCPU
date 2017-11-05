//
// Created by Dan on 2017/11/05.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MIPSHelper)

- (BOOL)isDigitAtIndex:(NSUInteger)index;
- (BOOL)isHexAtIndex:(NSUInteger)index;
- (BOOL)isOpIndexAtIndex:(NSUInteger)index;

@end
