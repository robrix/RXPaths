//  RXCGPathSerialization.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Monochrome Industries. All rights reserved.

#import "RXCGPathSerialization.h"
#import "RXPathSerialization.h"

typedef void (*RXCGPathSerializeElementFunction)(RXPathSerializer *serializer, const CGPathElement *element);

@implementation RXCGPathSerialization

#pragma mark Serialization

static void RXCGPathSerializeMoveElement(RXPathSerializer *serializer, const CGPathElement *element) {
	[serializer serializeMoveToPoint:element->points[0]];
}

static void RXCGPathSerializeLineElement(RXPathSerializer *serializer, const CGPathElement *element) {
	[serializer serializeLineToPoint:element->points[0]];
}

static void RXCGPathSerializeQuadraticCurveElement(RXPathSerializer *serializer, const CGPathElement *element) {
	[serializer serializeQuadraticCurveToPoint:element->points[1] controlPoint:element->points[0]];
}

static void RXCGPathSerializeCubicCurveElement(RXPathSerializer *serializer, const CGPathElement *element) {
	[serializer serializeCubicCurveToPoint:element->points[2] controlPoint1:element->points[0] controlPoint2:element->points[1]];
}

static void RXCGPathSerializeCloseElement(RXPathSerializer *serializer, const CGPathElement *element) {
	[serializer serializeCloseSubpath];
}

static void RXCGPathSerializeElement(void *info, const CGPathElement *element) {
	RXPathSerializer *serializer = *(RXPathSerializer * __strong *)info;
	
	static RXCGPathSerializeElementFunction elementFunctions[] = {
		RXCGPathSerializeMoveElement,
		RXCGPathSerializeLineElement,
		RXCGPathSerializeQuadraticCurveElement,
		RXCGPathSerializeCubicCurveElement,
		RXCGPathSerializeCloseElement
	};
	
	(elementFunctions[element->type])(serializer, element);
}

+(NSData *)dataWithPath:(CGPathRef)path error:(NSError * __autoreleasing *)error {
	NSParameterAssert(path != NULL);
	
	NSMutableData *data = [NSMutableData new];
	RXPathSerializer *serializer = [RXPathSerializer serializerWithMutableData:data];
	
	CGPathApply(path, &serializer, RXCGPathSerializeElement);
	
	return data;
}


#pragma mark Deserialization

+(CGPathRef)newPathWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
	NSParameterAssert(data != nil);
	
	RXPathDeserializer *deserializer = [RXPathDeserializer deserializerWithData:data];
	CGMutablePathRef path = CGPathCreateMutable();
	
	deserializer.moveHandler = ^(CGPoint point) {
		CGPathMoveToPoint(path, NULL, point.x, point.y);
	};
	
	deserializer.lineHandler = ^(CGPoint point) {
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
	};
	
	deserializer.quadraticCurveHandler = ^(CGPoint controlPoint, CGPoint endPoint) {
		CGPathAddQuadCurveToPoint(path, NULL, controlPoint.x, controlPoint.y, endPoint.x, endPoint.y);
	};
	
	deserializer.cubicCurveHandler = ^(CGPoint controlPoint1, CGPoint controlPoint2, CGPoint endPoint) {
		CGPathAddCurveToPoint(path, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);
	};
	
	deserializer.closeHandler = ^{
		CGPathCloseSubpath(path);
	};
	
	if(![deserializer deserializeWithError:error]) {
		CGPathRelease(path);
		path = NULL;
	}
	return path;
}

@end
