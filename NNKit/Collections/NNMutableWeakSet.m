//
//  NNMutableWeakSet.m
//  NNKit
//
//  Created by Scott Perry on 11/15/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNMutableWeakSet.h"

#import <objc/runtime.h>


@interface NNMutableWeakSet ()

@property (nonatomic, readonly, strong) NSMutableSet *backingStore;

- (void)_removeTombstoneAllowingNil:(id)object;

@end


@interface _NNWeakArrayTombstone : NSObject
@property (nonatomic, readonly, weak) id target;
@end
@implementation _NNWeakArrayTombstone
+ (_NNWeakArrayTombstone *)tombstoneWithTarget:(id)target;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone new];
    tombstone->_target = target;
    return tombstone;
}
@end


@interface _NNWeakArrayCleanupObject : NSObject
@property (atomic, readonly, weak) _NNWeakArrayTombstone *tombstone;
@property (atomic, readonly, weak) NNMutableWeakSet *collection;
@end
@implementation _NNWeakArrayCleanupObject
+ (_NNWeakArrayCleanupObject *)cleanupProxyWithTombstone:(_NNWeakArrayTombstone *)tombstone collection:(NNMutableWeakSet *)collection;
{
    _NNWeakArrayCleanupObject *proxy = [_NNWeakArrayCleanupObject new];
    proxy->_tombstone = tombstone;
    proxy->_collection = collection;
    return proxy;
}
- (void)dealloc;
{
    // atomic properties retain/autorelease so this warning is invalid. Additionally, due to rdar://15478132, strongifying the property in a local variable causes the property to be retained and then not released, causing a memory leak.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wreceiver-is-weak"
    @autoreleasepool {
        [self.collection _removeTombstoneAllowingNil:self.tombstone];
    }
    #pragma clang diagnostic pop
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

#pragma mark NSSet

- (NSUInteger)count;
{
    return self.backingStore.count;
}

- (id)member:(id)object;
{
    @throw nil;
    // if associated tombstone object exists with a key of self, use it to find the member
}

- (NSEnumerator *)objectEnumerator;
{
    @throw nil;
}

#pragma mark NSMutableSet

- (void)addObject:(id)object;
{
    _NNWeakArrayTombstone *tombstone = [_NNWeakArrayTombstone tombstoneWithTarget:object];
    _NNWeakArrayCleanupObject *proxy = [_NNWeakArrayCleanupObject cleanupProxyWithTombstone:tombstone collection:self];
    // TODO: Fuuuuuuck I need to implement yet another self-cleaning weak reference API for this to work
    objc_setAssociatedObject(object, (__bridge void *)self, tombstone, OBJC_ASSOCIATION_ASSIGN);
    // Make the proxy's lifecycle dependant on the object it is shadowing.
    objc_setAssociatedObject(object, (__bridge void *)proxy, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)removeObject:(id)object;
{
    // get tombstone by looking up self against object's associations
    // remove tombstone from self
}

#pragma mark Private

- (void)_removeTombstoneAllowingNil:(id)object;
{
    if (!object) { return; }
    
    [self.backingStore removeObject:object];
}

@end
