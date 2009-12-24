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

- (NSSize) maxIconSize;
- (IBAction)hideWindows:(id)sender;
- (void)updateActionsNow;
- (void)hideMainWindow:(id)sender;
- (void)showMainWindow:(id)sender;

- (IBAction)activate:(id)sender;
- (void)updateActions;

- (void)shortCircuit:(id)sender;
- (void)activate:(id)sender;
- (void)updateViewLocations;
- (void)activateInTextMode:(id)sender;
- (void)updateIndirectObjects;
- (IBAction)showTasks:(id)sender;
- (void)invalidateHide;

- (NSProgressIndicator *)progressIndicator;
- (QSCommand *)currentCommand;
- (IBAction)executeCommand:(id)sender;
- (void)executeCommandThreaded;
- (void)executePartialCommand:(NSArray *)array;

- (void)setCommand:(QSCommand *)command;
- (void)setCommandWithArray:(NSArray *)array;

- (void)activate:(id)sender;
- (void)selectObject:(QSBasicObject *)object;
- (void)searchObjectChanged:(NSNotification*)notif;
- (void)showIndirectSelector:(id)sender;

- (void)hideIndirectSelector:(id)sender;

@property (readonly) QSSearchObjectView* dSelector;
@property (readonly) QSSearchObjectView* aSelector;
@property (readonly) QSSearchObjectView* iSelector;
@property (readonly) QSMenuButton* menuButton;

- (void)fireActionUpdateTimer;
- (void)searchArray:(NSMutableArray *)array;
- (void)hideMainWindowFromExecution:(id)sender;
- (void)hideMainWindowFromCancel:(id)sender;
- (void)hideMainWindowFromFade:(id)sender; 	
- (void)hideMainWindowWithEffect:(id)effect;
- (void)setClearTimer;
- (void)executePartialCommand:(NSArray *)array;
- (void)actionActivate:(id)sender;
- (void)showArray:(NSMutableArray *)array;
- (QSBasicObject *)selection;
- (void)encapsulateCommand;
- (void)encapsulateCommand:(id)sender;
- (void)executeCommandAndContinue:(id)sender;
- (IBAction)executeCommand:(id)sender;
- (void)updateControl:(QSSearchObjectView *)control withArray:(NSArray *)array;
- (NSArray *)rankedActions;
@end
