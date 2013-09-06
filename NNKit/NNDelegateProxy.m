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
    
    // Async oneway dispatch isn't as useful as it used to be since events are now always dispatched on the main thread—any code performing a long operation would need to dispatch off of the main thread to avoid blocking application event dispatch anyway.
#ifdef NNKIT_CONCURRENCY_SUPPORT_ASYNC_ONEWAY
    NSMethodSignature *signature = [self.strongDelegate methodSignatureForSelector:invocation.selector];
    if (signature.isOneway) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
#else
    {
#endif
        if (despatch_lock_is_held(dispatch_get_main_queue())) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
}

@end
