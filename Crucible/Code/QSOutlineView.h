/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */

#import <Foundation/Foundation.h>

@protocol OutlineViewSeparator
- (BOOL)outlineView:(NSTableView *)aTableView itemIsSeparator:(id)item;
@end

@interface QSOutlineView : NSOutlineView {
	NSColor *highlightColor;
}
@property (copy) NSColor* highlightColor;

@end
