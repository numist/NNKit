//
//  NNMultiDispatchManager.h
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNMultiDispatchManager : NSObject

@property (nonatomic, assign, readwrite, getter = isEnabled, setter = setIsEnabled:) BOOL enabled;

- (instancetype)initWithProtocol:(Protocol *)protocol;

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;

@end
