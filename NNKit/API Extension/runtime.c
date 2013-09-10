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


// Like the other class_copy* functions, the caller must free the return value of this function with free()
objc_property_attribute_t *nn_property_copyAttributeList(objc_property_t property, unsigned int *outCount)
{
    if (outCount) {
        *outCount = 0;
    }
    
    // For more information about the property type string, see the Declared Properties section of the Objective-C Runtime Programming Guide
    const char *constAttributes = property_getAttributes(property);
    if (!constAttributes) {
        return NULL;
    }
    
    /**
     *  ┏━━━━━━━━┓
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────┨
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────┨
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────┨
     *  ┃...             ┃
     *  ┠────────┨
     *  ┃NULL            ┃
     *  ┃NULL            ┃
     *  ┠────────┨
     *  ┃N0Valueue0N0Valu┃
     *  ┃e0N0Valueueueue0┃
     *  ┃...             ┃
     *  ┗━━━━━━━━┛
     */
    
    // Get the number of attributes
    size_t attributeCount = strlen(constAttributes) ? 1 : 0;
    for (unsigned i = 0; constAttributes[i] != '\0'; i++) {
        if (constAttributes[i] == ',') {
            attributeCount++;
        }
    }
    
    // Calculate and allocate the attribute list to be returned to the caller
    size_t attributeListSize = (attributeCount + 1) * sizeof(objc_property_attribute_t); // The list of attributes, plus an extra attribute containing NULL for its name and value.
    size_t attributeStringsSize = (strlen(constAttributes) + attributeCount + 1) * sizeof(char); // The attribute names and values, plus the extra necessary NUL terminators.
    objc_property_attribute_t *attributeList = calloc(attributeListSize + attributeStringsSize, 1);
    if (!attributeList) {
        return NULL;
    }
    
    
    // Initialize the attribute string area.
    char *attributeStrings = (char *)attributeList + attributeListSize;
    strcpy(attributeStrings, constAttributes);
    
    char *name;
    char *next = attributeStrings;
    unsigned attributeIndex = 0;
    while ((name = strsep(&next, ",")) != NULL) {
        // Attribute pairs must contain a name!
        if (*name == '\0') {
            free(attributeList);
            return NULL;
        }
        
        // NUL-terminating the name requires first moving the rest of the string which requires some extra housekeeping because of strsep.
        char *value = name + 1;
        int remainingBufferLength = (int)attributeStringsSize - (int)(value - attributeStrings);
        if (remainingBufferLength > 1) {
            memmove(value + 1, value, remainingBufferLength - 1);
            // Update next pointer for strsep
            if (next) next++;
        }
        
        // Add NUL termination to name and update value pointer.
        *(name + 1) = '\0';
        value++;
        
        attributeList[attributeIndex].name = name;
        attributeList[attributeIndex].value = value;
        attributeIndex++;
    }
    
    if (outCount) {
        *outCount = attributeCount > 0 ? (unsigned int)attributeCount : 0;
    }
    
    return attributeList;
}

BOOL nn_selector_belongsToProtocol(SEL selector, Protocol *protocol, BOOL *requiredPtr, BOOL *instancePtr)
{
    BOOL required = requiredPtr ? !!*requiredPtr : NO;
    BOOL instance = instancePtr ? !!*instancePtr : NO;

    for (int i = 0; i < (1 << 2); ++i) {
        BOOL checkRequired = required ^ (i & 1);
        BOOL checkInstance = instance ^ (i & (1 << 1));
        
        struct objc_method_description hasMethod = protocol_getMethodDescription(protocol, selector, checkRequired, checkInstance);
        if (hasMethod.name || hasMethod.types) {
            if (requiredPtr) {
                *requiredPtr = required;
            }
            if (instancePtr) {
                *instancePtr = instance;
            }
            return YES;
        }
    }
    
    return NO;
}
