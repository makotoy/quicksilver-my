//
//  NSCursor_InformExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu May 06 2004.

//  2010-01-16 Makoto Yamashita

#import "NSCursor_InformExtensions.h"

#import "NSBezierPath_BLTRExtensions.h"

#define informAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:9], NSFontAttributeName,[NSColor darkGrayColor],NSForegroundColorAttributeName,[NSNumber numberWithFloat:1],NSBaselineOffsetAttributeName,nil]


@implementation NSCursor (InformExtensions)
+ informativeCursorWithString:(NSString *)string{
	
	if (![string length])return [self arrowCursor];
	NSSize size=[string sizeWithAttributes:informAttributes];
	NSImage *arrowImage=[[self arrowCursor] image];
	NSSize arrowSize=[arrowImage size];
	NSRect textRect=NSMakeRect(16,1,size.width,size.height);
	NSPoint padding=NSMakePoint(size.height/2,1);
	textRect=NSOffsetRect(textRect,padding.x,padding.y);
	NSRect blobRect=NSInsetRect(textRect,-padding.x,-padding.y);
	NSRect cursorRect=NSMakeRect(0,0,arrowSize.width,arrowSize.height);
	NSRect imageRect=NSUnionRect(NSInsetRect(blobRect,-1,-1),cursorRect);
	
	//imageRect=NSInsetRect(imageRect,0,NSHeight(imageRect)/2);
	
	NSImage * cImg=[[NSImage alloc] initWithSize:imageRect.size];
	NSBezierPath *roundRect=[NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:blobRect withRadius:size.height/2 indent:NO];
	
	[cImg lockFocus];
    [arrowImage drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, [arrowImage size].width, [arrowImage size].height) operation:NSCompositeSourceOver fraction:1.0];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.7]setFill];
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3]setStroke];
	[roundRect fill];  
	[roundRect stroke];
	
	[string drawInRect:textRect withAttributes:informAttributes];
	[cImg unlockFocus];
	return [[[NSCursor alloc] initWithImage:[cImg autorelease] hotSpot:NSZeroPoint] autorelease];
}

@end
