//
//  NNDelegateProxyTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
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

- (void)invalid;
{
    [(id)self.delegateProxy willChangeValueForKey:@""];
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

- (void)testInvalidDelegateMethod;
{
    XCTAssertThrows([[[MYClass alloc] initWithDelegate:self] invalid], @"Invalid delegate method was allowed to pass through!");
}

#pragma mark MYClassDelegate

- (void)objectCalledDelegateMethod:(id)obj;
{
    XCTAssertTrue([[NSThread currentThread] isMainThread], @"Delegate message was not dispatched on the main queue!");
    delegateMessageReceived = YES;
}

@end
