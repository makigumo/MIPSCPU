#import "BitRange.h"
#import "BitRange.h"//
//  InsOpTests.m
//  MIPSCPU
//
//  Created by Dan on 2017/06/22.
//  Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "InsOp.h"

@interface InsOpTests : XCTestCase

@end

@implementation InsOpTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSingleBitrange {
    NSArray<BitRange *> *array = [InsOp bitrangesFromString:@"31..26"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertNil(array[0].value);
}

- (void)testSingleBitrangeWithExtraData {
    NSArray<BitRange *> *array = [InsOp bitrangesFromString:@"31..26=0x23"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertEqual(array[0].value.unsignedIntValue, 0x23);
    XCTAssertEqual(array[0].asMask, 0xfc000000);
    XCTAssertEqual(array[0].asMatch, 0x8c000000);

    array = [InsOp bitrangesFromString:@"31..0=0"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 0);
    XCTAssertEqual(array[0].value.integerValue, 0);
    XCTAssertEqual(array[0].asMask, 0xffffffff);
    XCTAssertEqual(array[0].asMatch, 0);
}

- (void)testDualBitrange {
    NSArray<BitRange *> *array = [InsOp bitrangesFromString:@"31..26=1,20..16=0xf"];
    XCTAssertEqual(array.count, 2);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertEqual(array[0].value.unsignedIntValue, 1);
    XCTAssertEqual(array[1].firstBit, 20);
    XCTAssertEqual(array[1].lastBit, 16);
    XCTAssertEqual(array[1].value.unsignedIntValue, 0xf);
}

- (void)testInvalidBitrange {
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"16..20"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"31..26,16..20"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"32..26"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"-1..26"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"31..-1"], NSException, NSInternalInconsistencyException);
}

- (void)testInvalidBitrangeValue {
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"0..0=2"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"1..1=2"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([InsOp bitrangesFromString:@"31..26=0x40"], NSException, NSInternalInconsistencyException);
}

- (void)testOperandType {
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20"], OTYPE_UNDEFINED);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20=12"], OTYPE_UNDEFINED);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:rd"], OTYPE_REG_DEST);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:rt"], OTYPE_REG_TEMP);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:rs"], OTYPE_REG_SOURCE);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:fd"], OTYPE_FPU_REG_DEST);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:ft"], OTYPE_FPU_REG_TEMP);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:fs"], OTYPE_FPU_REG_SOURCE);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:imm16"], OTYPE_IMM16);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"15..0:off18"], OTYPE_OFF18);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:ffmt"], OTYPE_FPU_FMT);

    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:x"], OTYPE_INVALID);
    XCTAssertEqual([InsOp getOperandTypeFromString:@"16..20:"], OTYPE_UNDEFINED);
}

- (void)testOperandPosition {
    XCTAssertNil([InsOp getOperandPositionFromString:@"16..20"]);
    XCTAssertNil([InsOp getOperandPositionFromString:@"16..20#"]);
    XCTAssertEqual([InsOp getOperandPositionFromString:@"16..20#1"].intValue, 1);
    XCTAssertEqual([InsOp getOperandPositionFromString:@"16..20#1rw"].intValue, 1);
}

- (void)testGetValueFromString {
    XCTAssertEqual([[InsOp getValueFromString:@"16..20=1"] unsignedIntValue], 1);
    XCTAssertEqual([[InsOp getValueFromString:@"16..20=0"] unsignedIntValue], 0);
    XCTAssertEqual([[InsOp getValueFromString:@"16..20=0x1"] unsignedIntValue], 0x1);
    XCTAssertEqual([[InsOp getValueFromString:@"16..20=0x20"] unsignedIntValue], 0x20);
    XCTAssertEqual([[InsOp getValueFromString:@"5..0=0x1e"] unsignedIntValue], 0x1e);
    XCTAssertNil([InsOp getValueFromString:@"16..20="]);
}

- (void)testGetAccessModeFromString {
    XCTAssertEqual([InsOp getAccessModeFromString:@"16..20=1"], DISASM_ACCESS_NONE);
    XCTAssertEqual([InsOp getAccessModeFromString:@"16..20=1r"], DISASM_ACCESS_READ);
    XCTAssertEqual([InsOp getAccessModeFromString:@"16..20=1w"], DISASM_ACCESS_WRITE);
    XCTAssertEqual([InsOp getAccessModeFromString:@"16..20=1rw"], DISASM_ACCESS_READ | DISASM_ACCESS_WRITE);
    XCTAssertEqual([InsOp getAccessModeFromString:@"16..20=1wr"], DISASM_ACCESS_READ | DISASM_ACCESS_WRITE);
}

- (void)testGetIsBranchDestinationFromString {
    XCTAssertFalse([InsOp getIsBranchDestinationFromString:@"15..0:off18#2r"]);
    XCTAssertTrue([InsOp getIsBranchDestinationFromString:@"15..0:off18B#2r"]);
}
@end
