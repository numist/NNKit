//
//  despatch.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

void despatch_sync_main_reentrant(dispatch_block_t block)
{
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
