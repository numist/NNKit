//
//  NSNotificationCenter+NNAdditions.m
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NSNotificationCenter+NNAdditions.h"

#import "NNCleanupProxy.h"


@implementation NSNotificationCenter (NNAdditions)

- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;
{
    NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:observer];
    __weak NSNotificationCenter *weakCenter = self;
    __unsafe_unretained NNCleanupProxy *unsafeProxy = proxy;
    proxy.cleanupBlock = ^{
        NSNotificationCenter *center = weakCenter;
        
        [center removeObserver:unsafeProxy name:aName object:anObject];
    };
    [self addObserver:proxy selector:aSelector name:aName object:anObject];
}

@end
