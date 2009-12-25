//
//  QSShadowView.h
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/26/06.
//  Copyright 2006 Blacktree, Inc. All rights reserved.
//
//  Makoto Yamashita 2009-12-25

#import <Cocoa/Cocoa.h>


@interface QSShadowView : NSView {
	NSView *targetView;
	NSColor *color;
	float blur;
	float distance;
	float angle;
	float expand;
}

- (NSRect)paddedFrameForFrame:(NSRect)frame;
- (void)updatePosition;

@property (retain) NSView* targetView;
@property (copy) NSColor* color;
@property (assign) float blur;
@property (assign) float distance;
@property (assign) float angle;
@property (assign) float expand;
@end
