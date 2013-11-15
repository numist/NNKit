//
//  _NNWeakObserverProxy.m
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "_NNWeakObserverProxy.h"

#import <objc/runtime.h>


@interface _NNWeakObserverProxy ()

@property (atomic, readonly, weak) id notificationObserver;
@property (nonatomic, readonly, assign) NSMethodSignature *notificationMethodSignature;
@property (nonatomic, readonly, strong) NSNotificationCenter *notificationCenter;

@end


@implementation _NNWeakObserverProxy

#pragma mark - Initialization

+ (_NNWeakObserverProxy *)weakObserverProxyWithObserver:(id)observer selector:(SEL)aSelector notificationCenter:(NSNotificationCenter *)notificationCenter;
{
    return [[_NNWeakObserverProxy alloc] initWithObserver:observer selector:(SEL)aSelector notificationCenter:notificationCenter];
}

- (id)initWithObserver:(id)observer selector:(SEL)aSelector notificationCenter:(NSNotificationCenter *)notificationCenter;
{
    self->_notificationObserver = observer;
    self->_notificationMethodSignature = [observer methodSignatureForSelector:aSelector];
    self->_notificationCenter = notificationCenter;
    
    objc_setAssociatedObject(observer, (__bridge const void *)self, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return self;
}

- (void)dealloc;
{
    [self->_notificationCenter removeObserver:self];
}

#pragma mark Equality

- (NSUInteger)hash;
{
    return (NSUInteger)self;
}

- (BOOL)isEqual:(id)anObject;
{
    return (uintptr_t)anObject == (uintptr_t)self;
}

#pragma mark Message forwarding

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return self.notificationMethodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    invocation.target = self.notificationObserver;
    [invocation invoke];
}

@end
