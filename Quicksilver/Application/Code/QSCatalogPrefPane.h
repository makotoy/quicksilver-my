/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-25
 */
#import <Cocoa/Cocoa.h>

#define QSCodedCatalogEntryPasteboardType @"QSCatalogEntry"

@interface QSCatalogPrefPane : QSPreferencePane {
    IBOutlet QSTableView *catalogSetsTable;
	
    IBOutlet NSArrayController *catalogSetsController;

    IBOutlet NSTreeController *treeController;
    IBOutlet NSArrayController *contentsController;
    IBOutlet NSTabView *itemOptionsTabView;
    IBOutlet NSTabViewItem *itemTabView;
    IBOutlet NSDrawer *itemContentsDrawer;
    IBOutlet NSSplitView *catalogSplitView;
    
    //Item
    IBOutlet NSPopUpButton *sourcePopUp;
    IBOutlet QSOutlineView *itemTable;
    IBOutlet QSTableView *itemContentsTable;
    IBOutlet NSTextField *itemNameField;
    IBOutlet NSImageView *itemIconField;
    IBOutlet NSButton *itemAddButton;
    
    IBOutlet NSButton *itemAddGroupButton;
    IBOutlet NSButton *itemDeleteButton;
    IBOutlet NSBox *itemOptionsView;
    
    IBOutlet NSPopUpButton *itemViewSwitcher;
    
    QSCatalogEntry *currentItem;
    NSMutableDictionary *currentItemSettings;
    IBOutlet NSButton *currentItemDeleteButton;
    IBOutlet NSButton *currentItemAddButton;
    NSArray *currentItemContents;
    
    BOOL currentItemHasSettings;
    
    IBOutlet NSView *messageView;
    IBOutlet NSTextField *messageTextField;
    
    QSLibrarian *librarian;
    NSUserDefaults *defaults;
    NSDictionary *presetsDictionary;
    
    NSArray *draggedEntries;
    NSArray *draggedIndexPaths;
	
	NSMutableDictionary *iconCache;
	
    IBOutlet NSView *sidebar;
}

- (IBAction) addSource:(id)sender;
- (IBAction) saveItem:(id)sender;
- (IBAction)copyPreset:(id)sender;
- (IBAction)restoreDefaultCatalog:(id)sender;
- (IBAction)setValueForSenderForCatalogEntry:(id)sender;
- (IBAction)applySettings:(id)sender;
- (IBAction)rescanCurrentItem:(id)sender;

- (void)populateCatalogEntryFields;

- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item;

- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(NSInteger)rowIndex;

- (void) updateCurrentItemContents;

- (void)updateEntrySelection;

@property (retain) NSArray* currentItemContents;
@property (retain) QSCatalogEntry* currentItem;

+ (void) addEntryForCatFile:(NSString *)path;
+ (void) showEntryInCatalog:(QSCatalogEntry *)entry;

- (void) selectEntry:(QSCatalogEntry *)entry;
- (QSCatalogEntry *)entryForCatFile:(NSString *)path;
@end
