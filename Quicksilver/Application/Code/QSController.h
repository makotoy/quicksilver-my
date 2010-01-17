/* Derived from Blacktree, Inc. codebase
 * Makoto Yamashita, 2009-12-28
 */

/* QSController */

@class QSObjectView;
@class QSActionMatrix;

@class QSWindow;
@class QSMenuWindow;

@class QSObject;

@class QSInterfaceController;
@class QSCatalogController;

// This is referenced from subprojects, so the value cannot be externed
#define QSWindowsShouldHideNotification @"QSWindowsShouldHide"

@interface QSController : NSWindowController {
    QSInterfaceController *interfaceController;
    QSCatalogController *catalogController;
    NSWindowController *aboutWindowController;
    NSWindowController *quitWindowController;
    NSWindowController *triggerEditor;
    
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *preferencesMenu;
    IBOutlet NSWindow *aboutWindow;
    IBOutlet NSTextField *versionField;
    
    NSConnection *controllerConnection; 
    NSConnection *contextConnection;
    NSWindow *splashWindow;
	
    BOOL newVersion;
    BOOL runningSetupAssistant;
    
    NSColor *iconColor;
	NSImage *activatedImage;
	NSImage *runningImage;
	NSConnection *dropletConnection;
	
	NSObject *dropletProxy;
}

- (NSProgressIndicator *)progressIndicator;

- (void)openURL:(NSURL *)url;
- (void)showSplash:(id)sender;

- (void)recompositeIconImages;

- (NSImage *)daedalusImage;

- (NSMenu *)statusMenu;
- (NSMenu *)statusMenuWithQuit;

- (void) activateInterface:(id)sender;
- (void)activateDebugMenu;

- (void) checkForFirstRun;

- (void) receiveObject:(QSObject *)object;

- (void)setupAssistantCompleted:(id)sender;

@property (retain) QSInterfaceController* interfaceController;
@property (copy) NSColor* iconColor;
@property (retain) NSImage* activatedImage;
@property (copy) NSImage* runningImage;
@property (retain) NSObject* dropletProxy;

@end

@interface QSController (IBActions)
- (IBAction) showAgreement:(id)sender;
- (IBAction) runSetupAssistant:(id)sender;
- (IBAction) reportABug:(id)sender;
- (IBAction) unsureQuit:(id)sender;
- (IBAction) rescanItems:sender;
- (IBAction) forceRescanItems:sender;
- (IBAction) showElementsViewer:(id)sender;
- (IBAction) runSetupAssistant:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showGuide:(id)sender;
- (IBAction) showSettings:(id)sender;
- (IBAction) showCatalog:(id)sender;
- (IBAction) showTriggers:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) showForums:(id)sender;
- (IBAction) showTaskViewer:(id)sender;
- (IBAction) showReleaseNotes:(id)sender;
- (IBAction) showHelp:(id)sender;
- (IBAction) openIRCChannel:(id)sender;
- (IBAction) donate:(id)sender;
- (IBAction) getMorePlugIns:(id)sender;
@end

@interface QSController (ErrorHandling)
- (void)registerForErrors;
@end

@interface QSController (QSNotifications)
- (void)activated:(NSNotification *)aNotification;
- (void)deactivated:(NSNotification *)aNotification;
@end

extern QSController *QSCon;