//
//  NSColor+QSCGColorRef
//  Fester
//
//  Created by Nicholas Jitkoff on 10/20/07.
//  Copyright 2007 Google Inc. All rights reserved.
//
//  2010-01-16 Makoto Yamashita

#import "NSColor+QSCGColorRef.h"


@implementation NSColor (createCGColorRef)
- (CGColorRef)CGColorRef
{
    NSColor *rgbColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat components[4];
  
	[rgbColor getRed: &components[0] green: &components[1]
              blue: &components[2] alpha: &components[3]];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGColorRef resColor = CGColorCreate(colorSpace, components);
    CGColorSpaceRelease(colorSpace);

    return (CGColorRef)[(id)resColor autorelease];
}
@end
