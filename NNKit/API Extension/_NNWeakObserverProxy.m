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
@property (nonatomic, readonly, assign) Class observerClass;
@property (nonatomic, readonly, strong) NSNotificationCenter *notificationCenter;

@end


@implementation _NNWeakObserverProxy

#pragma mark - Initialization

+ (_NNWeakObserverProxy *)weakObserverProxyWithObserver:(id)notificationObserver notificationCenter:(NSNotificationCenter *)notificationCenter;
{
    return [[_NNWeakObserverProxy alloc] initWithObserver:notificationObserver notificationCenter:notificationCenter];
}

- (id)initWithObserver:(id)notificationObserver notificationCenter:(NSNotificationCenter *)notificationCenter;
{
    self->_notificationObserver = notificationObserver;
    // Or maybe object_getClass is more appropriate?
    self->_observerClass = [notificationObserver class];
    
    self->_notificationCenter = notificationCenter;
    
    objc_setAssociatedObject(notificationObserver, (__bridge const void *)self, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
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
    return anObject == self;
}

#pragma mark Message forwarding

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.observerClass instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    invocation.target = self.notificationObserver;
    [invocation invoke];
}

@end
