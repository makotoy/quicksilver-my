/* QSPreferencesController */

#import <Cocoa/Cocoa.h>

#define kQSPreferencesSplitWidth @"QSPreferencesSplitWidth"

@interface QSPreferencesController : NSWindowController
{
    IBOutlet NSTextField *descView;
    IBOutlet NSTableView *externalPrefsTable;
    IBOutlet NSButton *helpButton;
    IBOutlet NSImageView *iconView;
    IBOutlet QSTableView *internalPrefsTable;
    IBOutlet NSView *loadingView;
    IBOutlet NSTextField *nameView;
    IBOutlet NSProgressIndicator *loadingProgress;
    IBOutlet NSArrayController *moduleController;
	
	IBOutlet NSView *toolbarTitleView;
	
    IBOutlet NSBox *mainBox;
	
    IBOutlet NSBox *prefsBox;

    IBOutlet NSBox *settingsPrefsBox;
    IBOutlet NSBox *toolbarPrefsBox;
	
	IBOutlet NSSplitView *settingsSplitView;
	IBOutlet NSView *sidebarView;
	IBOutlet NSView *settingsView;
	IBOutlet NSBox *fillerBox;
	
	IBOutlet NSSegmentedControl *historyView;
	
	NSToolbar *toolbar;
	NSMutableDictionary *currentPaneInfo;	
	QSPreferencePane *currentPane;
	
	NSMutableDictionary *modulesByID;
    NSMutableArray *modules;
	
	BOOL relaunchRequested;
	
	BOOL showingSettings;
	BOOL reloading;
}
+ (QSPreferencePane *)showPaneWithIdentifier:(NSString *)identifier;
+ (void)showPrefs;

- (IBAction)back:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)selectModule:(id)sender;

@property (retain) NSMutableArray* modules;
@property (assign) BOOL relaunchRequested;
@property (retain) QSPreferencePane *currentPane;
@property (retain) NSMutableDictionary *currentPaneInfo;

- (void)setPaneForInfo:(NSMutableDictionary *)info switchSection:(BOOL)switchSection;
- (void)preventEmptySelection;
- (void)selectPaneWithIdentifier:(NSString *)identifier;
- (QSPreferencePane *)showPaneWithIdentifier:(NSString *)identifier;

@end
