/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */

#import "QSOutlineView.h"
#import "QSTableView.h"

@implementation QSOutlineView
- (id)_highlightColorForCell:(NSCell *)cell{
	if (highlightColor)
		return highlightColor;
	//return [super _highlightColorForCell:(NSCell *)cell];
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

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited{
    return NO;
}
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationMove;
    else return NSDragOperationCopy;
}
- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect{
    if ([[self delegate] respondsToSelector:@selector(outlineView:itemIsSeparator:)]
        && [[self delegate]outlineView:self itemIsSeparator:[self itemAtRow:rowIndex]]){
        [self drawSeparatorForRow:rowIndex clipRect:clipRect];
    }else{
        [super drawRow:rowIndex clipRect:clipRect];
    }
}

@end
