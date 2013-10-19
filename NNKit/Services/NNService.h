//
//  NNService.h
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(uint8_t, NNServiceType) {
    NNServiceTypeNone,
    NNServiceTypePersistent,
    NNServiceTypeOnDemand,
};


@protocol NNService <NSObject>
@required

+ (instancetype)sharedService;
- (NNServiceType)serviceType;
- (NSSet *)dependencies;

@optional
- (void)startService;
- (void)stopService;

@end


@interface NNService : NSObject <NNService>

@end
