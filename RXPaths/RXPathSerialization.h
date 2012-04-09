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

extern NSString * const RXPathSerializationErrorDomain;
extern NSString * const RXPathSerializationIndexErrorKey;
enum {
	RXPathSerializationInvalidDataErrorCode = 1,
};

typedef void (^RXPathElementHandler)(RXPathElementType type, CGPoint *points);
typedef void (^RXPathMoveBlock)(CGPoint point);
typedef void (^RXPathLineBlock)(CGPoint point);
typedef void (^RXPathQuadraticCurveBlock)(CGPoint controlPoint, CGPoint endPoint);
typedef void (^RXPathCubicCurveBlock)(CGPoint controlPoint1, CGPoint controlPoint2, CGPoint endPoint);
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

+(RXPathDeserializer *)deserializerWithData:(NSData *)data;

@property (nonatomic, copy) RXPathMoveBlock moveHandler;
@property (nonatomic, copy) RXPathLineBlock lineHandler;
@property (nonatomic, copy) RXPathQuadraticCurveBlock quadraticCurveHandler;
@property (nonatomic, copy) RXPathCubicCurveBlock cubicCurveHandler;
@property (nonatomic, copy) RXPathCloseBlock closeHandler;

-(BOOL)deserializeWithError:(NSError * __autoreleasing *)error;

@end
