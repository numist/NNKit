//
//  NNWeakObserverTests.m
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


static NSString *notificationName = @"somenotification";


@interface _NNWeakObserverTestObserver : NSObject
@end
@implementation _NNWeakObserverTestObserver
- (void)notify:(NSNotification *)note;
{
    @throw [NSException exceptionWithName:notificationName reason:@"BECAUSE I WANNA" userInfo:nil];
}
- (void)dealloc;
{
    NSLog(@"Destroyed object!");
}
@end


@interface NNWeakObserverTests : XCTestCase

@end


@implementation NNWeakObserverTests

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

- (void)testExample
{
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) _NNWeakObserverTestObserver *observer = [_NNWeakObserverTestObserver new];
        [[NSNotificationCenter defaultCenter] addWeakObserver:observer selector:@selector(notify:) name:notificationName object:nil];
        XCTAssertThrows([[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self], @"");
    }
    XCTAssertNoThrow([[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self], @"");
}

@end
