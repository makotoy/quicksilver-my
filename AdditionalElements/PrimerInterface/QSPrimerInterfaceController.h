/*
 * Derived from Blacktree codebase.
 * 2009-12-08 Makoto Yamashita.
 */

/* QSController */

#import <Cocoa/Cocoa.h>

@interface QSPrimerInterfaceController : QSResizingInterfaceController {
	IBOutlet NSButton *executeButton;
	
	IBOutlet NSTextField *dSearchText;
	IBOutlet NSTextField *aSearchText;
	IBOutlet NSTextField *iSearchText;
	
	IBOutlet NSTextField *dSearchCount;
	IBOutlet NSTextField *aSearchCount;
	IBOutlet NSTextField *iSearchCount;
	
	IBOutlet NSButton *dSearchResultDisclosure;
	IBOutlet NSButton *aSearchResultDisclosure;
	IBOutlet NSButton *iSearchResultDisclosure;
	
	IBOutlet NSView *indirectView;
}
@end