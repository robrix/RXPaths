//  RXPathSerialization.h
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Black Pixel. All rights reserved.

#import <Foundation/Foundation.h>

enum {
	RXPathMoveElementType = 'M',
	RXPathLineElementType = 'L',
	RXPathQuadraticCurveElementType = 'Q',
	RXPathCubicCurveElementType = 'C',
	RXPathCloseElementType = 'Z',
};
typedef const char RXPathElementType;

typedef void (^RXPathElementHandler)(RXPathElementType type, CGPoint *points);
typedef void (^RXPathMoveBlock)(CGPoint point);
typedef void (^RXPathLineBlock)(CGPoint point);
typedef void (^RXPathQuadraticCurveBlock)(CGPoint point1, CGPoint point2);
typedef void (^RXPathCubicCurveBlock)(CGPoint point1, CGPoint point2, CGPoint point3);
typedef void (^RXPathCloseBlock)();

@interface RXPathSerializer : NSObject

+(RXPathSerializer *)serializerWithMutableData:(NSMutableData *)data;

-(void)serializeMoveToPoint:(CGPoint)point;
-(void)serializeLineToPoint:(CGPoint)point;
-(void)serializeQuadraticCurveToPoint:(CGPoint)point controlPoint:(CGPoint)controlPoint;
-(void)serializeCubicCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2;
-(void)serializeCloseSubpath;

@end

@interface RXPathDeserializer : NSObject

+(void)deserializePathWithData:(NSData *)data
				   moveHandler:(RXPathMoveBlock)move
				   lineHandler:(RXPathLineBlock)line
		 quadraticCurveHandler:(RXPathQuadraticCurveBlock)quadratic
			 cubicCurveHandler:(RXPathCubicCurveBlock)cubic
				  closeHandler:(RXPathCloseBlock)close
						 error:(NSError * __autoreleasing *)error;

+(void)deserializePathWithData:(NSData *)data
				elementHandler:(RXPathElementHandler)element
						 error:(NSError * __autoreleasing *)error;

@end
