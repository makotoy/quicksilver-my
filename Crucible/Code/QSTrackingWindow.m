//
//  QSTrackingwindow.m
//  Quicksilver
//
//  Created by Alcor on 7/5/04.

//  2010-01-03 Makoto Yamashita.

#import "QSTrackingWindow.h"
#import "QSTypes.h"

@implementation QSTrackingWindow
+(QSTrackingWindow *)trackingWindow
{
	QSTrackingWindow* window = [[QSTrackingWindow alloc] initWithContentRect:NSZeroRect
                                                                   styleMask:NSBorderlessWindowMask
                                                                     backing:NSBackingStoreRetained
                                                                       defer:YES];
	[window setBackgroundColor:[[NSColor redColor]colorWithAlphaComponent:0.5]];
	[window setOpaque:NO];
	[window setIgnoresMouseEvents:YES];
	[window setHasShadow:NO];
	[window setLevel:kCGPopUpMenuWindowLevel - 1];
	[window setSticky:YES];
    [window registerForDraggedTypes:standardPasteboardTypes];
	return [window autorelease];
}

- (void)sendEvent:(NSEvent *)theEvent
{
    [super sendEvent:theEvent];
}

- (void)updateTrackingRect
{
    if (trackingRect) [[self contentView] removeTrackingRect:trackingRect];
    
    trackingRect = [[self contentView] addTrackingRect:NSMakeRect(0,0, NSWidth([self frame]), NSHeight([self frame]))
                                                 owner:self
                                              userData:self
                                          assumeInside:NO];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
	[super setFrame:frameRect display:flag];
	[self updateTrackingRect];
}

- (void)mouseEntered:(NSEvent *)theEvent{
	QSLog(@"entered tracking");
	[(NSResponder*)[self delegate] mouseEntered:theEvent];	
}

- (void)mouseExited:(NSEvent *)theEvent{
	QSLog(@"exited tracking");
	[(NSResponder*)[self delegate] mouseExited:theEvent];	
}

- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)theEvent
{
    
	QSLog(@"dragging tracking");
	[(NSResponder*)[self delegate] mouseEntered:nil];	
	return NSDragOperationEvery;
}

- (BOOL)canBecomeKeyWindow{return NO;}
- (BOOL)canBecomeMainWindow{return NO;}

@end
