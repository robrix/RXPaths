//  RXPathSerialization.m
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Black Pixel. All rights reserved.

#import "RXPathSerialization.h"

NSString * const RXPathSerializationErrorDomain = @"RXPathSerializationErrorDomain";
NSString * const RXPathSerializationIndexErrorKey = @"RXPathSerializationIndexErrorKey";

@implementation RXPathSerializer {
	NSMutableData *data;
}

+(RXPathSerializer *)serializerWithMutableData:(NSMutableData *)data {
	NSParameterAssert(data != nil);
	
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
	NSData *data;
	id<RXPathBuilder> builder;
	const char *start;
	const char *end;
	const char *cursor;
	NSError *error;
}

+(RXPathDeserializer *)deserializerWithData:(NSData *)data pathBuilder:(id<RXPathBuilder>)builder {
	NSParameterAssert(data != nil);
	
	RXPathDeserializer *deserializer = [self new];
	deserializer->data = data;
	deserializer->builder = builder;
	return deserializer;
}


static NSString *RXPathDeserializerInvalidDataDescription(RXPathDeserializer *self, const char *cursor, NSString *noun) {
	NSUInteger index = cursor - self->start;
	NSUInteger remainingLength = self->end - cursor;
	return [NSString stringWithFormat:NSLocalizedString(@"Invalid %1@ from %2$u: %3$.*4$s", @"Phrase describing parse failure with placeholders for noun describing the data that was being parsed, index where parsing stopped, byte array beginning at that index, and remaining data within the data being parsed."), noun, index, cursor, remainingLength];
}


static BOOL RXPathDeserializerAcceptType(RXPathDeserializer *self, RXPathElementType type) {
	BOOL didAdvance = NO;
	if((didAdvance = (*self->cursor == type)))
		self->cursor++;
	return didAdvance;
}

static BOOL RXPathDeserializerExpectPoint(RXPathDeserializer *self, CGPoint *point) {
	double x = 0, y = 0;
	NSUInteger bytesConsumed = 0;
	sscanf(self->cursor, " %lf %lf %n", &x, &y, &bytesConsumed);
	if(bytesConsumed > 0) {
		if(point)
			*point = (CGPoint){ x, y };
		self->cursor += bytesConsumed;
	} else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  RXPathDeserializerInvalidDataDescription(self, self->cursor, NSLocalizedString(@"point", @"Singular noun describing a cartesian 2-vector used in a path element.")), NSLocalizedDescriptionKey,
								  [NSNumber numberWithUnsignedInteger:self->cursor - self->start], RXPathSerializationIndexErrorKey,
								  nil];
		self->error = [NSError errorWithDomain:RXPathSerializationErrorDomain code:RXPathSerializationInvalidDataErrorCode userInfo:userInfo];
	}
	return bytesConsumed;
}

static BOOL RXPathDeserializeMoveElement(RXPathDeserializer *self) {
	CGPoint point = CGPointZero;
	BOOL didAdvance =
		RXPathDeserializerAcceptType(self, RXPathMoveElementType)
	&&	RXPathDeserializerExpectPoint(self, &point);
	if(didAdvance)
		[self->builder moveToPoint:point];
	return didAdvance;
}

static BOOL RXPathDeserializeLineElement(RXPathDeserializer *self) {
	CGPoint point = CGPointZero;
	BOOL didAdvance =
		RXPathDeserializerAcceptType(self, RXPathLineElementType)
	&&	RXPathDeserializerExpectPoint(self, &point);
	if(didAdvance)
		[self->builder addLineToPoint:point];
	return didAdvance;
}

static BOOL RXPathDeserializeQuadraticCurveElement(RXPathDeserializer *self) {
	CGPoint point = CGPointZero, controlPoint = CGPointZero;
	BOOL didAdvance =
		RXPathDeserializerAcceptType(self, RXPathQuadraticCurveElementType)
	&&	RXPathDeserializerExpectPoint(self, &controlPoint)
	&&	RXPathDeserializerExpectPoint(self, &point);
	if(didAdvance)
		[self->builder addQuadCurveToPoint:point controlPoint:controlPoint];
	return didAdvance;
}

static BOOL RXPathDeserializeCubicCurveElement(RXPathDeserializer *self) {
	CGPoint point = CGPointZero, controlPoint1 = CGPointZero, controlPoint2 = CGPointZero;
	BOOL didAdvance =
		RXPathDeserializerAcceptType(self, RXPathCubicCurveElementType)
	&&	RXPathDeserializerExpectPoint(self, &controlPoint1)
	&&	RXPathDeserializerExpectPoint(self, &controlPoint2)
	&&	RXPathDeserializerExpectPoint(self, &point);
	if(didAdvance)
		[self->builder addCurveToPoint:point controlPoint1:controlPoint1 controlPoint2:controlPoint2];
	return didAdvance;
}

static BOOL RXPathDeserializeCloseElement(RXPathDeserializer *self) {
	BOOL didAdvance = RXPathDeserializerAcceptType(self, RXPathCloseElementType);
	if(didAdvance)
		[self->builder closePath];
	return didAdvance;
}

static BOOL RXPathDeserializerExpectElement(RXPathDeserializer *self) {
	const char *initial = self->cursor;
	BOOL didAdvance =
		RXPathDeserializeMoveElement(self)
	||	RXPathDeserializeLineElement(self)
	||	RXPathDeserializeQuadraticCurveElement(self)
	||	RXPathDeserializeCubicCurveElement(self)
	||	RXPathDeserializeCloseElement(self);
	if(!didAdvance && !self->error) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  RXPathDeserializerInvalidDataDescription(self, initial, NSLocalizedString(@"element", @"Singular noun describing a single component (move, line, curve, etc) of a path")), NSLocalizedDescriptionKey,
								  [NSNumber numberWithUnsignedInteger:self->cursor - self->start], RXPathSerializationIndexErrorKey,
								  nil];
		self->error = [NSError errorWithDomain:RXPathSerializationErrorDomain code:RXPathSerializationInvalidDataErrorCode userInfo:userInfo];
	}
	return didAdvance;
}

-(BOOL)deserializeWithError:(NSError *__autoreleasing *)outError {
	cursor = start = data.bytes;
	end = data.bytes + data.length;
	
	BOOL didAdvance = NO;
	while(cursor < end) {
		if(!(didAdvance = RXPathDeserializerExpectElement(self))) {
			if(outError)
				*outError = error;
			break;
		}
	}
	return didAdvance;
}

@end
