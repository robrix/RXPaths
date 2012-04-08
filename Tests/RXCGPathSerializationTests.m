//  RXCGPathSerializationTests.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Black Pixel. All rights reserved.

#import "RXAssertions.h"
#import "RXCGPathSerialization.h"

@interface RXCGPathSerializationTests : SenTestCase
@end

@implementation RXCGPathSerializationTests

-(NSString *)serializedPath:(CGPathRef)path {
	NSError *error = nil;
	NSData *data = [RXCGPathSerialization dataWithPath:path error:&error];
	RXAssertNotNil(data, @"%@", error);
	return data? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

-(void)testSerializesMoves {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 10, 10);
	RXAssertEquals([self serializedPath:path], @"M10 10");
}

-(void)testSerializesFractionalMoves {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, M_PI, M_PI);
	RXAssertEquals([self serializedPath:path], @"M3.1415927 3.1415927");
}


-(void)testSerializesLines {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, 10, 10);
	RXAssertEquals([self serializedPath:path], @"M0 0L10 10");
}

-(void)testSerializesQuadraticCurves {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddQuadCurveToPoint(path, NULL, 10, 10, 20, 20);
	RXAssertEquals([self serializedPath:path], @"M0 0Q10 10 20 20");
}

-(void)testSerializesCubicCurves {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddCurveToPoint(path, NULL, 10, 10, 20, 20, 30, 30);
	RXAssertEquals([self serializedPath:path], @"M0 0C10 10 20 20 30 30");
}

-(void)testSerializesCloses {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, 10, 10);
	CGPathCloseSubpath(path);
	RXAssertEquals([self serializedPath:path], @"M0 0L10 10Z");
}

@end
