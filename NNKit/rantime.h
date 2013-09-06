//
//  rantime.h
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#ifndef NNKit_rantime_h
#define NNKit_rantime_h

#include <objc/runtime.h>

objc_property_attribute_t *nn_property_copyAttributeList(objc_property_t property, unsigned int *outCount);

#endif
