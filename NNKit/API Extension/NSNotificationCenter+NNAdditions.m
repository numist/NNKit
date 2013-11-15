//
//  NSNotificationCenter+NNAdditions.m
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NSNotificationCenter+NNAdditions.h"

#import "_NNWeakObserverProxy.h"


@implementation NSNotificationCenter (NNAdditions)

- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;
{
    [self addObserver:[_NNWeakObserverProxy weakObserverProxyWithObserver:observer notificationCenter:self] selector:aSelector name:aName object:anObject];
}

@end
