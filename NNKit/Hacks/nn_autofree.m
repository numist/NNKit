//
//  nn_autofree.m
//  NNKit
//
//  Created by Scott Perry on 09/09/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "nn_autofree.h"

void *nn_autofree(void *ptr)
{
    if (ptr) {
        [NSData dataWithBytesNoCopy:ptr length:1 freeWhenDone:YES];
    }
    return ptr;
}
