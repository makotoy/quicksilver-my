/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */

#import <AppKit/AppKit.h>


@interface NSObject (QSTableViewSeparator)
- (BOOL)tableView:(NSTableView *)aTableView shouldDrawRow:(int)rowIndex inClipRect:(NSRect)clipRect;
- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex;
@end
@interface NSObject (QSTableViewMenu)
- (NSMenu *)tableView:(NSTableView*)tableView menuForTableColumn:(NSTableColumn *)column row:(int)row;
@end
@interface NSObject (QSTableDropEnded)
- (void)tableView:(NSTableView *)tv dropEndedWithOperation:(NSDragOperation)operation;
@end

@interface NSTableView (Separator)
- (void)drawSeparatorForRow:(int)rowIndex clipRect:(NSRect)clipRect;
@end

@interface QSTableView : NSTableView {
    int drawingRowIsSelected;
	NSColor *highlightColor;
	id draggingDelegate;
	BOOL opaque;
	BOOL drawsBackground;
}
@property (copy) NSColor* highlightColor;
@property (retain) id draggingDelegate;
- (void)setOpaque:(BOOL)flag;
@end

@interface NSTableView (MenuExtensions) 

-(NSMenu*)menuForEvent:(NSEvent*)evt;
@end