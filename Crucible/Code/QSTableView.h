/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */

#import <AppKit/AppKit.h>


@protocol QSTableViewSeparatorDelegate
- (BOOL)tableView:(NSTableView *)aTableView shouldDrawRow:(NSInteger)rowIndex inClipRect:(NSRect)clipRect;
- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(NSInteger)rowIndex;
@end

@protocol QSTableViewMenu
- (NSMenu *)tableView:(NSTableView*)tableView menuForTableColumn:(NSTableColumn *)column row:(NSInteger)row;
@end

@protocol QSTableDropEnded
- (void)tableView:(NSTableView *)tv dropEndedWithOperation:(NSDragOperation)operation;
@end

@interface NSTableView (Separator)
- (void)drawSeparatorForRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect;
@end


@interface NSTableView (MenuExtensions)
-(NSMenu*)menuForEvent:(NSEvent*)evt;
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
@property (assign) BOOL opaque;
@property (assign) BOOL drawsBackground;

@end
