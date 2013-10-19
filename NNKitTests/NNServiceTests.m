//
//  NNServiceTests.m
//  NNKit
//
//  Created by Scott Perry on 10/18/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
