//
//  nn_autofreeTests.m
//  NNKit
//
//  Created by Scott Perry on 11/20/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNTestCase.h"

#import <NNKit/NNKit.h>


@interface nn_autofreeTests : NNTestCase

@end


@implementation nn_autofreeTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    [self testForMemoryLeaksWithBlock:^{
        nn_autofree(malloc(2));
    } iterations:1e5];
}

@end
