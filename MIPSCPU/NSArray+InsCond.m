//
// Created by Dan on 2017/06/22.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "NSArray+InsCond.h"
#import "InsCond.h"


@implementation NSArray (InsCond)

- (BOOL)satisfiedWith:(uint32_t)bytes {
    for (InsCond* cond in self) {
        if (![cond satisfiedWith:bytes]) {
            return NO;
        }
    }
    return YES;
}

@end
