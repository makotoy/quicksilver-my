/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-20
 */


#import <Cocoa/Cocoa.h>

@interface QSInterfaceController : NSWindowController {
    IBOutlet QSSearchObjectView *dSelector;
    IBOutlet QSSearchObjectView *aSelector;
    IBOutlet QSSearchObjectView *iSelector;

    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet id commandView;
    IBOutlet QSMenuButton *menuButton;
    NSTimer *hideTimer;
    NSTimer *actionsUpdateTimer;
    NSTimer *clearTimer;
    BOOL hidingWindow;
    BOOL preview;
}

@property (assign) BOOL preview;
@property (readonly) QSSearchObjectView* dSelector;
@property (readonly) QSSearchObjectView* aSelector;
@property (readonly) QSSearchObjectView* iSelector;
@property (readonly) QSMenuButton* menuButton;

- (NSSize) maxIconSize;
- (NSProgressIndicator *)progressIndicator;
- (QSCommand *)currentCommand;
- (QSBasicObject *)selection;
- (void)setCommand:(QSCommand *)command;
- (void)setCommandWithArray:(NSArray *)array;

- (void)updateActionsNow;
- (void)updateViewLocations;
- (void)updateActions;
- (void)updateIndirectObjects;
- (void)updateControl:(QSSearchObjectView *)control withArray:(NSArray *)array;

- (IBAction)hideWindows:(id)sender;
- (void)hideMainWindow:(id)sender;
- (void)hideMainWindowFromExecution:(id)sender;
- (void)hideMainWindowFromCancel:(id)sender;
- (void)hideMainWindowFromFade:(id)sender; 	
- (void)hideMainWindowWithEffect:(id)effect;

- (void)showMainWindow:(id)sender;
- (void)invalidateHide;

- (IBAction)activate:(id)sender;
- (void)activateInTextMode:(id)sender;
- (void)actionActivate:(id)sender;

- (void)shortCircuit:(id)sender;

- (IBAction)showTasks:(id)sender;

- (IBAction)executeCommand:(id)sender;
- (void)executeCommandThreaded;
- (void)executePartialCommand:(NSArray *)array;
- (void)executePartialCommand:(NSArray *)array;
- (void)executeCommandAndContinue:(id)sender;

- (void)encapsulateCommand;
- (void)encapsulateCommand:(id)sender;

- (void)selectObject:(QSBasicObject *)object;
- (void)searchObjectChanged:(NSNotification*)notif;
- (void)showIndirectSelector:(id)sender;

- (void)hideIndirectSelector:(id)sender;

- (IBAction)customize:(id)sender; // subclasses should override this method

- (void)fireActionUpdateTimer;
- (void)searchArray:(NSMutableArray *)array;
- (void)setClearTimer;
- (void)showArray:(NSMutableArray *)array;
- (NSArray *)rankedActions;
@end
