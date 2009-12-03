// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30

#import <Foundation/Foundation.h>

// #import <QSCore/QSActionProvider.h>



@interface QSCLExecutableProvider : QSActionProvider {
	IBOutlet NSWindow *window;
}
- (QSObject *) showDirectoryInTerminal:(QSObject *)dObject;
- (void)performCommandInTerminal:(NSString *)command;
- (NSString *)runExecutable:(NSString *)path withArguments:(NSString *)arguments inTerminal:(BOOL)inTerminal;
- (NSString *)escapeString:(NSString *)string;
- (BOOL)sudoIfNeeded;
@end
