//
//  NNMultiDispatchManager.h
//  NNKit
//
//  Created by Scott Perry on 11/19/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <NNKit/NNMultiDispatchManager.h>


@class NNMutableWeakSet;


@interface NNMultiDispatchManager (Protected)

@property (nonatomic, readonly, strong) NNMutableWeakSet *observers;

@end
