//
//  _NNWeakObserverProxy.h
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _NNWeakObserverProxy : NSProxy

+ (_NNWeakObserverProxy *)weakObserverProxyWithObserver:(id)notificationObserver notificationCenter:(NSNotificationCenter *)notificationCenter;

@end
