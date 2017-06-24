//
//  InsCondTests.m
//  MIPSCPU
//
//  Created by Dan on 2017/06/22.
//  Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "InsCond.h"
#import "InsOp.h"

@interface InsCondTests : XCTestCase

@end

@implementation InsCondTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCondWithAndOpsFail {
    XCTAssertThrowsSpecificNamed([InsCond condWith:nil andOps:@[]], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsCond condWith:@"" andOps:nil], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsCond condWith:@"" andOps:@[]], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsCond condWith:@"#0=!=0" andOps:@[]], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsCond condWith:@"#0==!=0" andOps:@[]], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsCond condWith:@"#0==0" andOps:@[]], NSException, NSInternalInconsistencyException);
}

- (void)testCondWithAndOps {
    InsCond *insCond = [InsCond condWith:@"#0==0" andOps:@[[InsOp insOpFromString:@"31..0"]]];
    XCTAssertNotNil(insCond);
    XCTAssertTrue([insCond satisfiedWith:0]);
    insCond = [InsCond condWith:@"#0!=1" andOps:@[[InsOp insOpFromString:@"31..0"]]];
    XCTAssertNotNil(insCond);
    XCTAssertTrue([insCond satisfiedWith:0]);
    XCTAssertFalse([insCond satisfiedWith:1]);
    insCond = [InsCond condWith:@"#0<1" andOps:@[[InsOp insOpFromString:@"31..0"]]];
    XCTAssertTrue([insCond satisfiedWith:0]);
    XCTAssertFalse([insCond satisfiedWith:1]);
    insCond = [InsCond condWith:@"#0<#1" andOps:@[[InsOp insOpFromString:@"31..16:rs"],
            [InsOp insOpFromString:@"15..0:rt"]]];
    XCTAssertTrue([insCond satisfiedWith:1]);
    XCTAssertFalse([insCond satisfiedWith:0x10000]);
    insCond = [InsCond condWith:@"#0>=#1" andOps:@[[InsOp insOpFromString:@"31..16:rs"],
            [InsOp insOpFromString:@"15..0:rt"]]];
    XCTAssertTrue([insCond satisfiedWith:0]);
    XCTAssertTrue([insCond satisfiedWith:0x10000]);
    XCTAssertFalse([insCond satisfiedWith:0x1]);
}

- (void)testOpOp {
    InsOp *leftOp = [InsOp insOpFromString:@"25..21:rs"];
    InsOp *rightOp = [InsOp insOpFromString:@"20..16:rt"];

    XCTAssertTrue([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_EQUAL] satisfiedWith:0]);
    XCTAssertFalse([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_NOT_EQUAL] satisfiedWith:0]);
    XCTAssertFalse([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_LESS] satisfiedWith:0]);

    XCTAssertTrue([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_EQUAL] satisfiedWith:0x1AD0000]);
    XCTAssertFalse([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_EQUAL] satisfiedWith:0x1AC0000]);
    XCTAssertFalse([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_LESS] satisfiedWith:0x1AC0000]);
    XCTAssertTrue([[InsCond condWithLeftOp:leftOp rightOp:rightOp condType:COND_LESS] satisfiedWith:0x0AD0000]);
}

- (void)testOpValue {
    InsOp *insOp = [InsOp insOpFromString:@"0..0"];

    XCTAssertTrue([[InsCond condWithLeftOp:insOp rightValue:@(0) condType:COND_EQUAL] satisfiedWith:0]);
    XCTAssertFalse([[InsCond condWithLeftOp:insOp rightValue:@(0) condType:COND_NOT_EQUAL] satisfiedWith:0]);

    XCTAssertFalse([[InsCond condWithLeftOp:insOp rightValue:@(1) condType:COND_EQUAL] satisfiedWith:0]);
    XCTAssertTrue([[InsCond condWithLeftOp:insOp rightValue:@(1) condType:COND_NOT_EQUAL] satisfiedWith:0]);
}

@end
