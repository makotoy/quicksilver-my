/* QSFinderProxy.h
 * QuickSilver Gamma project
 * Derived from Blacktree codebase
 * Makoto Yamashita 2015
 */

#import "QSFSBrowserMediator.h"

@interface QSFinderProxy : NSObject <QSFSBrowserMediator> {
    NSAppleScript *finderScript;
}
+ (id)sharedInstance;

- (BOOL)revealFile:(NSString *)file;
- (NSArray *)selection;
- (NSArray *)copyFiles:(NSArray *)files toFolder:(NSString *)destination;
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination;
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination shouldCopy:(BOOL)copy;    
- (NSArray *)deleteFiles:(NSArray *)files;

- (NSAppleScript *)finderScript;
- (void)setFinderScript:(NSAppleScript *)aFinderScript;

@property (strong) NSAppleScript *finderScript;
@end
