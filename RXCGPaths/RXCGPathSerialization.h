//  RXCGPathSerialization.h
//  Created by Rob Rix on 12-04-08.
//  Copyright (c) 2012 Monochrome Industries. All rights reserved.

#import <Foundation/Foundation.h>

@interface RXCGPathSerialization : NSObject

+(NSData *)dataWithPath:(CGPathRef)path error:(NSError * __autoreleasing *)error;
+(CGPathRef)newPathWithData:(NSData *)data error:(NSError * __autoreleasing *)error;

@end
