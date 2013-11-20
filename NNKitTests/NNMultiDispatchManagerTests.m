//
//  NNMultiDispatchManagerTests.m
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <NNKit/NNKit.h>
#import <NNKit/NNMultiDispatchManager.h>


unsigned callCount = 0;
dispatch_group_t group;


@protocol NNMultiDispatchManagerTestProtocol <NSObject>
- (void)foo:(id)sender;
- (oneway void)bar:(id)sender;
@optional
- (void)baz:(id)sender;
- (id)qux:(id)sender;
@end


@interface NNMultiDispatchManagerTestObject : NSObject <NNMultiDispatchManagerTestProtocol>
@end
@implementation NNMultiDispatchManagerTestObject
- (void)foo:(id)sender;
{
    callCount++;
}
- (oneway void)bar:(id)sender;
{
    callCount++;
    dispatch_group_leave(group);
}
@end


@interface NNMultiDispatchManagerTestObject2 : NSObject <NNMultiDispatchManagerTestProtocol>
@end
@implementation NNMultiDispatchManagerTestObject2
- (void)foo:(id)sender;
{
    callCount++;
}
- (oneway void)bar:(id)sender;
{
    callCount++;
    dispatch_group_leave(group);
}
- (void)baz:(id)sender;
{
    callCount++;
}
@end


@interface NNMultiDispatchManagerTests : XCTestCase

@end


@implementation NNMultiDispatchManagerTests

- (void)setUp
{
    [super setUp];

    callCount = 0;
    group = dispatch_group_create();
}

- (void)testSync
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    [(id<NNMultiDispatchManagerTestProtocol>)manager foo:self];
    XCTAssertEqual(callCount, (unsigned)4, @"");
}

- (void)testAsync;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    dispatch_group_enter(group);

    [(id<NNMultiDispatchManagerTestProtocol>)manager bar:self];
    XCTAssertEqual(callCount, (unsigned)0, @"");
    
    while(!despatch_group_yield(group));
    XCTAssertEqual(callCount, (unsigned)4, @"");
}

- (void)testOptionalSelector;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertNoThrow([(id<NNMultiDispatchManagerTestProtocol>)manager baz:self], @"");
    XCTAssertEqual(callCount, (unsigned)2, @"");
}

- (void)testBadSelector;
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertThrows([(id)manager invokeWithTarget:self], @"");
    XCTAssertEqual(callCount, (unsigned)0, @"");
}

- (void)testWeakDispatch
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    @autoreleasepool {
        id foo2 = [NNMultiDispatchManagerTestObject new];
        id foo3 = [NNMultiDispatchManagerTestObject2 new];
        [manager addObserver:foo1];
        [manager addObserver:foo2];
        [manager addObserver:foo3];
        [manager addObserver:foo4];
    }
    
    [(id<NNMultiDispatchManagerTestProtocol>)manager foo:self];
    XCTAssertEqual(callCount, (unsigned)2, @"");
}

- (void)testIllegalReturnType
{
    NNMultiDispatchManager *manager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(NNMultiDispatchManagerTestProtocol)];
    __attribute__((objc_precise_lifetime)) id foo1 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo2 = [NNMultiDispatchManagerTestObject new];
    __attribute__((objc_precise_lifetime)) id foo3 = [NNMultiDispatchManagerTestObject2 new];
    __attribute__((objc_precise_lifetime)) id foo4 = [NNMultiDispatchManagerTestObject2 new];
    [manager addObserver:foo1];
    [manager addObserver:foo2];
    [manager addObserver:foo3];
    [manager addObserver:foo4];
    
    XCTAssertThrows((void)[(id<NNMultiDispatchManagerTestProtocol>)manager qux:self], @"");
    XCTAssertEqual(callCount, (unsigned)0, @"");
}

@end
