/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */

#import "QSTableView.h"

#import "NSColor_QSModifications.h"


@interface NSTableView (SingleRowDisplay)
- (void)_setNeedsDisplayInRow:(int)fp8;
@end 

@implementation QSTableView

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint
{
	return YES;	
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	[draggingDelegate draggingEntered:sender];
	return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	[draggingDelegate draggingUpdated:sender];
	return [super draggingUpdated:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[draggingDelegate draggingExited:sender];
	[super draggingExited:sender];
	return;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationEvery;
}

@synthesize opaque;

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
    if ([[self delegate] respondsToSelector:@selector(tableView:rowIsSeparator:)]
        && [(id<QSTableViewSeparatorDelegate>)[self delegate] tableView:self rowIsSeparator:rowIndex]) {
        if (![[self delegate] respondsToSelector:@selector(tableView:shouldDrawRow:inClipRect:)]
			|| [(id<QSTableViewSeparatorDelegate>)[self delegate] tableView:self shouldDrawRow:rowIndex inClipRect:clipRect]){
			[self drawSeparatorForRow:rowIndex clipRect:clipRect];
		}
	} else {
		[super drawRow:rowIndex clipRect:clipRect];
	}
}


- (id)initWithFrame:(NSRect)rect
{
	self = [super initWithFrame:rect];
	if (self != nil) {
		opaque=YES;
		drawsBackground=YES;
	}
	return self;
}

- (void)awakeFromNib
{
	opaque=YES;
	drawsBackground=YES;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if (!drawsBackground) return;

    if ([self backgroundColor]) {
		[[self backgroundColor]set];
		NSRectFillUsingOperation(clipRect,NSCompositeCopy);
	} else {
		[super drawBackgroundInClipRect:clipRect];
	}
}

@synthesize drawsBackground;

- (void)setHighlightColorForBackgroundColor:(NSColor *)color
{
	[self setHighlightColor:
     [[self backgroundColor]blendedColorWithFraction:0.25
                                             ofColor:[[self backgroundColor] readableTextColor]]];
}

- (id)_highlightColorForCell:(NSCell *)cell
{
	if (highlightColor) return highlightColor;

	return [NSColor alternateSelectedControlColor];
}

@synthesize highlightColor;
- (void)setHighlightColor:(NSColor *)aHighlightColor
{
    if (highlightColor != aHighlightColor) {
        [highlightColor release];
        highlightColor = [aHighlightColor copy];
		
		[self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)color
{
	[super setBackgroundColor:color];
	[self setNeedsDisplay:YES];
}

- (void)redisplayRows:(NSIndexSet *)indexes
{
    if ([self respondsToSelector:@selector(_setNeedsDisplayInRow:)]) {
        [self _setNeedsDisplayInRow:[indexes firstIndex]];
	// ***warning   * incomplete
    } else {
        [self setNeedsDisplay:YES];
    }
}

-(NSMenu*)menuForEvent:(NSEvent*)evt
{
	//  QSLog (@"event");
    NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL]; 
    int column = [self columnAtPoint:point]; 
    int row = [self rowAtPoint:point]; 
    if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] ) 
        return [(id<QSTableViewMenu>)[self delegate] tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row]; 
    return [super menuForEvent:evt]; 
} 

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    [super draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation]; 
	
    if ([[self dataSource] respondsToSelector:@selector(tableView:dropEndedWithOperation:)] ) {
        [(id<QSTableDropEnded>)[self dataSource] tableView:self dropEndedWithOperation:operation]; 
    }
}

@synthesize draggingDelegate;

@end

@implementation NSTableView (MenuExtensions) 

-(NSMenu*)menuForEvent:(NSEvent*)evt
{ 
    NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL]; 
    int column = [self columnAtPoint:point]; 
    int row = [self rowAtPoint:point]; 
    if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] ) 
        return [(id<QSTableViewMenu>)[self delegate] tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row]; 
    return [super menuForEvent:evt]; 
} 
@end 
