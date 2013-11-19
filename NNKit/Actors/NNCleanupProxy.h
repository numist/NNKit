//
//  NNCleanupProxy.h
//  NNKit
//
//  Created by Scott Perry on 11/18/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNCleanupProxy : NSProxy

+ (NNCleanupProxy *)cleanupProxyForTarget:(id)target;

@property (nonatomic, readwrite, copy) void (^cleanupBlock)();

@end
