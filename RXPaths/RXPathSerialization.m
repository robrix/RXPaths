//  RXPathSerialization.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Black Pixel. All rights reserved.

#import "RXPathSerialization.h"

@implementation RXPathSerializer {
	NSMutableData *data;
}

+(RXPathSerializer *)serializerWithMutableData:(NSMutableData *)data {
	RXPathSerializer *serializer = [self new];
	serializer->data = data;
	return serializer;
}

static void RXPathSerializePoint(NSMutableData *data, CGPoint point) {
	const char format[100];
	snprintf((char *)format, sizeof(format), "%.8g %.8g", point.x, point.y);
	
	[data appendBytes:format length:strlen(format)];
}

-(void)serializeMoveToPoint:(CGPoint)point {
	[data appendBytes:"M" length:1];
	RXPathSerializePoint(data, point);
}

-(void)serializeLineToPoint:(CGPoint)point {
	[data appendBytes:"L" length:1];
	RXPathSerializePoint(data, point);
}

-(void)serializeQuadraticCurveToPoint:(CGPoint)point controlPoint:(CGPoint)controlPoint {
	[data appendBytes:"Q" length:1];
	RXPathSerializePoint(data, controlPoint);
	[data appendBytes:" " length:1];
	RXPathSerializePoint(data, point);
}

-(void)serializeCubicCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 {
	[data appendBytes:"C" length:1];
	RXPathSerializePoint(data, controlPoint1);
	[data appendBytes:" " length:1];
	RXPathSerializePoint(data, controlPoint2);
	[data appendBytes:" " length:1];
	RXPathSerializePoint(data, point);
}

-(void)serializeCloseSubpath {
	[data appendBytes:"Z" length:1];
}

@end


@implementation RXPathDeserializer {
	RXPathMoveBlock moveHandler;
	RXPathLineBlock lineHandler;
	RXPathQuadraticCurveBlock quadraticHandler;
	RXPathCubicCurveBlock cubicHandler;
	RXPathCloseBlock closeHandler;
}

+(void)deserializePathWithData:(NSData *)data
				   moveHandler:(RXPathMoveBlock)move
				   lineHandler:(RXPathLineBlock)line
		 quadraticCurveHandler:(RXPathQuadraticCurveBlock)quadratic
			 cubicCurveHandler:(RXPathCubicCurveBlock)cubic
				  closeHandler:(RXPathCloseBlock)close
						 error:(NSError * __autoreleasing *)error {
	
}

+(void)deserializePathWithData:(NSData *)data
				elementHandler:(RXPathElementHandler)element
						 error:(NSError * __autoreleasing *)error {
	
}

@end
