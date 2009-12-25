//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import <Cocoa/Cocoa.h>

extern NSString * QSApplicationDidFinishLaunchingNotification;
extern BOOL QSApplicationCompletedLaunch;

@interface QSApp : NSApplication {
    int featureLevel;
    BOOL isUIElement;
    BOOL shouldRelaunch;
	IBOutlet NSMenu *hiddenMenu;
	NSMutableArray *eventDelegates;
    NSResponder* globalKeyEquivalentTarget;
}

- (int) featureLevel;

- (BOOL) isUIElement;
- (BOOL) setShouldBeUIElement:(BOOL)hidden; //Returns YES if successful
- (void) forwardWindowlessRightClick:(NSEvent *) theEvent;
- (BOOL) completedLaunch;
- (BOOL) isPrerelease;
- (void) addEventDelegate:(id)eDelegate;
- (void) removeEventDelegate:(id)eDelegate;
@property (retain) NSResponder* globalKeyEquivalentTarget;

@end
