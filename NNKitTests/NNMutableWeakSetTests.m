//
//  NNMutableWeakSetTests.m
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@interface NNMutableWeakSetTests : XCTestCase

@end

@implementation NNMutableWeakSetTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddObject;
{
    NNMutableWeakSet *set = [NNMutableWeakSet new];
    __attribute__((objc_precise_lifetime)) id bar = [NSObject new];
    [set addObject:bar];
    XCTAssertEqual(set.count, (NSUInteger)1, @"");
}

- (void)testMemberExists;
{
    NNMutableWeakSet *set = [NNMutableWeakSet new];
    __attribute__((objc_precise_lifetime)) id foo = [NSObject new];

    [set addObject:foo];
    
    XCTAssertEqual(set.count, (NSUInteger)1, @"");
    XCTAssertEqualObjects([set member:foo], foo, @"");
    XCTAssertNil([set member:[NSObject new]], @"");
}

- (void)testMemberDoesNotExist;
{
    NNMutableWeakSet *set = [NNMutableWeakSet new];

    XCTAssertNil([set member:[NSObject new]], @"");

    __attribute__((objc_precise_lifetime)) id foo = [NSObject new];
    [set addObject:foo];
    XCTAssertNil([set member:[NSObject new]], @"");
}

- (void)testRemoveObject;
{
    NNMutableWeakSet *set = [NNMutableWeakSet new];
    __attribute__((objc_precise_lifetime)) id bar = [NSObject new];
    
    [set addObject:bar];
    XCTAssertEqual(set.count, (NSUInteger)1, @"");
    [set removeObject:bar];
    XCTAssertEqual(set.count, (NSUInteger)0, @"");
}

- (void)testWeakRemoval;
{
    NNMutableWeakSet *set = [NNMutableWeakSet new];

    @autoreleasepool {
        @autoreleasepool {
            __attribute__((objc_precise_lifetime)) id foo = [NSObject new];
            [set addObject:foo];
            XCTAssertEqual(set.count, (NSUInteger)1, @"");
        }
        
        [set addObject:[NSObject new]];
        [set addObject:[NSObject new]];
    }
    
    XCTAssertEqual(set.count, (NSUInteger)0, @"");
}

@end
