// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30


#import <Foundation/Foundation.h>
typedef enum {
	QSPasteboardHistoryMode = 1, // Global pasteboard history
	QSPasteboardStoreMode = 2, // numbered storage bins
	QSPasteboardQueueMode = 3, // FIFO Cycling
	QSPasteboardStackMode = 4 // LIFO Cycling
} QSPasteboardMode;

@class QSObjectView;
@class QSTableView;

#define kCapturePasteboardHistory @"Capture Pasteboard History"
#define kCapturePasteboardHistoryCount @"Capture Pasteboard History Count"


@interface QSPasteboardController : NSWindowController {
    NSMutableArray *pasteboardHistoryArray;
    NSMutableArray *pasteboardStoreArray;
    NSMutableArray *pasteboardCacheArray;
	
	NSMutableArray *currentArray;
	
    IBOutlet NSMatrix *pasteboardHistoryMatrix;
    IBOutlet QSTableView *pasteboardHistoryTable;
    IBOutlet QSObjectView *pasteboardItemView;
    IBOutlet NSWindow *pasteboardProxyWindow;
    
    IBOutlet NSButton *clearButton;
    IBOutlet NSTextField *titleField;
    IBOutlet NSMenu *pasteboardMenu;
    QSObjectView *pasteboardObjectView;
    BOOL supressCapture;
    BOOL adjustRowsToFit;
	BOOL cacheIsReversed;
	int mode;
}

- (id)selectedObject;
- (IBAction)clearHistory:(id)sender;
- (IBAction)setMode:(id)sender;

- (IBAction)qsPaste:(id)sender;

- (IBAction)toggleAdjustRows:(id)sender;

- (IBAction)showPreferences:(id)sender;

- (IBAction)hideWindow:(id)sender;

- (void)switchToMode:(int)newMode;
- (void)adjustRowHeight;
- (void)setCacheIsReversed:(BOOL)reverse;
+ (id)sharedInstance;

@end
