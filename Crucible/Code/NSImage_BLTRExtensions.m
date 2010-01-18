//
//  NSImage_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Apr 24 2003.

//  Makoto Yamashita 2010-01-04

#import <QuartzCore/QuartzCore.h>
#import "NSImage_BLTRExtensions.h"
#import "NSGeometry_BLTRExtensions.h"

static inline int get_bit(unsigned char *arr, unsigned long bit_num)
{
    return ( arr[(bit_num/8)] & (1 << (bit_num%8)) );
}

@implementation NSBitmapImageRep (Stego)
/*
 - (void)embedMessage:(NSString *)message inChannel:(int)channel {
 unsigned char *pixels = [self bitmapData];
 
 // In the following loop, i is the horizontal coordinate of the pixel, and
 // j is the vertical component.
 // i loops over columns, j loops over rows
 int i;
 int j;
 for(j = 0; j < imageHeightInPixels; j++)
 {
 for (i = 0; i < imageWidthInPixels; i++)
 {
 
 pixels[(j*imageWidthInPixels+i) *bitsPerPixel+channel]
 
 
 
 *pixels++ = fractColor.red;
 *pixels++ = fractColor.blue;
 *pixels++ = fractColor.green;
 *pixels++ = fractColor.alpha;
 
 }
 }
 
 }
 */
@end

@implementation NSImage (Dragging)

// ***warning   * this needs to fade all representations
- (NSImage *)imageWithAlphaComponent:(float)alpha
{
    // BOOL wasFlipped = [self isFlipped];
    NSImage *fadedImage = [[[NSImage alloc] initWithData:[self TIFFRepresentation]]autorelease];
    [fadedImage setCacheMode:NSImageCacheNever];

    NSEnumerator *repEnum = [[fadedImage representations] objectEnumerator];
    NSImageRep *rep = nil;
    while((rep = [repEnum nextObject]) ) {
        [fadedImage lockFocusOnRepresentation:rep];
            
        [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
        NSRectFillUsingOperation(rectFromSize([rep size]), NSCompositeDestinationIn);

        [fadedImage unlockFocus];
    }
    return fadedImage;
}

@end

@implementation NSImage (Scaling)

- (NSImage *)imageByAdjustingHue:(CGFloat)hue
{
    return [self imageByAdjustingHue:hue saturation:1.0];
}

- (NSImage *)imageByAdjustingHue:(CGFloat)hue saturation:(CGFloat)saturation
{
    CGImageRef imgRef = [self CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    CIImage* sourceImg = [CIImage imageWithCGImage:imgRef];
    
    if (!sourceImg) {
        NSLog(@"could not create an sounce image");
        return self;
    }
    CIFilter* hueAdjust = [CIFilter filterWithName:@"CIHueAdjust"];
    [hueAdjust setDefaults];
    [hueAdjust setValue:sourceImg forKey: @"inputImage"];
    [hueAdjust setValue:[NSNumber numberWithFloat:hue]
                 forKey:@"inputAngle"];
    CIFilter* satAdjust = [CIFilter filterWithName:@"CIColorControls"];
    [satAdjust setDefaults];
    [satAdjust setValue:[hueAdjust valueForKey: @"outputImage"]
                 forKey:@"inputImage"];
    [satAdjust setValue:[NSNumber numberWithFloat:saturation]
                 forKey:@"inputSaturation"];
    CIImage* outImg = [satAdjust valueForKey: @"outputImage"];
    NSImage* newImage = [[NSImage alloc] initWithSize:[self size]];
    [newImage lockFocus];
    [outImg drawAtPoint:NSZeroPoint
               fromRect:NSMakeRect(0, 0, CGRectGetHeight([outImg extent]), CGRectGetWidth([outImg extent]))
              operation:NSCompositeCopy
               fraction:1.0];
    [newImage unlockFocus];
    return [newImage autorelease];
}

- (NSSize) adjustSizeToDrawAtSize:(NSSize)theSize
{
  NSImageRep *bestRep = [self bestRepresentationForSize:theSize];
  [self setSize:[bestRep size]];
  return [bestRep size];
}

- (NSImageRep *)bestRepresentationForSize:(NSSize)theSize
{
	NSImageRep *bestRep = [self representationOfSize:theSize];

    if (bestRep) return bestRep;
    
    NSArray *reps = [self representations];
    // ***warning   * handle other sizes
    float repDistance = 65536.0;  
    // ***warning   * this is totally not the highest, but hey...
    float thisDistance;
    for (id thisRep in reps) {
        thisDistance = MIN(theSize.width - [thisRep size].width,
                           theSize.height - [thisRep size].height);  

		if (repDistance<0 && thisDistance>0) continue;

        if (ABS(thisDistance) <ABS(repDistance) || (thisDistance<0 && repDistance>0)) {
            repDistance = thisDistance;
            bestRep = thisRep;
        }
    }
    if (bestRep) return bestRep;
    bestRep = [self bestRepresentationForRect:NSMakeRect(0, 0, theSize.width, theSize.height)
                                      context:nil
                                        hints:nil];
    return bestRep;
}

- (NSImageRep *)representationOfSize:(NSSize)theSize
{
  NSArray *reps = [self representations];
  int i;
  for (i = 0; i<(int) [reps count]; i++)
    if (NSEqualSizes([[reps objectAtIndex:i] size] , theSize) )
      return [reps objectAtIndex:i];
  return nil;
}

- (BOOL)createIconRepresentations {
  [self setFlipped:NO];
	
	//[self createRepresentationOfSize:NSMakeSize(128, 128)];
  [self createRepresentationOfSize:NSMakeSize(32, 32)];
  [self createRepresentationOfSize:NSMakeSize(16, 16)];
  [self setScalesWhenResized:NO];
  return YES;
}


- (BOOL)createRepresentationOfSize:(NSSize)newSize { 
	// ***warning   * !? should this be done on the main thread?
  //
  
  if ([self representationOfSize:newSize]) return NO;
  
  
  
	NSBitmapImageRep *bestRep = (NSBitmapImageRep *)[self bestRepresentationForSize:newSize];
  if ([bestRep respondsToSelector:@selector(CGImage)]) {
    CGImageRef imageRef = [bestRep CGImage];
  
    CGColorSpaceRef cspace        = CGColorSpaceCreateDeviceRGB();    
    CGContextRef    smallContext        = CGBitmapContextCreate(NULL,
                                                                newSize.width,
                                                                newSize.height,
                                                                8,            // bits per component
                                                                newSize.width * 4, // bytes per pixel
                                                                cspace,
                                                                kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast);
    CFRelease(cspace);
    
    if (!smallContext) return NO;
    
    NSRect drawRect = fitRectInRect(rectFromSize([bestRep size]), rectFromSize(newSize), NO);
    
        CGContextDrawImage(smallContext, NSRectToCGRect(drawRect), imageRef);
    
    CGImageRef smallImage = CGBitmapContextCreateImage(smallContext);
    if (smallImage) {
      NSBitmapImageRep *cgRep = [[[NSBitmapImageRep alloc] initWithCGImage:smallImage] autorelease];
      [self addRepresentation:cgRep];      
    }
    CGImageRelease(smallImage);
    CGContextRelease(smallContext);
    
    return YES;
  }
  
  
  
  //
//  {
//    NSDate *date = [NSDate date];
//    NSData *data = [(NSBitmapImageRep *)bestRep TIFFRepresentation];
//    
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);  
//    CGImageSourceRef isrc = CGImageSourceCreateWithDataProvider (provider, NULL);
//    CGDataProviderRelease( provider );
//    
//    NSDictionary* thumbOpts = [NSDictionary dictionaryWithObjectsAndKeys:
//                               (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
//                               (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
//                               [NSNumber numberWithInt:newSize.width], (id)kCGImageSourceThumbnailMaxPixelSize,
//                               nil];
//    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex (isrc, 0, (CFDictionaryRef)thumbOpts);
//    if (isrc) CFRelease(isrc);
//    
//    NSBitmapImageRep *cgRep = [[[NSBitmapImageRep alloc] initWithCGImage:thumbnail] autorelease];
//    CGImageRelease(thumbnail);
//    NSLog(@"time1 %f", -[date timeIntervalSinceNow]);
//  }
//
//  
//
//  
//  {
//    NSDate *date = [NSDate date];
//    NSImage* scaledImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
//    [scaledImage lockFocus];
//    NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
//    [graphicsContext setImageInterpolation:NSImageInterpolationHigh];
//    [graphicsContext setShouldAntialias:YES];
//    NSRect drawRect = fitRectInRect(rectFromSize([bestRep size]), rectFromSize(newSize), NO);
//    [bestRep drawInRect:drawRect];
//    NSBitmapImageRep* nsRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, newSize.width, newSize.height)] autorelease];
//    [scaledImage unlockFocus];
//    
//    NSLog(@"time3 %f", -[date timeIntervalSinceNow]);
//  }
  //  [self addRepresentation:rep];
  
  return YES;
  

  
  //  
  //  
  //  [self addRepresentation:iconRep];
  //  return YES;
}

- (void)removeRepresentationsLargerThanSize:(NSSize)size {
  NSEnumerator *e = [[self representations] reverseObjectEnumerator];
  NSImageRep *thisRep;
	while((thisRep = [e nextObject]) ) {
		if ([thisRep size] .width>size.width && [thisRep size] .height>size.height)
			[self removeRepresentation:thisRep];
  } 	
}

- (NSImage *)duplicateOfSize:(NSSize)newSize {
	NSImage *dup = [[self copy] autorelease];
	[dup shrinkToSize:newSize];
	[dup setFlipped:NO];
	return dup;
}

- (BOOL)shrinkToSize:(NSSize)newSize {
	[self createRepresentationOfSize:newSize];
	[self setSize:newSize];
	[self removeRepresentationsLargerThanSize:newSize];
	return YES;
}



@end

@implementation  NSImage (Trim)
- (NSRect) usedRect
{
    NSData* tiffData = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:tiffData];
	NSRect resRect;
    if (![bitmap hasAlpha]) {
        resRect = NSMakeRect(0, 0, [bitmap size] .height, [bitmap size] .width);
        [bitmap release], bitmap = nil;        
        return resRect;
	}
  int minX = [bitmap pixelsWide];
  int minY = [bitmap pixelsHigh];
  int maxX = 0;
  int maxY = 0;
  int i, j;
  unsigned char* pixels = [bitmap bitmapData];
	
  for (i = 0; i < [bitmap pixelsWide]; i++) {
    for (j = 0; j<[bitmap pixelsHigh]; j++) {
      if (*(pixels + j*[bitmap pixelsWide] *[bitmap samplesPerPixel] + i*[bitmap samplesPerPixel] + 3) ) {
          //This pixel is not transparent! Readjust bounds.
        minX = MIN(minX, i);
        maxX = MAX(maxX, i);
        minY = MIN(minY, j);
        maxY = MAX(maxY, j);
      }			
    }
  }
    resRect = NSMakeRect(minX, [bitmap pixelsHigh] -maxY-1, maxX-minX+1, maxY-minY+1);
  [bitmap release], bitmap = nil;

  return resRect;
}

- (NSImage *)scaleImageToSize:(NSSize)newSize trim:(BOOL)trim expand:(BOOL)expand scaleUp:(BOOL)scaleUp
{
    NSRect sourceRect = (trim?[self usedRect] :rectFromSize([self size]) );
    NSRect drawRect = (scaleUp || NSHeight(sourceRect) >newSize.height || NSWidth(sourceRect)>newSize.width ? sizeRectInRect(sourceRect, rectFromSize(newSize), expand) : NSMakeRect(0, 0, NSWidth(sourceRect), NSHeight(sourceRect)));
    NSImage *tempImage = [[NSImage alloc] initWithSize:NSMakeSize(NSWidth(drawRect), NSHeight(drawRect) )];
    [tempImage lockFocus];
    {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [self drawInRect:drawRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1];
    }
    [tempImage unlockFocus];
    [tempImage autorelease];
  return [[[NSImage alloc] initWithData:[tempImage TIFFRepresentation]]autorelease];
    //*** UGH! why do I have to do this to commit the changes?;
}
@end

@implementation NSImage (Average)
- (NSColor *)averageColor
{
    for (id rep in [self representations]) {
        if (![rep isKindOfClass:[NSBitmapImageRep class]]) continue;

        CGFloat redMean, blueMean, greenMean, redContrib, blueContrib, greenContrib;
        NSUInteger x, y, area = [rep size].width * [rep size].height;
        for (x = 0; x < [rep size].width; x++) {
            for (y = 0; y < [rep size].height; y++) {
                [[rep colorAtX:x y:y] getRed:&redContrib
                                       green:&greenContrib
                                        blue:&blueContrib
                                       alpha:NULL];
                redMean += redContrib / area;
                greenMean += greenContrib / area;
                blueMean += blueContrib / area;
            }
        }
        NSColor *color = [NSColor colorWithDeviceRed:redMean
                                               green:greenMean
                                                blue:blueMean
                                               alpha:1.0];
        return color;
    }
    return nil;
}

@end
