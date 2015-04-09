//
//  NNTimer.m
//  NNKit
//
//  Created by Scott Perry on 04/22/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNTimer.h"


@interface NNTimer ()

@property (nonatomic, readwrite, assign) NSUInteger mutationCounter;
@property (nonatomic, readonly, strong) dispatch_queue_t queue;
@property (nonatomic, readonly, strong) dispatch_block_t job;

- (void)_enqueueNextJob;

@end


@implementation NNTimer

+ (NNTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(dispatch_block_t)block queue:(dispatch_queue_t)queue;
{
    NNTimer *result = [NNTimer new];
    
    result->_timeInterval = seconds;
    result->_job = block;
    result->_queue = queue;
    [result _enqueueNextJob];
    return result;
}

+ (NNTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo queue:(dispatch_queue_t)queue;
{
    NNTimer *result = [self scheduledTimerWithTimeInterval:seconds
                                                     block:nil
                                                     queue:queue];
    
    __weak id weakTarget = target;
    __weak NNTimer *weakTimer = result;
    result->_job = ^{
        __strong id strongTarget = weakTarget;
        __strong NNTimer *strongTimer = weakTimer;
        if (!strongTarget || !strongTimer) { return; }
        
        // Calling the IMP directly instead of using performSelector: or
        // performSelector:withObject: in order to safely shut up the compiler
        // warning about potentially-leaked objects.
        IMP imp = [strongTarget methodForSelector:aSelector];
        void (*imp1)(id, SEL, id) = (void *)imp;
        imp1(strongTarget, aSelector, strongTimer);
    };
    
    result->_userInfo = userInfo;
    
    return result;
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval;
{
    self->_timeInterval = timeInterval;
    self.mutationCounter++;
    [self _enqueueNextJob];
}

// -fire makes two mutually-exclusive promises. One is that the job is executed
// synchronously, the other, less-obvious, promise is that the job is run on
// the same queue (or in NSTimer's case, run loop) as the scheduled firings.
// NSTimer opts for the simplest solution of keeping the synchronicity
// guarantee, and so does NNTimer.
- (void)fire;
{
    self.job();
}

- (void)_enqueueNextJob;
{
    NSTimeInterval nonNegativeTimeInterval = self.timeInterval >= 0.
    ? self.timeInterval : 0.;
    int64_t delta = nonNegativeTimeInterval * NSEC_PER_SEC;
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, delta);
    
    NSUInteger mutationsAtSchedulingTime = self.mutationCounter;
    __weak __typeof(self) weakSelf = self;
    dispatch_block_t block = ^{
        __strong __typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf) { return; }
        if (mutationsAtSchedulingTime != strongSelf.mutationCounter) { return; }
        
        [strongSelf fire];
        [strongSelf _enqueueNextJob];
    };
    
    dispatch_after(delay, self.queue, block);
}

@end
