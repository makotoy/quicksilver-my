//
//  QSDictionaryUtility.m
//  DictPlugin
//
//  Created by Makoto Yamashita on 2/20/10.
//  Copyright 2010 Quicksilver project. All rights reserved.
//

#import "QSDictionaryUtility.h"


void showResultsWindow(NSString *input, NSString *title, id delegate)
{
	NSRect windowRect = NSMakeRect(0, 0, 455, 490);
	NSRect screenRect = [[NSScreen mainScreen] frame];
	QSWindow *window = [[QSWindow alloc] initWithContentRect:windowRect
												   styleMask:(NSTitledWindowMask | NSClosableWindowMask |
															  NSUtilityWindowMask | NSResizableWindowMask |
															  NSNonactivatingPanelMask)
													 backing:NSBackingStoreBuffered defer: NO];
	[window setFrameUsingName:kDictWindowName];
	windowRect = [window frame];
	NSRect centeredRect = centerRectInRect(windowRect, screenRect);
	[window setFrame:centeredRect display:YES];
	[window setOneShot:YES];
	[window setReleasedWhenClosed:YES];
	[window setShowOffset:NSMakePoint(-16, 16)];
	[window setHideOffset:NSMakePoint(16, -16)];
	[window setHidesOnDeactivate:NO];
	[window setMinSize:NSMakeSize(400, 280)];
	[window setMaxSize:NSMakeSize(600, FLT_MAX)];
	[window setTitle:title];
	
	if (delegate) [window setDelegate:delegate];
	
	NSScrollView *scrollView = [[[NSScrollView alloc]
                                 initWithFrame:[[window contentView] frame]] autorelease];
	[scrollView setBorderType:NSNoBorder];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	NSSize contentSize = [scrollView contentSize];
	NSTextView *textView = [[[NSTextView alloc] initWithFrame:(NSRect){{0,0},contentSize}] autorelease];
	[textView setMinSize:NSMakeSize(0.0, contentSize.height)];
	[textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[textView setVerticallyResizable:YES];
	[textView setHorizontallyResizable:NO];
	[textView setAutoresizingMask:NSViewWidthSizable];
	
	[textView setString:input];
	[textView setEditable:NO];
	[textView setSelectable:YES];
	
	[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
	[[textView textContainer] setWidthTracksTextView:YES];
	
	[scrollView setDocumentView:textView];
	[window setContentView:scrollView];
	[[window contentView] display];
	[window setLevel:NSFloatingWindowLevel];
	[window makeKeyAndOrderFront:nil];
	[window setLevel:NSNormalWindowLevel];
	[window makeFirstResponder:textView];
}
