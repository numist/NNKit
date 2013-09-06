//
//  NNDelegateProxy.h
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

#import <Foundation/Foundation.h>

@interface NNDelegateProxy : NSProxy

@property (weak) id delegate;

// protocol can be NULL, but shouldn't be—only messages appropriate to the delegate's protocol should be passed to the delegate!
+ (id)proxyWithDelegate:(id)delegate protocol:(Protocol *)protocol;

@end


#if 0
// Example usage:

// You should already have a protocol for your use of the delegate pattern:
@protocol MYClassDelegate <NSObject>
- (void)objectCalledDelegateMethod:(id)obj;
@end


@interface MYClass : NSObject

// And should already have a weak property for your delegate in your class declaration:
@property (nonatomic, weak) id<MYClassDelegate> delegate;

// Add a strong reference to a new property, the delegate proxy:
@property (strong) id<MYClassDelegate> delegateProxy;

@end

@implementation MYClass

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    // Initialize the delegate proxy, feel free to set the delegate later if you don't have one handy.
    _delegateProxy = [NNDelegateProxy proxyWithDelegate:nil protocol:@protocol(MYClassDelegate)];
    
    // …
    
    return self;
}

// If you have a writable delegate property, you'll need a custom delegate setter to ensure that the proxy gets updated:
- (void)setDelegate:(id<MYClassDelegate>)delegate;
{
    self->_delegate = delegate;
    
    ((NNDelegateProxy *)self.delegateProxy).delegate = delegate;
    // NOTE: A cast is necessary here because the delegateProxy property is typed id<MYClassDelegate> to retain as much static checking as possible elsewhere in your code, which fails here because the compiler doesn't realise that it's still an NNDelegateProxy under the hood.
}

- (void)method;
{
    // Who cares how we got to where we are, or where that even is; when it's time to dispatch a delegate message just send it to the proxy:
    [self.delegateProxy objectCalledDelegateMethod:self];
}

@end

#endif
