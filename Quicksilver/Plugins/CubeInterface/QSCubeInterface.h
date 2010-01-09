//
//  QSCubeInterface.h
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/14/06.
//  Copyright 2006 Blacktree, Inc.. All rights reserved.
//
//  Makoto Yamashita 2009-12-25

#import <Cocoa/Cocoa.h>

@interface QSCubeInterface : QSResizingInterfaceController <NSWindowDelegate> {
	NSRect standardRect;
	IBOutlet NSTextField *detailsTextField;
	IBOutlet NSTextField *searchTextField;
	IBOutlet NSTextField *commandField;
	NSView *lastSearchField;
	NSRect positionC,positionL,positionR,positionO; //Center, left, right, out positions
	NSControl *currentControl;
	NSWindow *shadowWindow;
	NSWindow *backdropWindow;
}

- (NSWindow *)shadowWindow;
- (NSWindow *)backdropWindow;

- (BOOL)useBackdrop;

- (NSRect)rectForState:(BOOL)expanded;
- (void)updateSearchViewsForTarget:(NSResponder *)responder;
@end
