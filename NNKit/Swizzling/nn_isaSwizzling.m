//
//  nn_isaSwizzling.m
//  NNKit
//
//  Created by Scott Perry on 02/07/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "nn_isaSwizzling_Private.h"

#import <objc/runtime.h>

#import "runtime.h"
#import "NNISASwizzledObject.h"
#import "nn_autofree.h"


static NSString *_prefixForSwizzlingClass(Class aClass) __attribute__((nonnull(1), pure));
static NSString * _classNameForObjectWithSwizzlingClass(id anObject, Class aClass) __attribute__((nonnull(1, 2), pure));
static BOOL _class_addInstanceMethodsFromClass(Class target, Class source) __attribute__((nonnull(1, 2)));
static BOOL _class_addProtocolsFromClass(Class targetClass, Class aClass) __attribute__((nonnull(1,2)));
static BOOL _class_containsNonDynamicProperties(Class aClass) __attribute__((nonnull(1)));
static BOOL _class_containsIvars(Class aClass) __attribute__((nonnull(1)));
static Class _targetClassForObjectWithSwizzlingClass(id anObject, Class aClass) __attribute__((nonnull(1, 2)));
static BOOL _object_swizzleIsa(id anObject, Class aClass) __attribute__((nonnull(1, 2)));


static NSString *_prefixForSwizzlingClass(Class aClass)
{
    return [NSString stringWithFormat:@"SwizzledWith%s_", class_getName(aClass)];
}

static NSString * _classNameForObjectWithSwizzlingClass(id anObject, Class aClass)
{
    return [NSString stringWithFormat:@"%@%s", _prefixForSwizzlingClass(aClass), object_getClassName(anObject)];
}

#pragma mark Class copying functions

static BOOL _class_addClassMethodsFromClass(Class target, Class source)
{
    BOOL success = YES;
    Method *methods = nn_autofree(class_copyMethodList(object_getClass(source), NULL));
    Method method;
    
    for (NSUInteger i = 0; methods && (method = methods[i]); i++) {
        // targetClass is a brand new shiny class, so this should never fail because it already implements a method (even though its superclass(es) might).
        if(!class_addMethod(object_getClass(target), method_getName(method), method_getImplementation(method), method_getTypeEncoding(method))) {
            success = NO;
            break;
        }
    }

    return success;
}

static BOOL _class_addInstanceMethodsFromClass(Class target, Class source)
{
    BOOL success = YES;
    Method *methods = nn_autofree(class_copyMethodList(source, NULL));
    Method method;
    
    for (NSUInteger i = 0; methods && (method = methods[i]); i++) {
        // targetClass is a brand new shiny class, so this should never fail because it already implements a method (even though its superclass(es) might).
        if(!class_addMethod(target, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method))) {
            success = NO;
            break;
        }
    }
    
    return success;
}

static BOOL _class_addProtocolsFromClass(Class targetClass, Class aClass)
{
    BOOL success = YES;
    Protocol * __unsafe_unretained *protocols = (Protocol * __unsafe_unretained *)nn_autofree(class_copyProtocolList(aClass, NULL));
    Protocol __unsafe_unretained *protocol;
    
    for (NSUInteger i = 0; protocols && (protocol = protocols[i]); i++) {
        // targetClass is a brand new shiny class, so this should never fail because it already conforms to a protocol (even though its superclass(es) might).
        if (!class_addProtocol(targetClass, protocol)) {
            success = NO;
            break;
        }
    }

    return success;
}

static BOOL _class_addPropertiesFromClass(Class targetClass, Class aClass)
{
    BOOL success = YES;
    objc_property_t *properties = nn_autofree(class_copyPropertyList(aClass, NULL));
    objc_property_t property;
    
    for (NSUInteger i = 0; properties && (property = properties[i]); i++) {
        unsigned attributeCount;
        objc_property_attribute_t *attributes = nn_autofree(nn_property_copyAttributeList(property, &attributeCount));

        // targetClass is a brand new shiny class, so this should never fail because it already has certain properties (even though its superclass(es) might).
        if(!class_addProperty(targetClass, property_getName(property), attributes, attributeCount)) {
            success = NO;
            break;
        }
    }
    
    return success;
}

#pragma mark Swizzling safety checks

static BOOL _class_containsNonDynamicProperties(Class aClass)
{
    objc_property_t *properties = nn_autofree(class_copyPropertyList(aClass, NULL));
    BOOL propertyIsDynamic = NO;
    
    for (unsigned i = 0; properties && properties[i]; i++) {
        objc_property_attribute_t *attributes = nn_autofree(nn_property_copyAttributeList(properties[i], NULL));
        
        for (unsigned j = 0; attributes && attributes[j].name; j++) {
            if (!strcmp(attributes[j].name, "D")) { // The property is dynamic (@dynamic).
                propertyIsDynamic = YES;
                break;
            }
        }
        
        attributes = NULL;
        
        if (!propertyIsDynamic) {
            NSLog(@"Swizzling class %s cannot contain non-dynamic properties", class_getName(aClass));
            return YES;
        }
    }
    
    return NO;
}

static BOOL _class_containsIvars(Class aClass)
{
    unsigned ivars;
    free(class_copyIvarList(aClass, &ivars));
    return ivars != 0;
}

#pragma mark Isa swizzling

static Class _targetClassForObjectWithSwizzlingClass(id anObject, Class aClass)
{
    Class targetClass = objc_getClass(_classNameForObjectWithSwizzlingClass(anObject, aClass).UTF8String);
    
    if (!targetClass) {
        const char *swizzlingClassName = class_getName(aClass);

        Class sharedAncestor = class_getSuperclass(aClass);
        if (![anObject isKindOfClass:sharedAncestor]) {
            NSLog(@"Target object %@ must be a subclass of %@ to be swizzled with class %s.", anObject, sharedAncestor, swizzlingClassName);
            return Nil;
        }
        
        if (_class_containsNonDynamicProperties(aClass)) {
            NSLog(@"Swizzling class %s cannot contain non-dynamic properties not inherited from its superclass", swizzlingClassName);
            return Nil;
        }
        
        if (_class_containsIvars(aClass)) {
            NSLog(@"Swizzling class %s cannot contain ivars not inherited from its superclass", swizzlingClassName);
            return Nil;
        }
        
        targetClass = objc_allocateClassPair(object_getClass(anObject), _classNameForObjectWithSwizzlingClass(anObject, aClass).UTF8String, 0);
        
        if (!_class_addClassMethodsFromClass(targetClass, aClass)) {
            return Nil;
        }
        
        if (!_class_addInstanceMethodsFromClass(targetClass, aClass)) {
            return Nil;
        }
        
        if (!_class_addProtocolsFromClass(targetClass, aClass)) {
            return Nil;
        }
        
        if (!_class_addPropertiesFromClass(targetClass, aClass)) {
            return Nil;
        }
        
        objc_registerClassPair(targetClass);
    }
    
    return targetClass;
}

static BOOL _object_swizzleIsa(id anObject, Class aClass)
{
    assert(!nn_alreadySwizzledObjectWithSwizzlingClass(anObject, aClass));
    
    Class targetClass = _targetClassForObjectWithSwizzlingClass(anObject, aClass);
    
    if (!targetClass) {
        return NO;
    }
    
    object_setClass(anObject, targetClass);
    
    return YES;
}

#pragma mark Privately-exported functions

BOOL nn_alreadySwizzledObjectWithSwizzlingClass(id anObject, Class aClass)
{
    NSString *classPrefix = _prefixForSwizzlingClass(aClass);
    
    for (Class candidate = object_getClass(anObject); candidate; candidate = class_getSuperclass(candidate)) {
        if ([[NSString stringWithUTF8String:class_getName(candidate)] hasPrefix:classPrefix]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Publicly-exported funtions

BOOL nn_object_swizzleIsa(id anObject, Class aClass) {
    BOOL success = YES;
    
    @autoreleasepool {
        // Bootstrap the object with the necessary lies, like overriding -class to report the original class.
        if (!nn_alreadySwizzledObjectWithSwizzlingClass(anObject, [NNISASwizzledObject class])) {
            [NNISASwizzledObject prepareObjectForSwizzling:anObject];
            
            success = _object_swizzleIsa(anObject, [NNISASwizzledObject class]);
        }
        
        if (success && !nn_alreadySwizzledObjectWithSwizzlingClass(anObject, aClass)) {
            success = _object_swizzleIsa(anObject, aClass);
        }
    }
    
    return success;
}
