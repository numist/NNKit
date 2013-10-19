//
//  NNServiceManager.h
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <NNKit/NNService.h>


@interface NNServiceManager : NSObject

+ (NNServiceManager *)sharedManager;

//- (void)registerAllPossibleServices;
- (void)registerService:(Class)service;
- (id<NNService>)instanceForService:(Class)service;

// On-demand service subscription.
- (void)subscribeToService:(Class)service;
- (void)unsubscribeFromService:(Class)service;

@end
