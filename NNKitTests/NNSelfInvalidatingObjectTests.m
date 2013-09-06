//
//  NNSelfInvalidatingObjectTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


static BOOL objectInvalidated;
static BOOL objectDestroyed;


@interface NNSelfInvalidatingObjectTests : XCTestCase
- (void)invalidated:(id)obj;
- (void)destroyed:(id)obj;
@end


@interface NNInvalidatingTestObject : NNSelfInvalidatingObject
@property (assign) NNSelfInvalidatingObjectTests *test;
@end

@implementation NNInvalidatingTestObject

- (instancetype)initWithTestObject:(NNSelfInvalidatingObjectTests *)obj;
{
    if (!(self = [super init])) { return nil; }
    
    _test = obj;
    
    return self;
}

- (void)invalidate;
{
    [self.test invalidated:self];
    
    [super invalidate];
}
- (void)dealloc;
{
    [_test destroyed:self];
    
    [super dealloc];
}
@end


@implementation NNSelfInvalidatingObjectTests

- (void)setUp
{
    [super setUp];
    
    objectInvalidated = NO;
    objectDestroyed = NO;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)invalidated:(id)obj;
{
    XCTAssertTrue(despatch_lock_is_held(dispatch_get_main_queue()), @"Invalidation happened on a queue other than the main queue!");
    XCTAssertFalse(objectInvalidated, @"Object was invalidated multiple times!");
    objectInvalidated = YES;
}

- (void)destroyed:(id)obj;
{
    XCTAssertTrue(objectInvalidated, @"Object was destroyed before it was invalidated!");
    objectDestroyed = YES;
}

- (void)testDeallocInvalidation
{
    NNInvalidatingTestObject *obj = [[NNInvalidatingTestObject alloc] initWithTestObject:self];
    
    XCTAssertFalse(objectInvalidated, @"Object was still valid before it was released");
    
    [obj release];
    obj = nil;
    
    while (!objectDestroyed) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was not invalidated before it was destroyed");
}

- (void)testManualInvalidation
{
    NNInvalidatingTestObject *obj = [[NNInvalidatingTestObject alloc] initWithTestObject:self];
    
    XCTAssertFalse(objectInvalidated, @"Object was still valid before it was released");
    
    // Ensure the autorelease pool gets drained within the scope of this test.
    @autoreleasepool {
        [obj invalidate];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was manually invalidated before it was destroyed");

    [obj release];
    obj = nil;
    
    while (!objectDestroyed) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue(objectInvalidated, @"Object was not invalidated before it was destroyed");
}

- (void)testManualDealloc
{
    XCTAssertThrows([[NNSelfInvalidatingObject new] dealloc], @"Invalidating objects are not supposed to accept -dealloc quietly");
}

@end
