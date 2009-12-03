// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30

#import <Foundation/Foundation.h>

@interface QSAppleMailMediator : NSObject {
    NSAppleScript *mailScript;
}
- (NSAppleScript *)mailScript;
@end
