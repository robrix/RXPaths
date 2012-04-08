//  RXCGPathSerialization.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Monochrome Industries. All rights reserved.

#import "RXCGPathSerialization.h"

typedef void (*RXCGPathSerializeElementFunction)(NSMutableData *data, const CGPathElement *element);

@implementation RXCGPathSerialization

static void RXCGPathSerializePoint(NSMutableData *data, CGPoint point) {
	const char format[100];
	snprintf((char *)format, sizeof(format), "%.8g %.8g", point.x, point.y);
	
	[data appendBytes:format length:strlen(format)];
}


static void RXCGPathSerializeMoveElement(NSMutableData *data, const CGPathElement *element) {
	[data appendBytes:"M" length:1];
	RXCGPathSerializePoint(data, element->points[0]);
}

static void RXCGPathSerializeLineElement(NSMutableData *data, const CGPathElement *element) {
	[data appendBytes:"L" length:1];
	RXCGPathSerializePoint(data, element->points[0]);
}

static void RXCGPathSerializeQuadCurveElement(NSMutableData *data, const CGPathElement *element) {
	[data appendBytes:"Q" length:1];
	RXCGPathSerializePoint(data, element->points[0]);
	[data appendBytes:" " length:1];
	RXCGPathSerializePoint(data, element->points[1]);
}

static void RXCGPathSerializeCurveElement(NSMutableData *data, const CGPathElement *element) {
	[data appendBytes:"C" length:1];
	RXCGPathSerializePoint(data, element->points[0]);
	[data appendBytes:" " length:1];
	RXCGPathSerializePoint(data, element->points[1]);
	[data appendBytes:" " length:1];
	RXCGPathSerializePoint(data, element->points[2]);
}

static void RXCGPathSerializeCloseElement(NSMutableData *data, const CGPathElement *element) {
	[data appendBytes:"Z" length:1];
}

static void RXCGPathSerializeElement(void *info, const CGPathElement *element) {
	NSMutableData *data = *(NSMutableData * __strong *)info;
	
	static RXCGPathSerializeElementFunction elementFunctions[] = {
		RXCGPathSerializeMoveElement,
		RXCGPathSerializeLineElement,
		RXCGPathSerializeQuadCurveElement,
		RXCGPathSerializeCurveElement,
		RXCGPathSerializeCloseElement
	};
	
	(elementFunctions[element->type])(data, element);
}

+(NSData *)dataWithPath:(CGPathRef)path error:(NSError * __autoreleasing *)error {
	NSParameterAssert(path != NULL);
	
	NSMutableData *data = [NSMutableData new];
	
	CGPathApply(path, &data, RXCGPathSerializeElement);
	
	return data;
}

@end
