//
// Created by Dan on 2017/06/20.
// Copyright (c) 2017 Makigumo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BitRange.h"
#import "NSArray+BitRange.h"

@interface NSArray_BitRangeTests : XCTestCase

@end

@implementation NSArray_BitRangeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAsMask {
    NSArray *array = @[
            [BitRange range32WithFirst:31 last:26],
            [BitRange range32WithFirst:20 last:16]
    ];
    XCTAssertEqual([array asMask], 0xFC1F0000);
    array = @[
            [BitRange range32WithFirst:31 last:26 value:@(0x11)],
            [BitRange range32WithFirst:25 last:21 value:@(0x11)],
            [BitRange range32WithFirst:5 last:0 value:@(0)]
    ];
    XCTAssertEqual([array asMask], 0xFFE0003F);
}

- (void)testAsMatch {
    NSArray *array = @[[BitRange range32WithFirst:31 last:26], [BitRange range32WithFirst:20 last:16]];
    XCTAssertEqual([array asMatch], 0);
    array = @[[BitRange range32WithFirst:31 last:26 value:@(0x11)]];
    XCTAssertEqual([array asMatch], 0x44000000);
    array = @[[BitRange range32WithFirst:31 last:26 value:@(0x11)], [BitRange range32WithFirst:5 last:0 value:@(0)]];
    XCTAssertEqual([array asMatch], 0x44000000);
    array = @[[BitRange range32WithFirst:31 last:26 value:@(0x11)],
            [BitRange range32WithFirst:25 last:21 value:@(0x11)],
            [BitRange range32WithFirst:5 last:0 value:@(0)]];
    XCTAssertEqual([array asMatch], 0x46200000);
}

- (void)testRegWithValue {
    NSArray *array = @[[BitRange range32WithFirst:31 last:26 value:@(0)],
            [BitRange range32WithFirst:25 last:21],
            [BitRange range32WithFirst:20 last:11 value:@(0)],
            [BitRange range32WithFirst:10 last:6 value:@(0)],
            [BitRange range32WithFirst:5 last:0 value:@(8)],
    ];
    XCTAssertEqual([array asMatch], 8);
    XCTAssertEqual([array asMask], 0xffffffff);
    array = @[[BitRange range32WithFirst:31 last:26 value:@(0)],
            [BitRange range32WithFirst:25 last:21 value:@(31)],
            [BitRange range32WithFirst:20 last:11 value:@(0)],
            [BitRange range32WithFirst:10 last:6 value:@(0)],
            [BitRange range32WithFirst:5 last:0 value:@(8)],
    ];
    XCTAssertEqual([array asMatch], 0x3e00008);
    XCTAssertEqual([array asMask], 0xffffffff);
}

- (void)testHighestBit {
    NSArray *const array = @[[BitRange range32WithFirst:31 last:26]];
    XCTAssertEqual([array highestBit], 31);
}

- (void)testLowestBit {
    NSArray *const array = @[[BitRange range32WithFirst:31 last:26]];
    XCTAssertEqual([array lowestBit], 26);
}

- (void)testValueFromBytes {
    NSArray *const array = @[[BitRange range32WithFirst:31 last:26]];
    XCTAssertEqual([array valueFromBytes:0x4c000000], 0x13);
}

- (void)testBitcount {
    XCTAssertEqual([@[[BitRange range32WithFirst:31 last:26]] bitCount], 6);
    XCTAssertEqual([@[[BitRange range32WithFirst:25 last:21]] bitCount], 5);
    XCTAssertEqual([@[[BitRange range32WithFirst:20 last:16]] bitCount], 5);
    XCTAssertEqual([@[[BitRange range32WithFirst:15 last:11]] bitCount], 5);
    XCTAssertEqual([@[[BitRange range32WithFirst:5 last:0]] bitCount], 6);
}

- (void)testBitcount_multiple {
    NSArray *const array = @[
            [BitRange range32WithFirst:31 last:26],
            [BitRange range32WithFirst:25 last:21],
            [BitRange range32WithFirst:20 last:16],
            [BitRange range32WithFirst:15 last:11],
            [BitRange range32WithFirst:5 last:0],
    ];
    XCTAssertEqual([array bitCount], 27);
}

@end
