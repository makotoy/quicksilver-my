/*
 * Derived from Blacktree, Inc. codebase
 * 2010-01-16 Makoto Yamashita.
 */

#import <AppKit/AppKit.h>

@interface QSWebSearchController : NSWindowController {
    IBOutlet NSTextField *webSearchField;
    IBOutlet NSBox *searchBox;
    IBOutlet NSPopUpButton *searchPopUp;
    
    id webSearch;
}
+ (id)sharedInstance;

- (IBAction)submitWebSearch:(id)sender;
- (IBAction)showSearchView:(id)sender;

@property (retain) id webSearch;

- (void)searchURL:(NSURL *)searchURL;
- (NSString *)resolvedURL:(NSURL *)searchURL forString:(NSString *)string encoding:(CFStringEncoding)encoding;
- (void)openPOSTURL:(NSURL *)searchURL;
- (void)searchURL:(NSURL *)searchURL forString:(NSString *)string;
- (void)searchURL:(NSURL *)searchURL forString:(NSString *)string encoding:(CFStringEncoding)encoding;

@end
