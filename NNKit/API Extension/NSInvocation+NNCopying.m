//
//  NSInvocation+NNCopying.m
//  NNKit
//
//  Created by Scott Perry on 03/10/14.
//  Copyright (c) 2014 Scott Perry. All rights reserved.
//

#import "NSInvocation+NNCopying.h"

@implementation NSInvocation (NNCopying)

- (instancetype)nn_copy;
{
    NSMethodSignature *signature = [self methodSignature];
    NSUInteger const arguments = signature.numberOfArguments;
    
    NSInvocation *result = [NSInvocation invocationWithMethodSignature:signature];
    
    void *heapBuffer = NULL;
    size_t heapBufferSize = 0;
    
    NSUInteger alignp = 0;
    for (NSUInteger i = 0; i < arguments; i++) {
        char *type = [signature getArgumentTypeAtIndex:i];
        NSGetSizeAndAlignment(type, NULL, &alignp);
        
        if (alignp > heapBufferSize) {
            heapBuffer = heapBuffer
                       ? realloc(heapBuffer, alignp)
                       : malloc(alignp);
            heapBufferSize = alignp;
        }
        
        [self getArgument:heapBuffer atIndex:i];
		[result setArgument:heapBuffer atIndex:i];
    }
    
    if (heapBuffer) {
        free(heapBuffer);
    }

    return result;
}

@end
