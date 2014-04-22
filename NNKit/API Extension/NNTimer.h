//
//  NNTimer.h
//  NNKit
//
//  Created by Scott Perry on 04/22/14.
//  Copyright (c) 2014 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNTimer : NSObject

+ (NNTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(dispatch_block_t)block queue:(dispatch_queue_t)queue;
+ (NNTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo queue:(dispatch_queue_t)queue;

@property (nonatomic, assign, readwrite) NSTimeInterval timeInterval;
@property (nonatomic, strong, readwrite) id userInfo;

- (void)fire;

@end
