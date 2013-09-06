//
//  NNDelegateProxyTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@protocol MYClassDelegate <NSObject>

- (void)objectCalledDelegateMethod:(id)obj;

@end


@interface NNDelegateProxyTests : XCTestCase <MYClassDelegate>

@end


@interface MYClass : NSObject

@property (strong) id<MYClassDelegate> delegateProxy;

@end

@implementation MYClass

- (instancetype)initWithDelegate:(id)delegate;
{
    if (!(self = [super init])) { return nil; }
    
    _delegateProxy = [NNDelegateProxy proxyWithDelegate:delegate protocol:@protocol(MYClassDelegate)];
    
    return self;
}

- (void)globalAsync;
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

- (void)globalSync;
{
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

- (void)mainAsync;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegateProxy objectCalledDelegateMethod:self];
    });
}

@end


static BOOL delegateMessageReceived;


@implementation NNDelegateProxyTests

- (void)setUp
{
    [super setUp];
    
    delegateMessageReceived = NO;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGlobalAsync;
{
    [[[MYClass alloc] initWithDelegate:self] globalAsync];
    
    while (!delegateMessageReceived) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)testGlobalSync;
{
    [[[MYClass alloc] initWithDelegate:self] globalSync];
    XCTAssertTrue(delegateMessageReceived, @"Delegate message was not received synchronously!");
}

- (void)testMainAsync;
{
    [[[MYClass alloc] initWithDelegate:self] mainAsync];
    
    while (!delegateMessageReceived) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

#pragma mark MYClassDelegate

- (void)objectCalledDelegateMethod:(id)obj;
{
    XCTAssertTrue([[NSThread currentThread] isMainThread], @"Delegate message was not dispatched on the main queue!");
    delegateMessageReceived = YES;
}

@end
