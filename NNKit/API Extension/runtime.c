//
//  runtime.c
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include "runtime.h"

#include <string.h>
#include <stdlib.h>


BOOL nn_selector_belongsToProtocol(SEL selector, Protocol *protocol, BOOL *requiredPtr, BOOL *instancePtr)
{
    BOOL required = requiredPtr ? !!*requiredPtr : NO;
    BOOL instance = instancePtr ? !!*instancePtr : NO;

    for (int i = 0; i < (1 << 2); ++i) {
        BOOL checkRequired = required ^ (i & 1);
        BOOL checkInstance = instance ^ ((i & (1 << 1)) >> 1);
        
        struct objc_method_description hasMethod = protocol_getMethodDescription(protocol, selector, checkRequired, checkInstance);
        if (hasMethod.name || hasMethod.types) {
            if (requiredPtr) {
                *requiredPtr = checkRequired;
            }
            if (instancePtr) {
                *instancePtr = checkInstance;
            }
            return YES;
        }
    }
    
    return NO;
}
