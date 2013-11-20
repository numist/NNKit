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

#import <mach/mach.h>

#import "NNServiceManager.h"
#import "NNService+Protected.h"


static size_t report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr != KERN_SUCCESS ) {
        @throw [NSException exceptionWithName:@"wtf" reason:[NSString stringWithFormat:@"Error with task_info(): %s", mach_error_string(kerr)] userInfo:nil];
    }
    return info.resident_size;
}


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

// Service E depends on Service D, runs on demand
static BOOL serviceERunning = NO;
@protocol TestServiceEProtocol <NSObject>
- (void)foo:(id)sender;
@end
@interface TestServiceE : NNService @end
@implementation TestServiceE
- (NNServiceType)serviceType { return NNServiceTypeOnDemand; }
- (NSSet *)dependencies { return [NSSet setWithObject:[TestServiceD self]]; }
- (Protocol *)subscriberProtocol { return @protocol(TestServiceEProtocol); }
- (void)startService {
    serviceERunning = YES;
    [self sendMessage];
}
- (void)sendMessage;
{
    [(id)self.subscriberDispatcher foo:self];
}
- (void)stopService {
    serviceERunning = NO;
}
@end


unsigned eventsDispatched;


@interface TestServiceESubscriber : NSObject <TestServiceEProtocol>
@end
@implementation TestServiceESubscriber
- (void)foo:(id)sender;
{
    eventsDispatched++;
}
@end


@interface NNServiceTests : XCTestCase

@end

@implementation NNServiceTests

- (void)setUp;
{
    [super setUp];
    
    eventsDispatched = 0;
}

- (void)tearDown;
{
    // Give cleanup tasks scheduled on the main queue an opportunity to run.
    (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
}

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
    [manager addSubscriber:self forService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager addSubscriber:self forService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager removeSubscriber:self forService:[TestServiceA self]];
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    [manager addSubscriber:self forService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    [manager registerService:[TestServiceC self]];
    XCTAssertTrue(serviceCRunning, @"");
    [manager removeSubscriber:self forService:[TestServiceA self]];
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    XCTAssertFalse(serviceCRunning, @"");
    [manager addSubscriber:self forService:[TestServiceA self]];
    XCTAssertTrue(serviceARunning, @"");
    XCTAssertTrue(serviceBRunning, @"");
    XCTAssertTrue(serviceCRunning, @"");
    manager = nil;
    (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    XCTAssertFalse(serviceARunning, @"");
    XCTAssertFalse(serviceBRunning, @"");
    XCTAssertFalse(serviceCRunning, @"");
}

- (void)testWeakSubscribers
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceA self]];
    XCTAssertFalse(serviceARunning, @"");
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) id foo = [NSObject new];
        [manager addSubscriber:foo forService:[TestServiceA self]];
        XCTAssertTrue(serviceARunning, @"");
    }
    (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    XCTAssertFalse(serviceARunning, @"");
}

- (void)testSubscriberDispatch
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceD self]];
    [manager registerService:[TestServiceE self]];
    XCTAssertFalse(serviceERunning, @"");
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) TestServiceESubscriber *foo = [TestServiceESubscriber new];
        [manager addSubscriber:foo forService:[TestServiceE self]];
        XCTAssertTrue(serviceERunning, @"");
        XCTAssertEqual(eventsDispatched, (unsigned)1, @"");
        [(TestServiceE *)[manager instanceForService:[TestServiceE self]] sendMessage];
        XCTAssertEqual(eventsDispatched, (unsigned)2, @"");
    }
    (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    XCTAssertFalse(serviceERunning, @"");
}

- (void)testSubscriberDispatchWhenServiceStopped
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceE self]];
    XCTAssertFalse(serviceERunning, @"");
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) TestServiceESubscriber *foo = [TestServiceESubscriber new];
        [manager addSubscriber:foo forService:[TestServiceE self]];
        XCTAssertFalse(serviceERunning, @"");
        [(TestServiceE *)[manager instanceForService:[TestServiceE self]] sendMessage];
        XCTAssertEqual(eventsDispatched, (unsigned)0, @"");
    }
    (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    XCTAssertFalse(serviceERunning, @"");
}

- (void)testMemoryLeaks;
{
    NNServiceManager *manager = [NNServiceManager new];
    [manager registerService:[TestServiceD self]];
    [manager registerService:[TestServiceE self]];
    XCTAssertFalse(serviceERunning, @"");
    __attribute__((objc_precise_lifetime)) TestServiceESubscriber *foo = [TestServiceESubscriber new];
    
    unsigned iterations;
    size_t memoryUsageAtStart = report_memory();
    for (iterations = 0; iterations < 1e4; ++iterations) {
        @autoreleasepool {
            [manager addSubscriber:foo forService:[TestServiceE self]];
            [manager removeSubscriber:foo forService:[TestServiceE self]];
            // Allow the main dispatch queue an opportunity to run its async blocks
            (void)[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
        }
    }
    
    size_t bytes = report_memory() - memoryUsageAtStart;
    XCTAssertFalse(bytes > 1e4, @"Memory usage increased by %zu bytes by end of test", bytes);
}

@end
