//
//  QSWebSearchPlugIn_Source.h
//  QSWebSearchPlugIn
//
//  Created by Nicholas Jitkoff on 11/24/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30


// #import "QSWebSearchPlugIn_Source.h"

@interface QSWebSearchSource : QSObjectSource {
	IBOutlet NSTableView *searchTable;
	IBOutlet NSPopUpButtonCell *encodingCell;
}

- (NSMenu *)encodingMenu;

@end

