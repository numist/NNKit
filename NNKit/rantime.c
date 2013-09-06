//
//  rantime.c
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#include "rantime.h"
#include <string.h>
#include <stdlib.h>

// Lifted from https://github.com/numist/Debugger/blob/master/debugger.h
#ifndef BailWithBlockUnless
#define BailWithBlockUnless(exp,block) \
do { \
    if (!(exp)) { \
        return block(); \
    } \
} while(0)
#endif

// Like the other class_copy* functions, the caller must free the return value of this function with free()
objc_property_attribute_t *nn_property_copyAttributeList(objc_property_t property, unsigned int *outCount)
{
    void *(^failure)(void) = ^{
        if (outCount) {
            *outCount = 0;
        }
        return NULL;
    };
    
    // For more information about the property type string, see the Declared Properties section of the Objective-C Runtime Programming Guide
    const char *constAttributes = property_getAttributes(property);
    BailWithBlockUnless(constAttributes, failure);
    
    /**
     *  ┏━━━━━━━━┓
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────────────┨
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────────────┨
     *  ┃nameptr         ┃
     *  ┃valueptr        ┃
     *  ┠────────────────┨
     *  ┃...             ┃
     *  ┠────────────────┨
     *  ┃NULL            ┃
     *  ┃NULL            ┃
     *  ┠────────────────┨
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
    BailWithBlockUnless(attributeList, failure);
    
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
            return failure();
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
