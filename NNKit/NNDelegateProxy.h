//
//  NNDelegateProxy.h
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNDelegateProxy : NSProxy

@property (weak) id delegate;

+ (NNDelegateProxy *)proxyWithDelegate:(id)delegate;

@end
