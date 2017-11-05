//
// Created by Dan on 2017/06/22.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsCond.h"
#import "InsOp.h"
#import "NSString+MIPSHelper.h"

@interface InsCondOpOp : InsCond

- (instancetype)initWithLeft:(InsOp *)left right:(InsOp *)right condType:(CondType)condType;

- (NSString *)description;

@end

@interface InsCondOpNumber : InsCond

- (instancetype)initWithLeft:(InsOp *)left right:(NSNumber *)right condType:(CondType)condType;

- (NSString *)description;

@end

@implementation InsCond {

}

+ (instancetype)condWith:(NSString *const)condition
                  andOps:(NSArray<InsOp *> *const)ops {
    NSAssert(condition, @"condition string required.");
    NSAssert(ops, @"InsOp array required.");

    NSAssert1(condition.length >= 4, @"condition string too small: %d < 5", (unsigned int) condition.length);

    // left op index
    NSAssert1([condition isOpIndexAtIndex:0], @"left operand index required: %@", condition);
    unsigned int left_op_idx = (unsigned int) [condition substringFromIndex:1].intValue;
    NSAssert3(left_op_idx < ops.count, @"left operand index %d not in op[%lu]: %@", left_op_idx, (unsigned long) ops.count, condition);
    NSUInteger pos_in_cond = [[@(left_op_idx) stringValue] length] + 1; // place count + '#' length
    
    // comparison operators
    CondType condType = COND_FALSE;
    // equal '=='
    if ([condition characterAtIndex:pos_in_cond] == '=') {
        if ([condition characterAtIndex:++pos_in_cond] == '=') {
            condType = COND_EQUAL;
        }
    }
    // not equal '!='
    else if ([condition characterAtIndex:pos_in_cond] == '!') {
        if ([condition characterAtIndex:++pos_in_cond] == '=') {
            condType = COND_NOT_EQUAL;
        }
    }
    // less '<'
    else if ([condition characterAtIndex:pos_in_cond] == '<') {
        condType = COND_LESS;
    }
    // greater equal '>='
    else if ([condition characterAtIndex:pos_in_cond] == '>') {
        if ([condition characterAtIndex:++pos_in_cond] == '=') {
            condType = COND_GREATER_EQUAL;
        }
    }
    NSAssert1(condType != COND_FALSE, @"invalid comparison operator: %@", condition);
    pos_in_cond++;
    if ([condition isOpIndexAtIndex:pos_in_cond]) {
        unsigned int right_op_idx = (unsigned int) [condition substringFromIndex:pos_in_cond+1].intValue;
        NSAssert3(right_op_idx < ops.count, @"right operand index %d not in op[%lu]: %@", right_op_idx, (unsigned long) ops.count, condition);
        return [self condWithLeftOp:ops[left_op_idx] rightOp:ops[right_op_idx] condType:condType];
    } else if ([condition isDigitAtIndex:pos_in_cond]) {
        unsigned int right_val = (unsigned int) [condition substringFromIndex:pos_in_cond].intValue;
        return [self condWithLeftOp:ops[left_op_idx] rightValue:@(right_val) condType:condType];
    }
    NSAssert1(false, @"right operand index or value required: %@", condition);
    return nil;
}

+ (instancetype)condWithLeftOp:(InsOp *)left
                       rightOp:(InsOp *)right
                      condType:(CondType)cond {
    return [[InsCondOpOp alloc] initWithLeft:left
                                       right:right
                                    condType:cond];
}

+ (instancetype)condWithLeftOp:(InsOp *)left
                    rightValue:(NSNumber *)right
                      condType:(CondType)cond {
    return [[InsCondOpNumber alloc] initWithLeft:left
                                           right:right
                                        condType:cond];
}

- (BOOL)satisfiedWith:(uint32_t)bytes {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}


@end

@implementation InsCondOpOp {
    InsOp *_left;
    InsOp *_right;
    CondType _condType;
}

- (instancetype)initWithLeft:(InsOp *)left
                       right:(InsOp *)right
                    condType:(CondType)condType {
    self = [super init];
    if (self) {
        _left = left;
        _right = right;
        _condType = condType;
    }

    return self;
}

- (BOOL)satisfiedWith:(uint32_t)bytes {
    switch (_condType) {

        case COND_EQUAL:
            return [_left valueFromBytes:bytes] == [_right valueFromBytes:bytes];
        case COND_NOT_EQUAL:
            return [_left valueFromBytes:bytes] != [_right valueFromBytes:bytes];
        case COND_LESS:
            return [_left valueFromBytes:bytes] < [_right valueFromBytes:bytes];
        case COND_GREATER_EQUAL:
            return [_left valueFromBytes:bytes] >= [_right valueFromBytes:bytes];
        case COND_FALSE:
            return NO;
    }
    return NO;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_left=%@", _left];
    [description appendFormat:@", _right=%@", _right];
    [description appendFormat:@", _condType=%lu", (unsigned long) _condType];
    [description appendString:@">"];
    return description;
}

@end

@implementation InsCondOpNumber {
    InsOp *_left;
    NSNumber *_right;
    CondType _condType;

}

- (instancetype)initWithLeft:(InsOp *)left
                       right:(NSNumber *)right
                    condType:(CondType)condType {
    self = [super init];
    if (self) {
        _left = left;
        _right = right;
        _condType = condType;
    }

    return self;
}

- (BOOL)satisfiedWith:(uint32_t)bytes {
    switch (_condType) {

        case COND_EQUAL:
            return [_left valueFromBytes:bytes] == _right.unsignedIntValue;
        case COND_NOT_EQUAL:
            return [_left valueFromBytes:bytes] != _right.unsignedIntValue;
        case COND_LESS:
            return [_left valueFromBytes:bytes] < _right.unsignedIntValue;
        case COND_GREATER_EQUAL:
            return [_left valueFromBytes:bytes] >= _right.unsignedIntValue;
        case COND_FALSE:
            return NO;
    }
    return NO;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_left=%@", _left];
    [description appendFormat:@", _right=%@", _right];
    [description appendFormat:@", _condType=%lu", (unsigned long) _condType];
    [description appendString:@">"];
    return description;
}

@end
