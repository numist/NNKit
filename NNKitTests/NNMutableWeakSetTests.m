//
//  NNMutableWeakSetTests.m
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@interface NNMutableWeakSetTests : XCTestCase

@end


@implementation NNMutableWeakSetTests

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
