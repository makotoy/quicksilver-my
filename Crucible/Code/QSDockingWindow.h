/*
 *  Derived from Blacktree, Inc. codebase
 *  2010-01-16 Makoto Yamashita
 */


#import "QSWindow.h"
#import "QSTrackingWindow.h"

@interface QSDockingWindow : QSBorderlessWindow <NSWindowDelegate> {

    NSTrackingRectTag trackingRect;
   // BOOL hidden;
    
    NSTimer *hideTimer;
	NSTimeInterval lastTime;
    BOOL moving;
	BOOL locked;
    
  BOOL allowKey;
    NSString *autosaveName;
	QSTrackingWindow *trackingWindow;
}

- (void)updateTrackingRect:(id)sender;
- (IBAction) hide:(id)sender;
- (IBAction) show:(id)sender;
- (IBAction) toggle:(id)sender;
- (BOOL) canFade;
- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)newAutosaveName;
- (void)resignKeyWindowNow;
- (QSTrackingWindow *)trackingWindow;
- (IBAction)orderFrontHidden:(id)sender;
- (void)saveFrame;
-(BOOL)hidden;
- (IBAction) hideOrOrderOut:(id)sender;
- (IBAction) showKeyless:(id)sender;
@end
