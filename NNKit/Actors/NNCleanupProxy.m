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

#import "nn_autofree.h"


@interface NNCleanupProxy ()

@property (nonatomic, readonly, weak) NSObject *target;
@property (nonatomic, readonly, assign) NSUInteger hash;
@property (nonatomic, readonly, strong) NSMutableDictionary *signatureCache;

@end


// XXX: rdar://15478132 means no explicit local strongification here due to retain leak :(
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreceiver-is-weak"

@implementation NNCleanupProxy

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target;
{
    NNCleanupProxy *result = [NNCleanupProxy alloc];
    result->_target = target;
    result->_signatureCache = [NSMutableDictionary new];
    objc_setAssociatedObject(target, (__bridge void *)result, result, OBJC_ASSOCIATION_RETAIN);
    return result;
}

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target conformingToProtocol:(Protocol *)protocol;
{
    NSParameterAssert([target conformsToProtocol:protocol]);
    
    NNCleanupProxy *result = [NNCleanupProxy cleanupProxyForTarget:target];
    [result cacheMethodSignaturesForProcotol:protocol];
    
    return result;
}

- (void)dealloc;
{
    if (self->_cleanupBlock) {
        self->_cleanupBlock();
    }
}

#pragma mark NSObject protocol

@synthesize hash = _hash;
- (NSUInteger)hash;
{
    if (!self->_hash) {
        @synchronized(self) {
            if (!self->_hash) {
                self->_hash = self.target.hash;
            }
        }
    }
    
    return self->_hash;
}

- (BOOL)isEqual:(id)object;
{
    return [object isEqual:self.target];
}

#pragma mark Message forwarding

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [self.signatureCache objectForKey:NSStringFromSelector(aSelector)];

    NSAssert(signature, @"Selector %@ was not pre-declared to proxy. Cache signatures before use with cacheMethodSignatureForSelector: while the target is still valid.", NSStringFromSelector(aSelector));
    
    if (!signature) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Unrecognized selector sent to instance %p", self] userInfo:nil];
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
    NSMethodSignature *signature = [self.target methodSignatureForSelector:aSelector];

    if (signature) {
        [self.signatureCache setObject:signature forKey:NSStringFromSelector(aSelector)];
    } else {
        NSAssert(!self.target, @"Target was non-nil, but method signature lookup failed anyway?");
        
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Unable to get method signature from target of instance %p", self] userInfo:nil];
    }
}

// This could be faster/lighter if method signature was late-binding, at the cost of higher complexity.
- (void)cacheMethodSignaturesForProcotol:(Protocol *)protocol;
{
    unsigned int totalCount;
    for (uint8_t i = 0; i < 1 << 1; ++i) {
        struct objc_method_description *methodDescriptions = nn_autofree(protocol_copyMethodDescriptionList(protocol, i & 1, YES, &totalCount));
        
        for (unsigned j = 0; j < totalCount; j++) {
            struct objc_method_description *methodDescription = methodDescriptions + j;
            [self.signatureCache setObject:[NSMethodSignature signatureWithObjCTypes:methodDescription->types] forKey:NSStringFromSelector(methodDescription->name)];
        }
    }

    // Recurse to include other protocols to which this protocol adopts
    Protocol * __unsafe_unretained *adoptions = protocol_copyProtocolList(protocol, &totalCount);
    for (unsigned j = 0; j < totalCount; j++) {
        [self cacheMethodSignaturesForProcotol:adoptions[j]];
    }
}

@end

#pragma clang diagnostic pop
