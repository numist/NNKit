//
//  NNSelfInvalidatingObject.h
//  Switch
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNSelfInvalidatingObject : NSObject

- (void)invalidate __attribute__((objc_requires_super));

@end
