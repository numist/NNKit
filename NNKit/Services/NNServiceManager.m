//
//  NNServiceManager.m
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNServiceManager.h"

#import <objc/runtime.h>

#import "NNCleanupProxy.h"
#import "NNMultiDispatchManager+Protected.h"
#import "NNMutableWeakSet.h"
#import "NNService+Protected.h"


static NSMutableSet *claimedServices;


static BOOL _serviceIsValid(Class service)
{
    return [service isSubclassOfClass:[NNService class]];
}


@interface _NNServiceInfo : NSObject

@property (nonatomic, strong, readonly) NNMutableWeakSet *subscribers;
@property (nonatomic, assign, readonly) NNServiceType type;
@property (nonatomic, strong, readonly) NNService *instance;
@property (nonatomic, strong, readonly) NSSet *dependencies;
@property (nonatomic, strong, readonly) Protocol *subscriberProtocol;

- (instancetype)initWithService:(Class)service;

@end


@implementation _NNServiceInfo

- (instancetype)initWithService:(Class)service;
{
    NSParameterAssert(_serviceIsValid(service));
    if (!(self = [super init])) { return nil; }
    
    self->_subscribers = [NNMutableWeakSet new];
    self->_instance = [service sharedService];
    self->_instance.subscriberDispatcher.enabled = NO;
    self->_type = self->_instance.serviceType;
    self->_dependencies = [self->_instance respondsToSelector:@selector(dependencies)] ? (self->_instance.dependencies ?: [NSSet set]) : [NSSet set];
    self->_subscriberProtocol = [self->_instance respondsToSelector:@selector(subscriberProtocol)] ? self->_instance.subscriberProtocol : @protocol(NSObject);

    return self;
}

@end


@interface NNServiceManager ()

// Class => _NNServiceInfo
@property (nonatomic, strong) NSMutableDictionary *lookup;
#define SERVICEINFO(service) ((_NNServiceInfo *)self.lookup[(service)])

// Class
@property (nonatomic, strong) NSMutableSet *runningServices;

// Class => NSMutableSet<Class>
@property (nonatomic, strong) NSMutableDictionary *dependantServices;

@end


@implementation NNServiceManager

#pragma mark - Initialization

+ (void)initialize;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        claimedServices = [NSMutableSet new];
    });
}

+ (NNServiceManager *)sharedManager;
{
    static NNServiceManager *_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [NNServiceManager new];
    });
    
    return _sharedManager;
}

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_lookup = [NSMutableDictionary new];
    self->_runningServices = [NSMutableSet new];
    self->_dependantServices = [NSMutableDictionary new];
    
    return self;
}

- (void)dealloc;
{
    while (self->_runningServices.count) {
        for (Class service in self->_runningServices) {
            if (SERVICEINFO(service).dependencies.count == 0) {
                [self _stopService:service];
                break;
            }
        }
    }
    
    @synchronized([NNServiceManager class]) {
        for (Class service in self->_lookup) {
            [claimedServices removeObject:service];
        }
    }
}

#pragma mark - NNServiceManager

- (void)registerService:(Class)service;
{
    NSParameterAssert(_serviceIsValid(service));
    if (SERVICEINFO(service)) {
        NSLog(@"Service %@ was already registered with %@", NSStringFromClass(service), self);
        return;
    }
    
    _NNServiceInfo *info = [[_NNServiceInfo alloc] initWithService:service];
    if (info.type == NNServiceTypeNone) { return; }
    
    @synchronized([NNServiceManager class]) {
        if ([claimedServices containsObject:service]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Service %@ already being managed", NSStringFromClass(service)] userInfo:nil];
        }
        [claimedServices addObject:service];
    }
    
    self.lookup[service] = info;

    for (Class dependency in info.dependencies) {
        NSMutableSet *deps = self.dependantServices[dependency];
        if (!deps) {
            self.dependantServices[dependency] = deps = [NSMutableSet new];
        }

        [deps addObject:service];
    }

    [self _startServiceIfReady:service];
}

- (NNService *)instanceForService:(Class)service;
{
    // May be nil if service is not registered!
    return SERVICEINFO(service).instance;
}

- (void)addSubscriber:(id)subscriber forService:(Class)service;
{
    NSParameterAssert(SERVICEINFO(service));
    NSParameterAssert([subscriber conformsToProtocol:SERVICEINFO(service).subscriberProtocol]);
    
    [SERVICEINFO(service).subscribers addObject:subscriber];
    [SERVICEINFO(service).instance.subscriberDispatcher addObserver:subscriber];
    __weak typeof(self) weakSelf = self;
    [NNCleanupProxy cleanupAfterTarget:subscriber withBlock:^{ dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        [self _stopServiceIfDone:service];
    }); }];
    [self _startServiceIfReady:service];
}

- (void)removeSubscriber:(id)subscriber forService:(Class)service;
{
    NSParameterAssert(SERVICEINFO(service));

    [SERVICEINFO(service).subscribers removeObject:subscriber];
    [SERVICEINFO(service).instance.subscriberDispatcher removeObserver:subscriber];
    [self _stopServiceIfDone:service];
}

#pragma mark Private

- (void)_startServiceIfReady:(Class)service;
{
    if ([self.runningServices containsObject:service]) {
        return;
    }
    
    if (SERVICEINFO(service).type == NNServiceTypeOnDemand && SERVICEINFO(service).subscribers.count == 0) {
        return;
    }
    
    if (![SERVICEINFO(service).dependencies isSubsetOfSet:self.runningServices]) {
        return;
    }

    [self _startService:service];
}

- (void)_stopServiceIfDone:(Class)service;
{
    // This is not needed for correctness, but let's avoid all that recursion if possible.
    if (![self.runningServices containsObject:service]) {
        return;
    }

    BOOL dependenciesMet = [SERVICEINFO(service).dependencies isSubsetOfSet:self.runningServices];
    BOOL serviceIsWanted = SERVICEINFO(service).type != NNServiceTypeOnDemand || SERVICEINFO(service).subscribers.count > 0;
    if (dependenciesMet && serviceIsWanted) {
        return;
    }
    
    [self _stopService:service];
}

- (void)_startService:(Class)service;
{
    NSParameterAssert(![self.runningServices containsObject:service]);

    NNService *instance = SERVICEINFO(service).instance;
    
    instance.subscriberDispatcher.enabled = YES;
    
    if ([instance respondsToSelector:@selector(startService)]) {
        [instance startService];
    }
    
    [self.runningServices addObject:service];
    
    for (Class dependantClass in self.dependantServices[service]) {
        [self _startServiceIfReady:dependantClass];
    }
}

- (void)_stopService:(Class)service;
{
    NSParameterAssert([self.runningServices containsObject:service]);
    
    NNService *instance = SERVICEINFO(service).instance;

    [self.runningServices removeObject:service];
    
    for (Class dependantClass in self.dependantServices[service]) {
        [self _stopServiceIfDone:dependantClass];
    }
    
    if ([instance respondsToSelector:@selector(stopService)]) {
        [instance stopService];
    }
    
    instance.subscriberDispatcher.enabled = NO;
}

@end
