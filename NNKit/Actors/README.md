NNKit Actor Model
=================

The base classes in this component solve some common problems found when implementing classes following the actor pattern.

NNPollingObject
---------------

Sometimes there is no way to have information pushed to you, and it has to be checked occasionally by a polling object. This base class provides basic interval and queue priority support with a polling worker thread that terminates when the object is released.

Subclasses need only override `-main` to use, and it's recommended that the built in `-postNotification:` method be used to emit events to interested parties. The `interval` property can be set to any time interval, with values less than or equal to zero causing the worker thread to terminate when it has finished its next scheduled iteration.

NNSelfInvalidatingObject
------------------------

Some objects may encapsulate resources that require work to clean up, such as an open file handle. In some cases, these operations can take time or may otherwise require that the actor be alive for an extended period of time after its owner has released it. Subclassing `NNSelfInvalidatingObject` allows this condition to be handled easily. Simply override `-invalidate`, and it is called asynchronously on the main queue once the internal refCount of the object has reached zero. When cleanup is complete, calling `[super invalidate]` puts the object in the nearest autorelease pool and it is finally destroyed on the next iteration of the runloop. Calling `[self invalidate]` early prevents it from being called when the object refCount reaches zero (the object is destroyed immediately).

This base class was inspired by [Andy Matuschak](https://github.com/andymatuschak).
