//
//  nn_isaSwizzlingTests.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright (c) 2013 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NNKit/NNKit.h>
#import <Foundation/Foundation.h>

// Class ISAGood can be used for swizzling any NSObject
@protocol ISAGood <NSObject> - (void)foo; @end
@interface ISAGood : NSObject <ISAGood> @end
@implementation ISAGood - (void)foo { NSLog(@"foooooo! "); } - (void)doesNotRecognizeSelector:(__attribute__((unused)) SEL)aSelector { NSLog(@"FAUX NOES!"); } @end


// Class ISANoSharedAncestor can only be used to swizzle instances that areKindOf NSArray
@protocol ISANoSharedAncestor <NSObject> - (void)foo; @end
@interface ISANoSharedAncestor : NSArray <ISANoSharedAncestor> @end
@implementation ISANoSharedAncestor - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISANoProtocol doesn't have a corersponding protocol and cannot be used for swizzling
@interface ISANoProtocol : NSObject @end
@implementation ISANoProtocol - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAAddsProperties adds properties to its superclass and thus cannot be used for swizzling
@protocol ISAAddsProperties <NSObject> - (void)foo; @end
@interface ISAAddsProperties : NSObject <ISAAddsProperties> @property (nonatomic, assign) NSUInteger bar; @end
@implementation ISAAddsProperties - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAAddsProperties adds properties to its superclass and thus cannot be used for swizzling
@protocol ISAAddsLegalProperties <NSObject> @end
@interface ISAAddsLegalProperties : NSObject <ISAAddsLegalProperties> @property (nonatomic, assign) NSUInteger bar; @end
@implementation ISAAddsLegalProperties @dynamic bar; - (NSUInteger)bar { NSLog(@"foooooo! "); return 7; } @end


// Class ISAAddsIvars adds ivars to its superclass and thus cannot be used for swizzling
@protocol ISAAddsIvars <NSObject> - (void)foo; @end
@interface ISAAddsIvars : NSObject <ISAAddsIvars> { NSUInteger bar; } @end
@implementation ISAAddsIvars - (void)foo { NSLog(@"foooooo! "); } @end


// Class ISAExtraProtocol adds an extra protocol that the swizzled object must conform to.
@protocol ISAExtraProtocol <NSObject> - (void)foo; @end
@interface ISAExtraProtocol : NSObject <ISAExtraProtocol, NSCacheDelegate> @end
@implementation ISAExtraProtocol - (void)foo { NSLog(@"foooooo! "); } @end


@interface nn_isaSwizzlingTests : XCTestCase

@end

@implementation nn_isaSwizzlingTests

- (void)testInteractionWithKVO;
{
    XCTFail(@"NOT TESTED");
}

- (void)testExtraProtocol;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAExtraProtocol)], @"Object is not virgin");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAExtraProtocol class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAExtraProtocol)], @"Object is not swizzled correctly");
    XCTAssertTrue([bar conformsToProtocol:@protocol(NSCacheDelegate)], @"Object is missing extra protocol");
}

- (void)testAddsProperties;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISAAddsProperties class]), @"Failed to fail to swizzle object");
}

- (void)testAddsLegalProperties;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAAddsLegalProperties class]), @"Failed to swizzle object");
    XCTAssertEqual(((ISAAddsLegalProperties *)bar).bar, (NSUInteger)7, @"Oops properties");
}

- (void)testAddsIvars;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISAAddsIvars class]), @"Failed to fail to swizzle object");
}

- (void)testDoubleSwizzle;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not virgin");
    XCTAssertFalse([bar respondsToSelector:@selector(foo)], @"Object is not virgin");
    
    XCTAssertThrows([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertThrows([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not swizzled correctly");
    
    XCTAssertTrue([bar respondsToSelector:@selector(foo)], @"Object is not swizzled correctly");
    
    XCTAssertNoThrow([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertNoThrow([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertEqual([bar class], [NSObject class], @"Object should report itself as still being an NSObject");
}

- (void)testSharedAncestor;
{
    NSObject *bar = [[NSObject alloc] init];
    NSArray *arr = [[NSArray alloc] init];
    
    XCTAssertFalse(nn_object_swizzleIsa(bar, [ISANoSharedAncestor class]), @"Failed to fail to swizzle object");
    XCTAssertTrue(nn_object_swizzleIsa(arr, [ISANoSharedAncestor class]), @"Failed to swizzle object");
}

- (void)testNoProto;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISANoProtocol class]), @"Failed to swizzle object");
}

- (void)testImplementationDetails;
{
    NSObject *bar = [[NSObject alloc] init];
    
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wundeclared-selector"
    
    XCTAssertFalse([bar respondsToSelector:@selector(actualClass)], @"Object is not virgin");
    XCTAssertThrows([bar performSelector:@selector(actualClass)], @"actualClass exists?");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar respondsToSelector:@selector(_swizzler_actualClass)], @"Object is not swizzled correctly");
    XCTAssertNoThrow([bar performSelector:@selector(_swizzler_actualClass)], @"Internal swizzle method actualClass not implemented?");
    
#   pragma clang diagnostic pop

}

- (void)testGood;
{
    NSObject *bar = [[NSObject alloc] init];
    
    XCTAssertFalse([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not virgin");
    XCTAssertFalse([bar respondsToSelector:@selector(foo)], @"Object is not virgin");
    
    XCTAssertThrows([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertThrows([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertTrue(nn_object_swizzleIsa(bar, [ISAGood class]), @"Failed to swizzle object");
    
    XCTAssertTrue([bar conformsToProtocol:@protocol(ISAGood)], @"Object is not swizzled correctly");
    XCTAssertTrue([bar isKindOfClass:[ISAGood class]], @"Object is not swizzled correctly");
    
    XCTAssertTrue([bar respondsToSelector:@selector(foo)], @"Object is not swizzled correctly");
    
    XCTAssertNoThrow([(id<ISAGood>)bar foo], @"foooooo!");
    XCTAssertNoThrow([bar doesNotRecognizeSelector:nil], @"FAUX NOES!");
    
    XCTAssertEqual([bar class], [NSObject class], @"Object should report itself as still being an NSObject");
}

@end