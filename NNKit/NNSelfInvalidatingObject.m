//
//  NNSelfInvalidatingObject.m
//  Switch
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//
//  Requires -fno-objc-arc
//

#import "NNSelfInvalidatingObject.h"

#import <assert.h>


@interface NNSelfInvalidatingObject () {
    _Bool _valid;
}

@property (nonatomic, assign) long refCount;

@end


@implementation NNSelfInvalidatingObject

#pragma mark NSObject

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_refCount = 0;
    self->_valid = true;
    
    /*
     * -invalidate supports two conditions:
     *   * invalidate may be called before the refCount hits zero, in which case the object should survive until its natural death.
     *   * invalidate may be called at refCount zero, in which case the object should survive until the end of the current runloop.
     * To satisfy both of these constraints, retain/release messages are forwarded to super and one extra retain is made (here) balanced by an autorelease in -invalidate to keep the object alive while it is still valid/invalidating.
     * Calling dealloc directly is an error and is not supported.
     */
    [self retain];
    
    return self;
}

- (instancetype)retain;
{
    @synchronized(self) {
        ++self.refCount;
    }
    [self retain];
    return self;
}

- (oneway void)release;
{
    @synchronized(self) {
        --self.refCount;
    }
    [self release];
}

- (oneway void)dealloc;
{
    if (self->_valid) {
        @throw [NSException exceptionWithName:@"Nope" reason:@"Nope, don't call dealloc directly ever" userInfo:nil];
    }

    [super dealloc];
}

#pragma mark NNSelfInvalidatingObject

- (void)invalidate;
{
    @synchronized(self) {
        if (self->_valid) {
            self->_valid = false;
            [self autorelease];
        }
    }
}

#pragma mark Internal

- (void)setRefCount:(long)refCount;
{
    self->_refCount = refCount;
    
    if (!refCount && self->_valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invalidate];
        });
    }
}

@end
