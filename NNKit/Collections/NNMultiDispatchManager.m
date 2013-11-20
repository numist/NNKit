//
//  NNMultiDispatchManager.m
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNMultiDispatchManager.h"

#import "NNMutableWeakSet.h"
#import "despatch.h"
#import "nn_autofree.h"
#import "runtime.h"


@interface NNMultiDispatchManager ()

@property (nonatomic, readonly, assign) Protocol *protocol;
@property (nonatomic, readonly, strong) NSMutableDictionary *signatureCache;
@property (nonatomic, readonly, strong) NNMutableWeakSet *observers;

@end


@implementation NNMultiDispatchManager

- (instancetype)initWithProtocol:(Protocol *)protocol;
{
    if (!(self = [super init])) { return nil; }
    
    self->_protocol = protocol;
    self->_signatureCache = [NSMutableDictionary new];
    [self _cacheMethodSignaturesForProcotol:protocol];
    self->_observers = [NNMutableWeakSet new];

    return self;
}

- (void)addObserver:(id)observer;
{
    NSParameterAssert([observer conformsToProtocol:self.protocol]);
    
    [self.observers addObject:observer];
}

- (void)removeObserver:(id)observer;
{
    [self.observers removeObject:observer];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
{
    return [self.signatureCache objectForKey:NSStringFromSelector(aSelector)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation;
{
    NSAssert(strstr(anInvocation.methodSignature.methodReturnType, "v"), @"Method return type must be void.");
    dispatch_block_t dispatch = ^{
        for (id obj in self.observers) {
            if ([obj respondsToSelector:anInvocation.selector]) {
                [anInvocation invokeWithTarget:obj];
            }
        }
    };
    if (anInvocation.methodSignature.isOneway) {
        [anInvocation retainArguments];
        dispatch_async(dispatch_get_main_queue(), dispatch);
    } else {
        despatch_sync_main_reentrant(dispatch);
    }
    
    anInvocation.target = nil;
    [anInvocation invoke];
}

#pragma mark Private

- (void)_cacheMethodSignaturesForProcotol:(Protocol *)protocol;
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
        [self _cacheMethodSignaturesForProcotol:adoptions[j]];
    }
}

@end
