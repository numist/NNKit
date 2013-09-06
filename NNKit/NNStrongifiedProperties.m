//
//  NNStrongifiedProperties.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import "NNStrongifiedProperties.h"

#import <objc/runtime.h>

#import "rantime.h"


static SEL weakGetterForPropertyName(Class myClass, NSString *propertyName) {
    objc_property_t property = NULL;
    do {
        property = class_getProperty(myClass, [propertyName UTF8String]);
        if (property) {
            break;
        }
    } while ((myClass = class_getSuperclass(myClass)));
    
    if (!property) {
        return NO;
    }
    
    objc_property_attribute_t *attributes = nn_property_copyAttributeList(property, NULL);
    BOOL propertyIsWeak = NO;
    SEL getter = NSSelectorFromString(propertyName);
    for (int i = 0; attributes[i].name != NULL; ++i) {
        NSLog(@"%s : %s", attributes[i].name, attributes[i].value);
        if (!strncmp(attributes[i].name, "W", MIN(strlen("W"), strlen(attributes[i].name)))) {
            propertyIsWeak = YES;
        }
        if (!strncmp(attributes[i].name, "G", 1)) {
            getter = NSSelectorFromString([NSString stringWithFormat:@"%s", attributes[i].name + 1]);
        }
#       warning strnncmp might be nice
        if (!strncmp(attributes[i].name, "T", MIN(strlen("T"), strlen(attributes[i].name))) && strncmp(attributes[i].value, "@", MIN(strlen("@"), strlen(attributes[i].value)))) {
            return NO;
        }
    }
    free(attributes);
    attributes = NULL;
    
    if (!propertyIsWeak) {
        return NULL;
    }
    
    return getter;
}


static _Bool selectorIsStrongGetter(Class myClass, SEL sel, SEL *weakGetter) {
    NSString *selectorName = NSStringFromSelector(sel);
    NSRange prefixRange = [selectorName rangeOfString:@"strong"];
    
    BOOL selectorIsStrongGetter = prefixRange.location == 0;
    
    if (!selectorIsStrongGetter) {
        if (weakGetter) {
            *weakGetter = NULL;
        }
        return NO;
    }
    
    // Also check uppercase in case it's an acronym?
    
    NSString *upperName = [selectorName substringFromIndex:prefixRange.length];
    NSString *lowerName = [NSString stringWithFormat:@"%@%@",
                           [[selectorName substringWithRange:(NSRange){prefixRange.length, 1}] lowercaseString],
                           [selectorName substringFromIndex:prefixRange.length + 1]];
    
    SEL lowerGetter = weakGetterForPropertyName(myClass, lowerName);
    SEL upperGetter = weakGetterForPropertyName(myClass, upperName);
    
    if (lowerGetter && upperGetter) {
        @throw [NSException exceptionWithName:@"NNAmbiguousImplementationException" reason:[NSString stringWithFormat:@"Strong getter method %@ may refer to either %@ or %@ properties", selectorName, lowerName, upperName] userInfo:nil];
    }
    
    if (!lowerGetter && !upperGetter) {
        return NO;
    }

    *weakGetter = lowerGetter ?: upperGetter;

    return YES;
}


static id strongGetterIMP(id self, SEL _cmd) {
    SEL weakSelector = NULL;
    BOOL sane = selectorIsStrongGetter([self class], _cmd, &weakSelector);
    NSAssert(sane, @"Selector %@ does not represent a valid strongifying getter method", NSStringFromSelector(_cmd));
    
    if (!weakSelector) { return nil; }
    
#   warning we have a better way to deal with this—how?
#   pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id strongRef = [self performSelector:weakSelector];
#   pragma clang diagnostic pop
    
    return strongRef;
}


@implementation NNStrongifiedProperties

+ (BOOL)resolveInstanceMethod:(SEL)sel;
{
    SEL weakSelector = NULL;
    if (selectorIsStrongGetter(self, sel, &weakSelector)) {
        Method weakGetter = class_getInstanceMethod(self, weakSelector);
        const char *getterEncoding = method_getTypeEncoding(weakGetter);
        class_addMethod(self, sel, (IMP)strongGetterIMP, getterEncoding);
        return YES;
    }
    
    return NO;
}

@end
