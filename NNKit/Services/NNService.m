//
//  NNService.m
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

#import "NNService+Protected.h"

#import "NNServiceManager.h"
#import "NNMultiDispatchManager.h"


#import <objc/runtime.h>
#define NNMemoize(block) _NNMemoize(self, _cmd, block)
id _NNMemoize(id self, SEL _cmd, id (^block)()) {
    id result;
    void *key = (void *)((uintptr_t)(__bridge void *)self ^ (uintptr_t)(void *)_cmd ^ (uintptr_t)&_NNMemoize);
    
    @synchronized(self) {
        result = objc_getAssociatedObject(self, key);
        if (!result) {
            result = block();
            objc_setAssociatedObject(self, key, result, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
    }
    
    return result;
}


@interface NNService ()

@property (nonatomic, readonly, strong) NNMultiDispatchManager *subscriberDispatcher;

@end


@implementation NNService

+ (instancetype)sharedService;
{
    static NSMutableDictionary *instances;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [NSMutableDictionary new];
    });
    
    NNService *result;
    
    @synchronized(instances) {
        result = [instances objectForKey:self];
        if (!result) {
            result = [self new];
            [instances setObject:result forKey:self];
        }
    }
    
    return result;
}

+ (NNServiceType)serviceType;
{
    if ([self instancesRespondToSelector:_cmd]) {
        NSLog(@"%@: instance method %@ should be implemented as a class method", self, NSStringFromSelector(_cmd));
        return [[self sharedService] serviceType];
    }
    
    return NNServiceTypeNone;
}

+ (NSSet *)dependencies;
{
    if ([self instancesRespondToSelector:_cmd]) {
        NSLog(@"%@: instance method %@ should be implemented as a class method", self, NSStringFromSelector(_cmd));
        return [[self sharedService] dependencies];
    }

    return [NSSet set];
}

+ (Protocol *)subscriberProtocol;
{
    if ([self instancesRespondToSelector:_cmd]) {
        NSLog(@"%@: instance method %@ should be implemented as a class method", self, NSStringFromSelector(_cmd));
        return [[self sharedService] subscriberProtocol];
    }

    return @protocol(NSObject);
}

- (id)init;
{
    if (!(self = [super init])) { return nil; }
    
    self->_subscriberDispatcher = [[NNMultiDispatchManager alloc] initWithProtocol:self.class.subscriberProtocol];
    
    return self;
}

- (void)startService;
{
    NSAssert([[NSThread currentThread] isMainThread], @"Service must be started on the main thread");
}

- (void)stopService;
{
    NSAssert([[NSThread currentThread] isMainThread], @"Service must be stopped on the main thread");
}

@end
