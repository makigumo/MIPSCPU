//
// Created by Dan on 2017/06/22.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import "InsCond.h"
#import "InsOp.h"

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

NSString *const condition_pattern = @"^#(\\d+)(?:(!=)?+(==)?+(\\<)?+)(?:(?:#(\\d+))?(\\d+)?)$";

+ (instancetype)condWith:(NSString *const)condition
                  andOps:(NSArray<InsOp *> *const)ops {
    NSAssert(condition, @"condition string required.");
    NSAssert(ops, @"InsOp array required.");
    NSError *error = nil;
    NSRegularExpression *condition_regex = [NSRegularExpression regularExpressionWithPattern:condition_pattern
                                                                                     options:0
                                                                                       error:&error];
    NSTextCheckingResult *match = [condition_regex firstMatchInString:condition
                                                              options:0
                                                                range:NSMakeRange(0, [condition length])];
    NSAssert1(match != nil, @"invalid condition format: %@", condition);

    // left op index
    NSRange range = [match rangeAtIndex:1];
    NSAssert1(range.location != NSNotFound, @"left operand index required: %@", condition);
    unsigned int left_op_idx = (unsigned int) [condition substringWithRange:range].intValue;
    NSAssert3(left_op_idx < ops.count, @"left operand index %d not in op[%d]: %@", left_op_idx, (unsigned long) ops.count, condition);

    // comparison operators
    // not equal '!='
    NSRange notequalrange = [match rangeAtIndex:2];
    // equal '=='
    NSRange equalrange = [match rangeAtIndex:3];
    // less '<'
    NSRange lessrange = [match rangeAtIndex:4];
    NSAssert1(equalrange.location != NSNotFound ^ notequalrange.location != NSNotFound ^ lessrange.location != NSNotFound, @"invalid comparison operator: %@", condition);
    CondType condType = COND_FALSE;
    if (notequalrange.location != NSNotFound) {
        condType = COND_NOT_EQUAL;
    } else if (equalrange.location != NSNotFound) {
        condType = COND_EQUAL;
    } else if (lessrange.location != NSNotFound) {
        condType = COND_LESS;
    }

    // right operand
    NSRange right_op = [match rangeAtIndex:5];

    // right value
    NSRange right_value = [match rangeAtIndex:6];
    NSAssert1(right_op.location != NSNotFound ^ right_value.location != NSNotFound, @"invalid right operand/value: %@", condition);

    if (right_op.location != NSNotFound) {
        unsigned int right_op_idx = (unsigned int) [condition substringWithRange:right_op].intValue;
        NSAssert3(right_op_idx < ops.count, @"right operand index %d not in op[%d]: %@", right_op_idx, (unsigned long) ops.count, condition);
        return [self condWithLeftOp:ops[left_op_idx] rightOp:ops[right_op_idx] condType:condType];
    } else if (right_value.location != NSNotFound) {
        unsigned int right_val = (unsigned int) [condition substringWithRange:right_value].intValue;
        return [self condWithLeftOp:ops[left_op_idx] rightValue:@(right_val) condType:condType];
    }
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
