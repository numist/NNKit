//
//  NNCleanupProxy.m
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNCleanupProxy.h"

#import <objc/runtime.h>


@interface NNCleanupProxy ()

@property (nonatomic, readonly, weak) id target;

@end


@implementation NNCleanupProxy

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target;
{
    NNCleanupProxy *result = [NNCleanupProxy alloc];
    result->_target = target;
    objc_setAssociatedObject(target, (__bridge void *)result, result, OBJC_ASSOCIATION_RETAIN);
    return result;
}

- (void)dealloc;
{
    if (self->_cleanupBlock) {
        self->_cleanupBlock();
    }
}

#pragma mark Message forwarding

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    // XXX: rdar://15478132 means no local strongification here due to retain leak :(
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wreceiver-is-weak"
    return [self.target methodSignatureForSelector:aSelector];
    #pragma clang diagnostic pop
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    invocation.target = self.target;
    [invocation invoke];
}

@end
