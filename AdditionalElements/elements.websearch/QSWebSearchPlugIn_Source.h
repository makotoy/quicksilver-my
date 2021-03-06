//
//  QSWebSearchPlugIn_Source.h
//  QSWebSearchPlugIn
//
//  Created by Nicholas Jitkoff on 11/24/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30


#import <QSCrucible/QSCrucible.h>

@interface QSWebSearchSource : QSObjectSource {
	IBOutlet NSTableView *searchTable;
	IBOutlet NSPopUpButtonCell *encodingCell;
    NSArray *searchSourceTabTopLevelObjects;
}

- (NSMenu *)encodingMenu;

@property(strong) NSArray *searchSourceTabTopLevelObjects;

@end
