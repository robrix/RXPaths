//  RXCGPathSerialization.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Monochrome Industries. All rights reserved.

#import "RXCGPathSerialization.h"
#import "RXPathSerialization.h"

NSString * const RXCGPathSerializationErrorDomain = @"RXCGPathSerializationErrorDomain";
NSString * const RXCGPathSerializationIndexErrorKey = @"RXCGPathSerializationIndexErrorKey";

typedef void (*RXCGPathSerializeElementFunction)(RXPathSerializer *serializer, const CGPathElement *element);


@interface RXCGPathDeserializationState : NSObject

@property (nonatomic, assign) const char *start;
@property (nonatomic, assign) const char *end;
@property (nonatomic, assign) const char *cursor;
@property (nonatomic, strong) NSError *error;

@end

@implementation RXCGPathDeserializationState

@synthesize start, end, cursor, error;

@end


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

static BOOL RXCGPathExpectType(RXCGPathDeserializationState *state, RXPathElementType type) {
	BOOL advanced = NO;
	if((advanced = (*state.cursor == type))) {
		state.cursor++;
	}
	return advanced;
}

static BOOL RXCGPathExpectPoint(RXCGPathDeserializationState *state, CGPoint *point) {
	double x = 0, y = 0;
	NSUInteger bytesConsumed = 0;
	sscanf(state.cursor, " %lf %lf %n", &x, &y, &bytesConsumed);
	if(bytesConsumed > 0) {
		if(point)
			*point = (CGPoint){ x, y };
		state.cursor += bytesConsumed;
	} else {
		NSUInteger index = state.cursor - state.start;
		NSUInteger remainingLength = state.end - state.cursor;
		NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Invalid point from %1$u: %2$.*3$s", @""), index, state.cursor, remainingLength];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  description, NSLocalizedDescriptionKey,
								  [NSNumber numberWithUnsignedInteger:index], RXCGPathSerializationIndexErrorKey,
								  nil];
		state.error = [NSError errorWithDomain:RXCGPathSerializationErrorDomain code:RXCGPathSerializationInvalid userInfo:userInfo];
	}
	return bytesConsumed;
}

static BOOL RXCGPathDeserializeMoveElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	CGPoint point = CGPointZero;
	BOOL advanced =
		RXCGPathExpectType(state, RXPathMoveElementType)
	&&	RXCGPathExpectPoint(state, &point);
	if(advanced)
		CGPathMoveToPoint(path, NULL, point.x, point.y);
	return advanced;
}

static BOOL RXCGPathDeserializeLineElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	CGPoint point = CGPointZero;
	BOOL advanced =
		RXCGPathExpectType(state, RXPathLineElementType)
	&&	RXCGPathExpectPoint(state, &point);
	if(advanced)
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
	return advanced;
}

static BOOL RXCGPathDeserializeQuadraticCurveElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	CGPoint point1 = CGPointZero, point2 = CGPointZero;
	BOOL advanced =
		RXCGPathExpectType(state, RXPathQuadraticCurveElementType)
	&&	RXCGPathExpectPoint(state, &point1)
	&&	RXCGPathExpectPoint(state, &point2);
	if(advanced)
		CGPathAddQuadCurveToPoint(path, NULL, point1.x, point1.y, point2.x, point2.y);
	return advanced;
}

static BOOL RXCGPathDeserializeCubicCurveElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	CGPoint point1 = CGPointZero, point2 = CGPointZero, point3 = CGPointZero;
	BOOL advanced =
		RXCGPathExpectType(state, RXPathCubicCurveElementType)
	&&	RXCGPathExpectPoint(state, &point1)
	&&	RXCGPathExpectPoint(state, &point2)
	&&	RXCGPathExpectPoint(state, &point3);
	if(advanced)
		CGPathAddCurveToPoint(path, NULL, point1.x, point1.y, point2.x, point2.y, point3.x, point3.y);
	return advanced;
}

static BOOL RXCGPathDeserializeCloseElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	BOOL advanced = RXCGPathExpectType(state, RXPathCloseElementType);
	if(advanced)
		CGPathCloseSubpath(path);
	return advanced;
}

static BOOL RXCGPathDeserializeElement(CGMutablePathRef path, RXCGPathDeserializationState *state) {
	const char *initial = state.cursor;
	BOOL advanced =
		RXCGPathDeserializeMoveElement(path, state)
	||	RXCGPathDeserializeLineElement(path, state)
	||	RXCGPathDeserializeQuadraticCurveElement(path, state)
	||	RXCGPathDeserializeCubicCurveElement(path, state)
	||	RXCGPathDeserializeCloseElement(path, state);
	if(!advanced && !state.error) {
		NSUInteger index = initial - state.start;
		NSUInteger remainingLength = state.end - initial;
		NSString *description = [NSString stringWithFormat:NSLocalizedString(@"Invalid element from %1$u: %2$.*3$s", @""), index, initial, remainingLength];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  description, NSLocalizedDescriptionKey,
								  [NSNumber numberWithUnsignedInteger:index], RXCGPathSerializationIndexErrorKey,
								  nil];
		state.error = [NSError errorWithDomain:RXCGPathSerializationErrorDomain code:RXCGPathSerializationInvalid userInfo:userInfo];
	}
	return advanced;
}

+(CGPathRef)newPathWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
	NSParameterAssert(data != nil);
	
	RXCGPathDeserializationState *state = [RXCGPathDeserializationState new];
	CGMutablePathRef path = CGPathCreateMutable();
	
	state.start = state.cursor = data.bytes;
	state.end = state.cursor + data.length;
	
	while(state.cursor < state.end) {
		if(!RXCGPathDeserializeElement(path, state)) {
			CGPathRelease(path);
			path = NULL;
			if(error)
				*error = state.error;
			break;
		}
	}
	return path;
}

@end
