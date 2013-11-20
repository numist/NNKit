//
//  NNServiceManager.h
//  NNKit
//
//  Created by Scott Perry on 10/17/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

#import <NNKit/NNService.h>


/*!
 * @class NNServiceManager
 *
 * @discussion
 * Manages the running state of registered services based on their dependencies and subscriptions.
 */
@interface NNServiceManager : NSObject

/*!
 * @method sharedManager
 *
 * @discussion
 * Singleton service manager accessor.
 *
 * @result
 * Global shared service manager object.
 */
+ (NNServiceManager *)sharedManager;

//- (void)registerAllPossibleServices;

/*!
 * @method registerService:
 *
 * @discussion
 * Registers <i>service</i> with the service manager, and starts it if its
 * dependencies have all been met.
 *
 * @param service
 * The Class of a service to be registered with this service manager.
 */
- (void)registerService:(Class)service;

/*!
 * @method instanceForService
 *
 * @discussion
 * Accessor method to get the instance of a service class, started or not,
 * managed by this service manager.
 *
 * @result
 * An instance of the requested service. <code>nil</code> if the service has
 * not been registered with this service manager.
 */
- (NNService *)instanceForService:(Class)service;

/*!
 * @method addSubscriber:forService::
 *
 * @discussion
 * Increments the service's subscriber count. Services that are run on demand
 * will be started by calls to this method if there were not other subscribers.
 *
 * Subscribers are automatically removed if they are deallocated while
 * subscribed to the service.
 *
 * @param subscriber
 * The object that is interested in the service. If the service defines a
 * specificl protocol with +subscriberProtocol, the subscriber must conform to it.
 *
 * @param service
 * The service to which the caller is subscribing.
 */
- (void)addSubscriber:(id)subscriber forService:(Class)service;

/*!
 * @method removeSubscriber:forService:
 *
 * @discussion
 * Decrements the service's subscriber count. Services that are run on demand
 * will be stopped by calls to this method when the subscriber count reaches zero.
 *
 * @param subscriber
 * The object that is no longer interested in the service.
 *
 * @param service
 * The service to which the caller is unsubscribing.
 */
- (void)removeSubscriber:(id)subscriber forService:(Class)service;

@end
