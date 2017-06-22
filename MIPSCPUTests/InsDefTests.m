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

@end
