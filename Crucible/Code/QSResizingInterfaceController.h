/*
 * Derived from Blacktree, Inc. codebase
 * 2010-01-09 Makoto Yamashita
 */

#import <Foundation/Foundation.h>

#import "QSInterfaceController.h"

@interface QSResizingInterfaceController : QSInterfaceController {
    BOOL expanded;
    NSTimer *expandTimer;
}
- (void)resetAdjustTimer;
- (void)expandWindow:(id)sender;
- (void)contractWindow:(id)sender;

- (void)firstResponderChanged:(NSResponder *)aResponder;

- (BOOL)expanded;
- (void)adjustWindow:(id)sender;
@end
