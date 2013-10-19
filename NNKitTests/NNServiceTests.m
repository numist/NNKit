//
//  NNServiceTests.m
//  NNKit
//
//  Created by Scott Perry on 10/18/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NNServiceManager.h"
#import "NNService.h"


/*
 C -> A
 C -> B
 B -> A
 
 Start order: A, B, C
 Stop order: C, B, A
 */

static BOOL serviceARunning = NO;
static BOOL serviceBRunning = NO;
static BOOL serviceCRunning = NO;

@interface TestServiceA : NNService @end
@implementation TestServiceA
- (NNServiceType)serviceType { return NNServiceTypeOnDemand; }
- (void)startService {
    NSAssert(!serviceARunning, @"");
    serviceARunning = YES;
}
- (void)stopService {
    NSAssert(!serviceCRunning, @"");
    NSAssert(!serviceBRunning, @"");
    NSAssert(serviceARunning, @"");
    serviceARunning = NO;
}
@end

@interface TestServiceB : NNService @end
@implementation TestServiceB
- (NNServiceType)serviceType { return NNServiceTypePersistent; }
- (NSSet *)dependencies { return [NSSet setWithObject:[TestServiceA self]]; }
- (void)startService {
    NSAssert(serviceARunning, @"");
    NSAssert(!serviceBRunning, @"");
    NSAssert(!serviceCRunning, @"");
    serviceBRunning = YES;
}
- (void)stopService {
    NSAssert(serviceBRunning, @"");
    serviceBRunning = NO;
}
@end

@interface TestServiceC : NNService @end
@implementation TestServiceC
- (NNServiceType)serviceType { return NNServiceTypePersistent; }
- (NSSet *)dependencies { return [NSSet setWithArray:@[[TestServiceA self], [TestServiceB self]]]; }
- (void)startService {
    NSAssert(serviceARunning, @"");
    NSAssert(serviceBRunning, @"");
    NSAssert(!serviceCRunning, @"");
    serviceCRunning = YES;
}
- (void)stopService {
    NSAssert(serviceCRunning, @"");
    serviceCRunning = NO;
}
@end

// Service D has no dependencies, is always running
static BOOL serviceDRunning = NO;
@interface TestServiceD : NNService @end
@implementation TestServiceD
- (NNServiceType)serviceType { return NNServiceTypePersistent; }
- (void)startService { NSAssert(!serviceDRunning, @""); serviceDRunning = YES; }
- (void)stopService { NSAssert(serviceDRunning, @""); serviceDRunning = NO; }
@end

@interface NNServiceTests : XCTestCase

@end

@implementation NNServiceTests

- (void)testBasic
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceD self]];
    XCTAssertTrue(serviceDRunning, @"");
    manager = nil;
    XCTAssertFalse(serviceDRunning, @"");
}

- (void)testCustodyDispute
{
    NNServiceManager *manager1 = [NNServiceManager new];
    NNServiceManager *manager2 = [NNServiceManager new];
    [manager1 registerService:[TestServiceD self]];
    // Manager 2 can't claim manager 1's service
    XCTAssertThrows([manager2 registerService:[TestServiceD self]], @"");
    // But manager 1's registration is idempotent
    XCTAssertNoThrow([manager1 registerService:[TestServiceD self]], @"");
}

- (void)testDependencies
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceA self]];
    [manager registerService:[TestServiceB self]];
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    [manager subscribeToService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager subscribeToService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager unsubscribeFromService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager registerService:[TestServiceC self]];
    XCTAssertTrue(serviceCRunning, @"");
    [manager unsubscribeFromService:[TestServiceA self]];
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    XCTAssertFalse(serviceCRunning, @"");
    [manager subscribeToService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    XCTAssertTrue(serviceCRunning, @"");
    manager = nil;
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    XCTAssertFalse(serviceCRunning, @"");
}

@end
