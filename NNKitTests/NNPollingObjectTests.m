//
//  NNPollingObjectTests.m
//  NNKit
//
//  Created by Scott Perry on 09/06/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@interface NNPollingObjectTests : XCTestCase

@end


@interface NNTestObject : NNPollingObject
@end
@implementation NNTestObject

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    self.interval = 0.0001;
    return self;
}

- (void)main;
{
    [self postNotification:nil];
}

@end


static int iterations;


@implementation NNPollingObjectTests

- (void)setUp
{
    [super setUp];
    
    iterations = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectNotification:) name:[NNTestObject notificationName] object:nil];
}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super tearDown];
}

- (void)testBasicPolling
{
    NNTestObject *obj = [NNTestObject new];
    
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.5];
    while ([[NSDate date] compare:until] == NSOrderedAscending && !iterations) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    XCTAssert(iterations > 0, @"Polling object iterated zero times!");
    [obj self];
}

- (void)testZeroInterval
{
    NNTestObject *obj = [NNTestObject new];
    obj.interval = 0.0;
    
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while ([[NSDate date] compare:until] == NSOrderedAscending && iterations < 2) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    XCTAssert(iterations == 1, @"Polling object iterated more than once!");
    [obj self];
}

- (void)testObjectDeath
{
    @autoreleasepool {
        NNTestObject *obj = [NNTestObject new];
        
        NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.1];
        while ([[NSDate date] compare:until] == NSOrderedAscending && !iterations) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
        }
        [obj self];
    }
    iterations = 0;
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while ([[NSDate date] compare:until] == NSOrderedAscending && !iterations) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    XCTAssert(iterations == 0, @"Object continued polling after it was released!");
}

- (void)objectNotification:(NSNotification *)notification;
{
    XCTAssert([[NSThread currentThread] isMainThread], @"Poll notification was not dispatched on the main thread!");
    
    iterations++;
}

@end
