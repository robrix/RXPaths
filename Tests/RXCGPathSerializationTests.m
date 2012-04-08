//  RXCGPathSerializationTests.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Black Pixel. All rights reserved.

#import "RXAssertions.h"
#import "RXCGPathSerialization.h"

@interface RXCGPathSerializationTests : SenTestCase
@end

@implementation RXCGPathSerializationTests {
	CGMutablePathRef path;
}

-(void)setUp {
	path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
}

-(void)tearDown {
	CGPathRelease(path);
	path = NULL;
}


-(NSString *)serializedPath:(CGPathRef)argument {
	NSError *error = nil;
	NSData *data = [RXCGPathSerialization dataWithPath:argument error:&error];
	RXAssertNotNil(data, @"%@", error);
	return data? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

-(void)testSerializesMovesWithoutDecimals {
	RXAssertEquals([self serializedPath:path], @"M0 0");
}

-(void)testSerializesFractionalMovesWithEightDecimalPlacesOfPrecision {
	CGPathMoveToPoint(path, NULL, M_PI, M_PI);
	RXAssertEquals([self serializedPath:path], @"M3.1415927 3.1415927");
}

-(void)testSerializesLines {
	CGPathAddLineToPoint(path, NULL, 10, 10);
	RXAssertEquals([self serializedPath:path], @"M0 0L10 10");
}

-(void)testSerializesQuadraticCurves {
	CGPathAddQuadCurveToPoint(path, NULL, 10, 10, 20, 20);
	RXAssertEquals([self serializedPath:path], @"M0 0Q10 10 20 20");
}

-(void)testSerializesCubicCurves {
	CGPathAddCurveToPoint(path, NULL, 10, 10, 20, 20, 30, 30);
	RXAssertEquals([self serializedPath:path], @"M0 0C10 10 20 20 30 30");
}

-(void)testSerializesCloses {
	CGPathAddLineToPoint(path, NULL, 10, 10);
	CGPathCloseSubpath(path);
	RXAssertEquals([self serializedPath:path], @"M0 0L10 10Z");
}


-(CGPathRef)newDeserializedPath:(NSString *)string {
	NSError *error = nil;
	CGPathRef result = [RXCGPathSerialization newPathWithData:[string dataUsingEncoding:NSUTF8StringEncoding] error:&error];
	RXAssertNotNil(result, @"%@", error);
	return result;
}

-(void)testDeserializesMoves {
	CGPathMoveToPoint(path, NULL, 10, 10);
	CGPathRef actual = [self newDeserializedPath:@"M10 10"];
	RXAssert(CGPathEqualToPath(actual, path));
	CGPathRelease(actual);
}

-(void)testDeserializesLines {
	CGPathAddLineToPoint(path, NULL, 10, 10);
	CGPathRef actual = [self newDeserializedPath:@"M0 0L10 10"];
	RXAssert(CGPathEqualToPath(actual, path));
	CGPathRelease(actual);
}

-(void)testDeserializesQuadraticCurves {
	CGPathAddQuadCurveToPoint(path, NULL, 10, 10, 20, 20);
	CGPathRef actual = [self newDeserializedPath:@"M0 0Q10 10 20 20"];
	RXAssert(CGPathEqualToPath(actual, path));
	CGPathRelease(actual);
}

-(void)testDeserializesCubicCurves {
	CGPathAddCurveToPoint(path, NULL, 10, 10, 20, 20, 30, 30);
	CGPathRef actual = [self newDeserializedPath:@"M0 0C10 10 20 20 30 30"];
	RXAssert(CGPathEqualToPath(actual, path));
	CGPathRelease(actual);
}

-(void)testDeserializesCloses {
	CGPathAddLineToPoint(path, NULL, 10, 10);
	CGPathCloseSubpath(path);
	CGPathRef actual = [self newDeserializedPath:@"M0 0L10 10Z"];
	RXAssert(CGPathEqualToPath(actual, path));
	CGPathRelease(actual);
}

@end
