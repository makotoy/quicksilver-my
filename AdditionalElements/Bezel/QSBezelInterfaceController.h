// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30
/* QSController */


#import <Cocoa/Cocoa.h>
// #import <QSInterface/QSResizingInterfaceController.h>


@interface QSBezelInterfaceController : QSResizingInterfaceController{
    NSRect standardRect;
	IBOutlet NSTextField *details;
}

- (NSRect)rectForState:(BOOL)expanded;
@end