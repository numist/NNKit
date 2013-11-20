//
//  NNTestCase.h
//  NNKit
//
//  Created by Scott Perry on 11/20/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface NNTestCase : XCTestCase

- (BOOL)testForMemoryLeaksWithBlock:(void (^)())block iterations:(size_t)iterations;

@end
