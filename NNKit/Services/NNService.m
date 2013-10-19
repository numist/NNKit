//
//  NNService.m
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNService.h"

#import "NNServiceManager+Protected.h"


@implementation NNService

+ (instancetype)sharedService;
{
    static NSMutableDictionary *instances;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [NSMutableDictionary new];
    });
    
    id<NNService> result;
    
    @synchronized(instances) {
        result = [instances objectForKey:self];
        if (!result) {
            result = [self new];
            [instances setObject:result forKey:self];
        }
    }
    
    return result;
}

- (id<NSFastEnumeration>)notificationNames;
{
    return nil;
}

- (NNServiceType)serviceType;
{
    return NNServiceTypeNone;
}

- (id<NSFastEnumeration>)dependencies;
{
    return nil;
}

@end
