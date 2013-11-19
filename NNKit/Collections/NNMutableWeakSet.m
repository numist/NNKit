//
//  NNMutableWeakSet.m
//  NNKit
//
//  Created by Scott Perry on 11/15/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNMutableWeakSet.h"

#import "_NNWeakArrayTombstone.h"
#import "_NNMutableWeakSetEnumerator.h"
#import "NNCleanupProxy.h"


@interface NNMutableWeakSet ()

@property (nonatomic, readonly, strong) NSMutableSet *backingStore;

- (void)_removeObjectAllowingNil:(id)object;

@end


/**
 
 collection -> tombstone                    // Unavoidable. The whole point of this exercise.
 tombstone -> object [style = "dotted"];    // Obvious.
 cleanup -> tombstone [style = "dotted"];   // For removing the tombstone from the collection.
 cleanup -> collection [style = "dotted"];  // For removing the tombstone from the collection.
 object -> cleanup;                         // Object association, the only strong reference to the proxy.
 object -> tombstone [style = "dotted];     // Object association so the collection can look at the object and find the tombstone.
 
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
    return [[_NNMutableWeakSetEnumerator alloc] initWithMutableWeakSet:self];
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
