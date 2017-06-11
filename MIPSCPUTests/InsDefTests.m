//
//  InsDefTests.m
//  MIPSCPU
//
//  Created by Dan on 2017/06/11.
//  Copyright © 2017年 Makigumo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "InsDef.h"
#import "BitRange.h"
#import "NSArray+BitRange.h"

@interface InsDefTests : XCTestCase

@end

@implementation InsDefTests
InsDef *insDef;

- (void)setUp {
    [super setUp];
    insDef = [[InsDef alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSingleBitrange {
    NSArray<BitRange *> *array = [insDef bitrangesFromString:@"31..26"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertNil(array[0].value);
}

- (void)testSingleBitrangeWithExtraData {
    NSArray<BitRange *> *array = [insDef bitrangesFromString:@"31..26=0x23"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertEqual(array[0].value.unsignedIntValue, 0x23);
    XCTAssertEqual(array[0].asMask, 0xfc000000);
    XCTAssertEqual(array[0].asMatch, 0x8c000000);

    array = [insDef bitrangesFromString:@"31..0=0"];
    XCTAssertEqual(array.count, 1);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 0);
    XCTAssertEqual(array[0].value.integerValue, 0);
    XCTAssertEqual(array[0].asMask, 0xffffffff);
    XCTAssertEqual(array[0].asMatch, 0);
}

- (void)testDualBitrange {
    NSArray<BitRange *> *array = [insDef bitrangesFromString:@"31..26=1,20..16=0xf"];
    XCTAssertEqual(array.count, 2);
    XCTAssertEqual(array[0].firstBit, 31);
    XCTAssertEqual(array[0].lastBit, 26);
    XCTAssertEqual(array[0].value.unsignedIntValue, 1);
    XCTAssertEqual(array[1].firstBit, 20);
    XCTAssertEqual(array[1].lastBit, 16);
    XCTAssertEqual(array[1].value.unsignedIntValue, 0xf);
}

- (void)testInvalidBitrange {
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"16..20"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"31..26,16..20"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"32..26"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"-1..26"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"31..-1"], NSException, NSInternalInconsistencyException);
}

- (void)testInvalidBitrangeValue {
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"0..0=2"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"1..1=2"], NSException, NSInternalInconsistencyException);
    XCTAssertThrowsSpecificNamed([insDef bitrangesFromString:@"31..26=0x40"], NSException, NSInternalInconsistencyException);
}

- (void)testOperandType {
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20"], OTYPE_UNDEFINED);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20=12"], OTYPE_UNDEFINED);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:rd"], OTYPE_REG_DEST);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:rt"], OTYPE_REG_TEMP);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:rs"], OTYPE_REG_SOURCE);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:fd"], OTYPE_FPU_REG_DEST);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:ft"], OTYPE_FPU_REG_TEMP);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:fs"], OTYPE_FPU_REG_SOURCE);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:imm16"], OTYPE_IMM16);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:imm24"], OTYPE_IMM24);
    XCTAssertEqual([insDef getOperandTypeFromString:@"15..0:off18"], OTYPE_OFF18);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:ffmt"], OTYPE_FPU_FMT);

    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:x"], OTYPE_INVALID);
    XCTAssertEqual([insDef getOperandTypeFromString:@"16..20:"], OTYPE_UNDEFINED);
}

- (void)testOperandPosition {
    XCTAssertNil([insDef getOperandPositionFromString:@"16..20"]);
    XCTAssertNil([insDef getOperandPositionFromString:@"16..20#"]);
    XCTAssertEqual([insDef getOperandPositionFromString:@"16..20#1"].intValue, 1);
    XCTAssertEqual([insDef getOperandPositionFromString:@"16..20#1rw"].intValue, 1);
}

- (void)testOperands {
    InsDef *def = [InsDef defWithMnemonic:@"alnv.ps"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..26=0x13 25..21:rs#4r 20..16:ft#3r 15..11:fs#2r 10..6:fd#1w 5..0=0x1e"];
    XCTAssertEqual(def.operands.count, 4);
    XCTAssertEqual(def.mask, 0xFC00003F);
    XCTAssertEqual(def.match, 0x4c00001e);
    XCTAssertEqual(def.operands[3].type, OTYPE_REG_SOURCE);
    XCTAssertEqual(def.operands[3].accessMode, DISASM_ACCESS_READ);
    XCTAssertEqual(def.operands[2].type, OTYPE_FPU_REG_TEMP);
    XCTAssertEqual(def.operands[2].accessMode, DISASM_ACCESS_READ);
    XCTAssertEqual(def.operands[1].type, OTYPE_FPU_REG_SOURCE);
    XCTAssertEqual(def.operands[1].accessMode, DISASM_ACCESS_READ);
    XCTAssertEqual(def.operands[0].type, OTYPE_FPU_REG_DEST);
    XCTAssertEqual(def.operands[0].accessMode, DISASM_ACCESS_WRITE);
    def = [InsDef defWithMnemonic:@"nop"
                          release:MIPS32R2 | MIPS64
                           format:@"31..26=0 25..21=1 20..16=0 15..11=1 10..6=0 5..0=0x25"];
    XCTAssertEqual(def.operands.count, 0);
    XCTAssertEqual(def.mask, 0xffffffff);
    XCTAssertEqual(def.match, 0x00200825);
}

- (void)testNumberOfMaskBitsSet {
    InsDef *def = [InsDef defWithMnemonic:@"nop"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..0"];
    XCTAssertEqual([def numberOfMaskBitsSet], 0);
    def = [InsDef defWithMnemonic:@"nop"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..26"];
    XCTAssertEqual([def numberOfMaskBitsSet], 0);
    def = [InsDef defWithMnemonic:@"nop"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..26"];
    XCTAssertEqual([def numberOfMaskBitsSet], 0);
    def = [InsDef defWithMnemonic:@"nop"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..0=0"];
    XCTAssertEqual([def numberOfMaskBitsSet], 32);
    def = [InsDef defWithMnemonic:@"nop"
                                  release:MIPS32R2 | MIPS64
                                   format:@"31..26=0"];
    XCTAssertEqual([def numberOfMaskBitsSet], 6);
}

- (void)testMatches {
    InsDef *def = [InsDef defWithMnemonic:@"abs.s"
                                  release:MIPS32
                                   format:@"31..26=0x11 25..21=0x10 20..16=0 15..11:fs#2r 10..6:fd#1w 5..0=5"];
    XCTAssertTrue([def matches:0x4600f005 isa:MIPS32]);
    // broad match
    def = [InsDef defWithMnemonic:@"jr"
                                  release:MIPS32
                                   format:@"31..26=0 25..21:rs#1r 20..11=0 10..6=0 5..0=8"];
    XCTAssertEqual(def.match, 0x00000008);
    XCTAssertEqual(def.mask, 0xfc1fffff);
    XCTAssertTrue([def matches:0x03e00008 isa:MIPS32]);
    XCTAssertTrue([def matches:0x03200008 isa:MIPS32]);
    // more specific match
    def = [InsDef defWithMnemonic:@"jr_ret"
                          release:MIPS32
                           format:@"31..26=0 25..21=31:rs#1r 20..11=0 10..6=0 5..0=8"];
    XCTAssertEqual(def.operands.count, 1);
    XCTAssertEqual([def.operands[0].bits asMask], 0x03e00000);
    XCTAssertEqual([def.operands[0].bits asMatch], 0x03e00000);
    XCTAssertEqual(def.match, 0x03e00008);
    XCTAssertEqual(def.mask, 0xffffffff);
    XCTAssertTrue([def matches:0x03e00008 isa:MIPS32]);
    XCTAssertFalse([def matches:0x03200008 isa:MIPS32]);
}

- (void)testBitRangesIntersect {
    XCTAssertThrowsSpecificNamed([InsDef defWithMnemonic:@"abs.s"
                                                 release:MIPS32
                                                  format:@"31..26=0x11 25..10=0x10 20..16=0 15..11:fs#2r 10..6:fd#1w 5..0=5"],
            NSException, NSInternalInconsistencyException, @"should throw NSInternalInconsistencyException");
    XCTAssertThrowsSpecificNamed([InsDef defWithMnemonic:@"abs.s"
                                                 release:MIPS32
                                                  format:@"31..26=0x11 25..20=0x10 20..16=0 15..11:fs#2r 10..6:fd#1w 5..0=5"],
            NSException, NSInternalInconsistencyException, @"should throw NSInternalInconsistencyException");
    XCTAssertThrowsSpecificNamed([InsDef defWithMnemonic:@"test"
                                                 release:MIPS32
                                                  format:@"31..26,26..21=0x10 20..0=0"],
            NSException, NSInternalInconsistencyException, @"should throw NSInternalInconsistencyException");
}

- (void)testGetValueFromString {
    XCTAssertEqual([[insDef getValueFromString:@"16..20=1"] unsignedIntValue], 1);
    XCTAssertEqual([[insDef getValueFromString:@"16..20=0"] unsignedIntValue], 0);
    XCTAssertEqual([[insDef getValueFromString:@"16..20=0x1"] unsignedIntValue], 0x1);
    XCTAssertEqual([[insDef getValueFromString:@"16..20=0x20"] unsignedIntValue], 0x20);
    XCTAssertEqual([[insDef getValueFromString:@"5..0=0x1e"] unsignedIntValue], 0x1e);
    XCTAssertNil([insDef getValueFromString:@"16..20="]);
}

- (void)testGetAccessModeFromString {
    XCTAssertEqual([insDef getAccessModeFromString:@"16..20=1"], DISASM_ACCESS_NONE);
    XCTAssertEqual([insDef getAccessModeFromString:@"16..20=1r"], DISASM_ACCESS_READ);
    XCTAssertEqual([insDef getAccessModeFromString:@"16..20=1w"], DISASM_ACCESS_WRITE);
    XCTAssertEqual([insDef getAccessModeFromString:@"16..20=1rw"], DISASM_ACCESS_READ | DISASM_ACCESS_WRITE);
    XCTAssertEqual([insDef getAccessModeFromString:@"16..20=1wr"], DISASM_ACCESS_READ | DISASM_ACCESS_WRITE);
}

- (void)testGetIsBranchDestinationFromString {
    XCTAssertFalse([insDef getIsBranchDestinationFromString:@"15..0:off18#2r"]);
    XCTAssertTrue([insDef getIsBranchDestinationFromString:@"15..0:off18B#2r"]);
}
@end
