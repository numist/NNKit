//
//  NNStrongifiedPropertiesTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>


@interface NNStrongifiedPropertiesTests : XCTestCase

@end



@interface NNStrongifyTestClass : NNStrongifiedProperties

@property (weak) id foo;
@property id bar;
@property (weak) id TLA;
@property (weak) id qux;
@property (weak) id Qux;

@end
@interface NNStrongifyTestClass (NNStrongGetters)

- (id)strongFoo; // Good
- (id)strongBar; // Bad -- strong
- (id)strongTLA; // Good
- (id)strongQux; // Bad -- ambiguous

@end
@implementation NNStrongifyTestClass
@end



@interface NNSwizzledStrongifierTestClass : NSObject

@property (weak) id foo;
@property id bar;
@property (weak) id TLA;
@property (weak) id qux;
@property (weak) id Qux;

@end
@interface NNSwizzledStrongifierTestClass (NNStrongGetters)

- (id)strongFoo; // Good
- (id)strongBar; // Bad -- strong
- (id)strongTLA; // Good
- (id)strongQux; // Bad -- ambiguous

@end
@implementation NNSwizzledStrongifierTestClass


@end



@implementation NNStrongifiedPropertiesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicStrongGetter
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    id boo = [NSObject new];
    obj.foo = boo;
    XCTAssertEqual([obj strongFoo], boo, @"Basic weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testCapitalizedStrongGetter
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    id boo = [NSObject new];
    obj.TLA = boo;
    XCTAssertEqual([obj strongTLA], boo, @"Capitalized weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testStrongGetterWithStrongProperty
{
    XCTAssertThrows([[NNStrongifyTestClass new] strongBar], @"Strongified strong property access resulted in a valid IMP.");
}

- (void)testAmbiguousStrongGetter
{
    XCTAssertThrows([[NNStrongifyTestClass new] strongQux], @"Ambiguous property access resulted in a single IMP.");
}

- (void)testNilling
{
    NNStrongifyTestClass *obj = [NNStrongifyTestClass new];
    @autoreleasepool {
        id boo = [NSObject new];
        obj.foo = boo;
        [boo self];
    }
    XCTAssertNil([obj strongFoo], @"Weak property did not nil as expected.");
}

- (void)testSwizzledBasicStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    id boo = [NSObject new];
    obj.foo = boo;
    XCTAssertEqual([obj strongFoo], boo, @"Basic weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testSwizzledCapitalizedStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    id boo = [NSObject new];
    obj.TLA = boo;
    XCTAssertEqual([obj strongTLA], boo, @"Capitalized weak property did not resolve a strong getter.");
    [boo self];
}

- (void)testSwizzledStrongGetterWithStrongProperty
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertThrows([obj strongBar], @"Strongified strong property access resulted in a valid IMP.");
}

- (void)testSwizzledAmbiguousStrongGetter
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    XCTAssertThrows([obj strongQux], @"Ambiguous property access resulted in a single IMP.");
}

- (void)testSwizzledNilling
{
    NNSwizzledStrongifierTestClass *obj = [NNSwizzledStrongifierTestClass new];
    nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);
    @autoreleasepool {
        id boo = [NSObject new];
        obj.foo = boo;
        [boo self];
    }
    XCTAssertNil([obj strongFoo], @"Weak property did not nil as expected.");
}

@end
