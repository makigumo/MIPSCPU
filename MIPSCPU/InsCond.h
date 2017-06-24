//
// Created by Dan on 2017/06/22.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InsOp;


@interface InsCond : NSObject

typedef NS_ENUM(NSUInteger, CondType) {
    COND_FALSE,
    COND_EQUAL,
    COND_NOT_EQUAL,
    COND_LESS,
    COND_GREATER_EQUAL,
};

+ (instancetype)condWith:(NSString *const)condition andOps:(NSArray<InsOp *> *const)ops;

+ (instancetype)condWithLeftOp:(InsOp *)left rightOp:(InsOp *)right condType:(CondType)cond;

+ (instancetype)condWithLeftOp:(InsOp *)left rightValue:(NSNumber *)right condType:(CondType)cond;

- (BOOL)satisfiedWith:(uint32_t)bytes;

@end
