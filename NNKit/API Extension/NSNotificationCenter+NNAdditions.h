//
//  NSNotificationCenter+NNAdditions.h
//  NNKit
//
//  Created by Scott Perry on 11/14/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (NNAdditions)

- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

@end
