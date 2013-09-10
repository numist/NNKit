NNKit API Extensions
====================

For its own internal use, as well as your enjoyment, NNKit contains a set of extensions to existing system APIs.

despatch
--------

[Despatch](http://numist.net/define/?despatch) contains helper functions to make dealing with GCD easier. At the moment this is one function:

### `despatch_sync_main_reentrant` ####

`despatch_sync_main_reentrant` is a function for making synchronous dispatch onto the main queue simpler. The block argument is invoked directly if the sender is already executing on the main thread, and dispatched synchronously onto the main queue otherwise.

### `despatch_group_yield` ###

The yield concept is borrowed from Python and other languages as a way for a path of execution to pause and allow other work scheduled for that thread to proceed. In this case it's most useful in unit tests to allow asynchronous work that takes place on the main thread to proceed.

A very basic example from `NNDelegateProxyTests.m`:

    - (void)testGlobalAsync;
    {
        dispatch_group_enter(group);
        [[[MYClass alloc] initWithDelegate:self] globalAsync];
        
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:0.1];
        while (!despatch_group_yield(group) && [[NSDate date] compare:timeout] == NSOrderedAscending);
        XCTAssertFalse(dispatch_group_wait(group, DISPATCH_TIME_NOW), @"Delegate message was never received (timed out)!");
    }

runtime
-------

Runtime provides functions that should exist in the Objective-C runtime, but don't.

### `nn_selector_belongsToProtocol` ###

`nn_selector_belongsToProtocol` returns whether or not a selector belongs to a protocol, with additional arguments that inform its search pattern and return information about the selector found in the protocol. Providing default values for `instance` and `required` begin the search with those attributes, and their values on return indicate the attributes of the first match found.

### `nn_property_copyAttributeList` ###

This function should have been included in the runtime. The return values of `method_getName`, `method_getImplementation`, and `method_getTypeEncoding` can be used as parameters to `class_addMethod`, same with the return values of `ivar_getName` and `ivar_getTypeEncoding` into `class_addIvar`. This lovely consistency breaks down when it comes to properties in the Objective-C runtime—the result of `property_getAttributes` is completely unsuitable for `class_addProperty`. 

`nn_property_copyAttributeList` takes the result of `property_getAttributes` and returns a buffer in a format that can be used by `class_addProperty` directly, as well as easily enumerated.
