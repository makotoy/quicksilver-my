
//  SLKeyPopUpButton.m
//  Searchling
//
//  Created by Alcor on Thu Jan 16 2003.

//  2010-01-03 Makoto Yamashita.

#import "QSObjectView.h"
#import "QSObjectCell.h"
#import "QSLibrarian.h"
#import "QSInterfaceController.h"
#import "NSCursor_InformExtensions.h"
#import "QSObject_Drag.h"
#import "QSObject_Menus.h"
#import "QSObject_Pasteboard.h"
#import "QSAction.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

@implementation QSObjectView

+ (Class) cellClass { return [QSObjectCell class]; }

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{ 
	id object = [self objectValue];
	if  ([object respondsToSelector:@selector(dataDictionary)] && [[[object dataDictionary] allKeys] containsObject: sendType])
		return self;
	return nil;
}

- (void)viewDidMoveToWindow { }

- (void)awakeFromNib
{
	[self viewDidMoveToWindow];
	[self registerForDraggedTypes:standardPasteboardTypes];
	if (!controller && [self window]) controller = [[self window] delegate];
	draggedObject = nil;
	springTimer = nil;
    [self setDropMode:QSFullDropMode]; 	
}

- (QSInterfaceController *)controller
{
	if (!controller && [self window]) controller = [[self window] delegate];
	return controller;  
}

- (BOOL)acceptsFirstResponder {return NO;}

- (BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)setSpringTimer
{
	if (![springTimer isValid]) {
		[springTimer release];
		springTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(spring:) userInfo:nil repeats:NO] retain];
	}
	[springTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

- (void)invalidateSpringTimer {	[springTimer invalidate]; }

- (void)spring:(NSTimer *)timer
{
    NSPoint dummyPt;
	CGPoint currentMouseLocation2;
	dummyPt = [NSEvent mouseLocation];
    currentMouseLocation2.x = dummyPt.x;
    currentMouseLocation2.y = dummyPt.y;
	shouldSpring = YES;
	CGPostMouseEvent (currentMouseLocation2, NO, 1, NO);
}

- (BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)isOpaque { return NO; }

- (void)setImage:(NSImage *)image { }

- (void)mouseDown:(NSEvent *)theEvent
{
	BOOL isInside = YES;
	
	theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	
	switch ([theEvent type]) {
		case NSLeftMouseDragged:
			performingDrag = YES;
			// [super mouseDragged:theEvent];
			if ([self objectValue]) {
				NSRect reducedRect = [self frame];
				//reducedRect.size.width = MIN(NSWidth([self frame]), 52+MAX([[[self objectValue] name] sizeWithAttributes:nil] .width, [[[self objectValue] details] sizeWithAttributes:detailAttributes] .width) );
				NSImage *dragImage = [[[NSImage alloc] initWithSize:reducedRect.size] autorelease];
				[dragImage lockFocus];
				[[self cell] drawInteriorWithFrame:NSMakeRect(0, 0, [dragImage size] .width, [dragImage size] .height) inView:self];
				[dragImage unlockFocus];
				NSSize dragOffset = NSMakeSize(0.0, 0.0);
				
				
				if (!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ) {
					NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
					[[self objectValue] putOnPasteboard:pboard includeDataForTypes:nil];
					[self dragImage:[dragImage imageWithAlphaComponent:0.5] at:NSZeroPoint offset:dragOffset
							  event:theEvent pasteboard:pboard source:self slideBack:!([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask)];
				} else {
					NSPoint dragPosition;
					NSRect imageLocation;
					
					dragPosition = [self convertPoint:[theEvent locationInWindow]
											 fromView:nil];
					dragPosition.x -= 16;
					dragPosition.y -= 16;
					imageLocation.origin = dragPosition;
					imageLocation.size = NSMakeSize(32, 32);
					
					[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"silver"]
										  fromRect:imageLocation
											source:self
										 slideBack:YES
											 event:theEvent];  
				}				
			}
            break;
		case NSLeftMouseUp:
			[self mouseClicked:theEvent];
			break;
		default:
			break;
	}
	return;
}

- (void)mouseClicked:(NSEvent *)theEvent { }

- (BOOL)needsPanelToBecomeKey { return YES; }

- (void)paste:(id)sender
{
    [self readSelectionFromPasteboard:[NSPasteboard generalPasteboard]];
}

- (void)cut:(id)sender
{
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
	[self setObjectValue:nil];
}

- (void)copy:(id)sender
{
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
	QSObject *entry;
	entry = [QSObject objectWithPasteboard:pboard];
	[self setObjectValue:entry];
	return YES;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
	[[self objectValue] putOnPasteboard:pboard includeDataForTypes:types];
	return YES;
}


- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	QSLog(@"write to %@", [dropDestination path]);
	NSString *name = [[[self objectValue] name] stringByAppendingPathExtension:@"silver"];
	
	name = [name stringByReplacing:@"/" with:@"_"];
	name = [name stringByReplacing:@":" with:@"_"];
	NSString *file = [[dropDestination path] stringByAppendingPathComponent:name];
	
	//QSLog(file);
	[[(QSObject *)[self objectValue] dictionaryRepresentation] writeToFile:file atomically:YES];
	return [NSArray arrayWithObject:name];
}

- (NSSize) cellSize { return [[self cell] cellSize]; }

- (NSMenu *)menu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"ContextMenu"] autorelease];
	NSArray *actions = [[QSLibrarian sharedInstance] validActionsForDirectObject:[self objectValue] indirectObject:nil];
	NSMenuItem *item;
	for (QSAction *action in actions) {
		if (action) {
			NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];
			
			NSImage *icon = [action icon];
			[icon setSize:NSMakeSize(16, 16)];
			
			if ([componentArray count] >1) {
				NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
				if (!groupMenu) {
					groupMenu = [[[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
					if (icon) [groupMenu setImage:icon];
					[groupMenu setSubmenu: [[[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]]autorelease]];  
					[menu addItem:groupMenu];
				}       
				item = (NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(performMenuAction:) keyEquivalent:@""];
			} else {
				item = (NSMenuItem *)[menu addItemWithTitle:[action name] action:@selector(performMenuAction:) keyEquivalent:@""];
			}
			[item setTarget:self];
			[item setRepresentedObject:action];
			if (icon) [item setImage:icon];
		}
	}	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Remove" action:@selector(delete:) keyEquivalent:@""];
	
	return menu;	
}

- (void)performMenuAction:(NSMenuItem *)item
{
	[[item representedObject] performOnDirectObject:[self objectValue] indirectObject:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  [self setNeedsDisplay:YES];
}
//Standard Accessors


- (id)objectValue { return [[[[self cell] representedObject] retain] autorelease];  }

- (void)setObjectValue:(QSBasicObject *)newObject {
	[newObject loadIcon];
	[newObject becameSelected];

	[[self cell] setRepresentedObject:newObject];
  
	[self setNeedsDisplay:YES];
}


- (QSObjectDropMode) dropMode { return dropMode;  }
- (void)setDropMode:(QSObjectDropMode)aDropMode { dropMode = aDropMode; }

- (BOOL)acceptsDrags { return [self dropMode];  }

- (BOOL)initiatesDrags { return initiatesDrags;  }
- (void)setInitiatesDrags:(BOOL)flag { initiatesDrags = flag; }

- (QSObject *)draggedObject { return [[draggedObject retain] autorelease];  }

- (void)setDraggedObject:(QSObject *)newDraggedObject
{
	[draggedObject release];
	draggedObject = [newDraggedObject retain];
}

- (NSString *)searchString { return [[searchString retain] autorelease];  }

- (void)setSearchString:(NSString *)newSearchString
{
	if (newSearchString == searchString) return;
	[searchString release];
	searchString = [newSearchString retain];
}

- (NSUInteger) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) {
		if (isLocal) return NSDragOperationMove;
		return NSDragOperationNone;
	}    else {
		if (isLocal) return NSDragOperationMove;
		return NSDragOperationEvery;
	}
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	performingDrag = NO;
	QSLog(@"ended at %f %f %d", aPoint.x, aPoint.y, operation);
}

//Dragging

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
	if (![self acceptsDrags] || performingDrag || ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)])) {
		return NSDragOperationNone;
	}
	shouldSpring = NO;
	
	[self setDragAction:nil];
	draggingLocation = NSZeroPoint;
	lastDragMask = NSDragOperationNone;
	if ([[sender draggingSource] isKindOfClass:[self class]]) [self setDraggedObject:[[sender draggingSource] objectValue]];
	else [self setDraggedObject:[QSObject objectWithPasteboard:[sender draggingPasteboard]]];
	return [self draggingUpdated:sender];
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)]) {
        return NSDragOperationNone;
	}
	NSDragOperation operation = NSDragOperationNone;
	if (![self objectValue] || [self dropMode] == QSSelectDropMode) {
        operation = NSDragOperationGeneric;
	} else if ([[self objectValue] respondsToSelector:@selector(draggingEntered:withObject:)]) {
		operation = [[self objectValue] draggingEntered:sender withObject:[self draggedObject]];
	}
	
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	BOOL maskChanged = (sourceDragMask != lastDragMask);
	lastDragMask = sourceDragMask;
	
	if (operation == NSDragOperationGeneric) {
		NSCursor *cursor = [NSCursor informativeCursorWithString:@"Select"];
		[cursor set];
		[[self cell] setHighlighted:NO];
	} else if (fDEV && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
		NSCursor *cursor = [NSCursor informativeCursorWithString:@"Choose Action..."];
		[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		operation = NSDragOperationPrivate;
	} else {
		if (maskChanged) {
			NSString *action = [[self objectValue] actionForDragOperation:sourceDragMask withObject:draggedObject];
			NSCursor *cursor = [NSCursor informativeCursorWithString:[[QSExec actionForIdentifier:action] name]];
			[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		} 		
		if (operation != NSDragOperationNone) {[[self cell] setHighlighted:YES];}
	} 	
	return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self invalidateSpringTimer];
	[[self cell] setHighlighted:NO];
	[self setDraggedObject:nil];
	[NSCursor pop];
	[self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[self invalidateSpringTimer];
	QSLog(@"drag ended elsewhere");
}

- (void)drawRect:(NSRect)rect
{
    [[self cell] drawWithFrame:rectFromSize([self frame].size) inView:self];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSString *action = [[self objectValue] actionForDragOperation:sourceDragMask withObject:draggedObject];
	[self invalidateSpringTimer];
	if (shouldSpring) {
		[self performSelector:@selector(concludeSpringWithData:) withObject:[NSApp currentEvent] afterDelay:0.1];
		
		id winController = [[self window] windowController];
		if ([winController isKindOfClass:[QSInterfaceController class]] ) {
			[(QSInterfaceController *)winController invalidateHide];
		}
	} else if (fDEV && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
			[NSMenu popUpContextMenu:[[[self objectValue] resolvedObject] actionsMenu] withEvent:[NSApp currentEvent] forView:self]; 
	} else if (action && [self dropMode] != QSSelectDropMode) {
		QSAction *actionObject = [QSExec actionForIdentifier:action];
		[NSThread detachNewThreadSelector:@selector(concludeDragWithAction:) toTarget:self withObject:[actionObject retain]];
	} else if (sourceDragMask & NSDragOperationGeneric) {
		id winController = [[self window] windowController];
		if ([winController isKindOfClass:[QSInterfaceController class]] ) {
			[(QSInterfaceController *)winController invalidateHide];
			[[self window] makeKeyAndOrderFront:self];
		}
		[NSCursor pop];
		
		[[self window] selectNextKeyView:self];
		[self setObjectValue:[self draggedObject]];
		[self setDraggedObject:nil]; 	
	} else {
		return NO;
	}
	[[self cell] setHighlighted:NO];
	[[self window] makeFirstResponder:self];
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[self setDragAction:nil];
}

- (void)concludeDragWithAction:(QSAction *)actionObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[actionObject performOnDirectObject:[self draggedObject] indirectObject:[self objectValue]]; 	
	[pool release];
}

- (void)concludeSpringWithData:(id)object
{
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSEvent* mouseEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                             location:NSZeroPoint
                                        modifierFlags:0
                                            timestamp:0
                                         windowNumber:[[self window] windowNumber]
                                              context:nil
                                          eventNumber:0
                                           clickCount:0
                                             pressure:0];
	[[self draggedObject] putOnPasteboard:pboard includeDataForTypes:nil];
	[self dragImage:[[self draggedObject] icon]
                 at:[self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil]
             offset:NSZeroSize
              event:mouseEvent
         pasteboard:pboard source:self slideBack:NO];
}

@synthesize dragAction;

@end


