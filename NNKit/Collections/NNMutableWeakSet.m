//
//  NNMutableWeakSet.m
//  NNKit
//
//  Created by Scott Perry on 11/15/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNMutableWeakSet.h"

#import "NNCleanupProxy.h"


@interface NNMutableWeakSet ()

@property (nonatomic, readonly, strong) NSMutableSet *backingStore;

- (void)_removeObjectAllowingNil:(id)object;

@end


@interface _NNWeakArrayTombstone : NSObject
@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly, assign) NSUInteger hash;
@end
@implementation _NNWeakArrayTombstone
+ (_NNWeakArrayTombstone *)tombstoneWithTarget:(id)target;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone new];
    tombstone->_target = target;
    return tombstone;
}

@synthesize hash = _hash;
- (NSUInteger)hash;
{
    if (!self->_hash) {
        @synchronized(self) {
            if (!self->_hash) {
                id target = self.target;
                self->_hash = [target hash];
            }
        }
    }
    
    return self->_hash;
}

- (BOOL)isEqual:(id)object;
{
    id target = self.target;
    if ([target isEqual:object]) { return YES; }
    return (uintptr_t)object == (uintptr_t)self;
}
@end


/**
 
 collection -> tombstone                        // Unavoidable. The whole point of this exercise.
 tombstone -> object [style = "dotted"];        // Obvious.
 cleanup -> tombstone [style = "dotted"];         // For removing the tombstone from the collection.
 cleanup -> collection [style = "dotted"];        // For removing the tombstone from the collection.
 object -> cleanup;                               // Object association, the only strong reference to the proxy.
 object -> tombstone [style = "dotted];         // Object association so the collection can look at the object and find the tombstone.
 
 */


@implementation NNMutableWeakSet

- (instancetype)initWithCapacity:(NSUInteger)numItems;
{
    if (!(self = [super init])) { return nil; }
    
    self->_backingStore = [[NSMutableSet alloc] initWithCapacity:numItems];
    
    return self;
}

- (id)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_backingStore = [[NSMutableSet alloc] init];
    
    return self;
}

#pragma mark NSSet

- (NSUInteger)count;
{
    return self.backingStore.count;
}

- (id)member:(id)object;
{
    return ((_NNWeakArrayTombstone *)[self.backingStore member:object]).target;
}

- (NSEnumerator *)objectEnumerator;
{
    @throw nil;
}

#pragma mark NSMutableSet

- (void)addObject:(id)object;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone tombstoneWithTarget:object];
    NNCleanupProxy *proxy = [NNCleanupProxy cleanupProxyForTarget:object];
    
    __weak NNMutableWeakSet *weakCollection = self;
    __weak _NNWeakArrayTombstone *weakTombstone = tombstone;
    proxy.cleanupBlock = ^{
        NNMutableWeakSet *collection = weakCollection;
        [collection _removeObjectAllowingNil:weakTombstone];
    };
    
    [self.backingStore addObject:tombstone];
}

- (void)removeObject:(id)object;
{
    [self.backingStore removeObject:object];
}

#pragma mark Private

- (void)_removeObjectAllowingNil:(id)object;
{
    if (!object) { return; }
    
    [self.backingStore removeObject:object];
}

@end
