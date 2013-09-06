//
//  NNDelegateProxy.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNDelegateProxy.h"

#import "despatch.h"


@implementation NNDelegateProxy

+ (id)proxyWithDelegate:(id)delegate protocol:(Protocol *)protocol;
{
    if (protocol && delegate) {
        NSAssert([delegate conformsToProtocol:protocol], @"Object %@ does not conform to protocol %@", delegate, NSStringFromProtocol(protocol));
    }

    NNDelegateProxy *proxy = [self alloc];
    proxy.delegate = delegate;
    return proxy;
}

// Helper function to provide an autoreleasing reference to the delegate property
- (id)strongDelegate;
{
    id delegate = self.delegate;
    return delegate;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [self.strongDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    despatch_sync_main_reentrant(^{
        [invocation invokeWithTarget:self.strongDelegate];
    });
}

@end
