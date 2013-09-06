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

+ (NNDelegateProxy *)proxyWithDelegate:(id)delegate;
{
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
    dispatch_block_t block = ^{ [invocation invoke]; };
    
    if (despatch_lock_is_held(dispatch_get_main_queue())) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
