//
//  BitRangeTests.m
//  MIPSCPU
//
//  Created by Dan on 2017/06/11.
//  Copyright © 2017年 Makigumo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BitRange.h"

@interface BitRangeTests : XCTestCase

@end

@implementation BitRangeTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBitCount {
    XCTAssertEqual([[BitRange range32WithFirst:31 last:31] bitCount], 1);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:30] bitCount], 2);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26] bitCount], 6);
    XCTAssertEqual([[BitRange range32WithFirst:15 last:11] bitCount], 5);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:0] bitCount], 32);
}

- (void)testBitMask {
    XCTAssertEqual([[BitRange range32WithFirst:0 last:0] asMask], 0x1);
    XCTAssertEqual([[BitRange range32WithFirst:1 last:1] asMask], 0x2);
    XCTAssertEqual([[BitRange range32WithFirst:1 last:0] asMask], 0x3);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:31] asMask], 0x80000000);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26] asMask], 0xFC000000);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:0] asMask], 0xFFFFFFFF);
}

- (void)testBitMaskWithValue {
    XCTAssertEqual([[BitRange range32WithFirst:0 last:0 value:@(0)] asMask], 0x1);
    XCTAssertEqual([[BitRange range32WithFirst:0 last:0 value:@(1)] asMask], 0x1);
    XCTAssertEqual([[BitRange range32WithFirst:1 last:0 value:@(2)] asMask], 0x3);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26 value:@(0x13)] asMask], 0xFC000000);
}

- (void)testBitMatch {
    XCTAssertEqual([[BitRange range32WithFirst:0 last:0] asMatch], 0);
    XCTAssertEqual([[BitRange range32WithFirst:1 last:1 value:@(1)] asMatch], 0x2);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26 value:@(0x13)] asMatch], 0x4c000000);
    XCTAssertEqual([[BitRange range32WithFirst:5 last:0 value:@(0x1e)] asMatch], 0x0000001e);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26] asMatch], 0);
}

- (void)testMaxValue {
    XCTAssertEqual([[BitRange range32WithFirst:0 last:0] maxValue], 1);
    XCTAssertEqual([[BitRange range32WithFirst:1 last:1 value:@(1)] maxValue], 1);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:26] maxValue], 0x3f);
    XCTAssertEqual([[BitRange range32WithFirst:31 last:0 value:@(0x1e)] maxValue], 0xffffffff);
}

@end
