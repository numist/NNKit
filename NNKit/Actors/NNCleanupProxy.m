//
//  NNCleanupProxy.m
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNCleanupProxy.h"

#import <objc/runtime.h>


@interface NNCleanupProxy ()

@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly, strong) NSMutableDictionary *signatureCache;

@end


@implementation NNCleanupProxy

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target;
{
    NNCleanupProxy *result = [NNCleanupProxy alloc];
    result->_target = target;
    result->_signatureCache = [NSMutableDictionary new];
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
    NSMethodSignature *signature = [self.signatureCache objectForKey:NSStringFromSelector(aSelector)];
    NSAssert(signature, @"RACE CONDITION: method signature for selector %@ was not already known. Cache signatures with cacheMethodSignatureForSelector: to avoid crashing when the proxy's target is deallocated.", NSStringFromSelector(aSelector));

    if (!signature) {
        signature = [self _cacheMethodSignatureForSelector:aSelector];
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    invocation.target = self.target;
    [invocation invoke];
}

#pragma mark NNCleanupProxy

- (void)cacheMethodSignatureForSelector:(SEL)aSelector;
{
    (void)[self _cacheMethodSignatureForSelector:aSelector];
}

#pragma mark Private

- (NSMethodSignature *)_cacheMethodSignatureForSelector:(SEL)aSelector;
{
    NSMethodSignature *signature = nil;
    
    // XXX: rdar://15478132 means no explicit local strongification here due to retain leak :(
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wreceiver-is-weak"
    signature = [self.target methodSignatureForSelector:aSelector];
    #pragma clang diagnostic pop

    if (signature) {
        [self.signatureCache setObject:signature forKey:NSStringFromSelector(aSelector)];
    }
    
    return signature;
}

@end
