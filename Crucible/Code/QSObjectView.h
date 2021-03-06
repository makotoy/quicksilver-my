/* Derived from Blacktree, Inc. codebase
 * 2010-01-03 Makoto Yamashita.
 */

#import <AppKit/AppKit.h>

@class QSInterfaceController;

typedef enum {
	QSRejectDropMode = 0, // Ignores Drops
	QSSelectDropMode = 1, // Selects Dropped objects
	QSActionDropMode = 2, // Can perform actions, but not change selection
	QSFullDropMode = 3 // Actions as well as change selection
} QSObjectDropMode;	

@interface QSObjectView : NSControl {
    NSString *searchString;
    QSInterfaceController *controller;
    BOOL dragImageDraw;
    BOOL dragAcceptDraw;
    
    BOOL performingDrag;
    NSDictionary *nameAttributes;
    NSDictionary *detailAttributes,*liteDetailAttributes;

    NSTimer *iconLoadTimer;    
    
	QSObjectDropMode dropMode;
	
    QSObject *draggedObject;
    NSString *dragAction;
    NSDragOperation lastDragMask;
	
    BOOL initiatesDrags;
    NSPoint draggingLocation;
    NSTimer *springTimer;
    BOOL shouldSpring;
	NSEvent *springDrag;
	NSImage *draggedImage;
}
- (QSObject *)draggedObject;
- (void)setDraggedObject:(QSObject *)newDraggedObject;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)newSearchString;

- (id)objectValue;
- (void)setObjectValue:(QSBasicObject *)newObject;

- (QSObjectDropMode)dropMode;
- (void)setDropMode:(QSObjectDropMode)aDropMode;

- (BOOL)acceptsDrags;

- (BOOL)initiatesDrags;
- (void)setInitiatesDrags:(BOOL)flag;

@property (copy) NSString* dragAction;

- (QSInterfaceController *)controller;
- (NSSize)cellSize;
- (void)mouseClicked:(NSEvent *)theEvent;
@end
