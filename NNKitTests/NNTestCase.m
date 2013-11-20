//
//  NNTestCase.m
//  NNKit
//
//  Created by Scott Perry on 11/20/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNTestCase.h"

#import <mach/mach.h>


static size_t report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr != KERN_SUCCESS ) {
        @throw [NSException exceptionWithName:@"wtf" reason:[NSString stringWithFormat:@"Error with task_info(): %s", mach_error_string(kerr)] userInfo:nil];
    }
    return info.resident_size;
}


@interface NNTestCase ()

@end


@implementation NNTestCase

- (BOOL)testForMemoryLeaksWithBlock:(void (^)())block iterations:(size_t)iterations;
{
    XCTAssertTrue(iterations > 4096, @"Memory leak tests are not accurate with iteration counts less than 4096!");
    
    size_t bytes_expected = iterations;
    size_t memory_usage_at_start = report_memory();
    
    while (--iterations != 0) {
        @autoreleasepool {
            block();
        }
    }
    
    size_t bytes_actual = report_memory() - memory_usage_at_start;
    BOOL memory_usage_is_good = bytes_actual < bytes_expected;
    NSLog(@"Memory usage increased by %zu bytes by end of test", bytes_actual);
    XCTAssertTrue(memory_usage_is_good, @"Memory usage increased by %zu bytes by end of test (expected < %zu)", bytes_actual, bytes_expected);
    
    return memory_usage_is_good;
}

@end
