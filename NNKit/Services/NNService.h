//
//  NNService.h
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


/*!
 * @enum NNServiceType
 *
 * @discussion
 * Represents the type of a service. Persistent services are started once all of
 * their dependencies have been started, on-demand services are started when an
 * object subscribes to the service.
 */
typedef NS_ENUM(uint8_t, NNServiceType) {
    NNServiceTypeNone,
    NNServiceTypePersistent,
    NNServiceTypeOnDemand,
};


/*!
 * @protocol NNService
 *
 * @discussion
 * Protocol that all services must implement to be supported by a
 * <code>NNServiceManager</code>.
 */
@protocol NNService <NSObject>

@required
/*!
 * @method sharedService
 *
 * @discussion
 * Service singleton accessor.
 *
 * @result
 * Singleton object for the service.
 */
+ (id)sharedService;

/*!
 * @method serviceType
 *
 * @discussion
 * The type of the service. Must not be NNServiceTypeNone.
 */
- (NNServiceType)serviceType;

/*!
 * @method dependencies
 *
 * @discussion
 * Services are not started until their dependencies have all been started first.
 * This means multiple services can be made on-demand by having a root service
 * that is on-demand and multiple dependant services that are persistent.
 *
 * @result
 * Returns a set of <code>Class</code>es that this service depends on to run.
 * Can be <code>nil</code>.
 */
- (NSSet *)dependencies;

@optional
/*!
 * @method startService
 *
 * @discussion
 * Called when the service is started. Optional.
 */
- (void)startService;

/*!
 * @method stopService
 *
 * @discussion
 * Called when the service is stopped. Optional.
 */
- (void)stopService;

@end


/*!
 * @class NNService
 *
 * @discussion
 * The <code>NNService</code> class contains generic implementations for most of
 * the methods in the <code>NNService</code> protocol. Only
 * <code>serviceType</code> still needs to be overridden for a service to be
 * legal.
 */
@interface NNService : NSObject <NNService>

@end
