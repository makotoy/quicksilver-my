//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-15

#import <Foundation/Foundation.h>
#import <QSCrucible/QSCrucible.h>

@interface QSABContactActions : QSObjectSource
@end

@interface QSAddressBookObjectSource : QSObjectSource {
	NSTimeInterval addressBookModDate;
	NSMutableDictionary *contactDictionary;
	
	IBOutlet NSPopUpButton *groupList;
	IBOutlet NSPopUpButton *distributionList;
    NSArray *addrViewTopLevelObjs;
}
@property (retain) NSPopUpButton *groupList;
@property (retain) NSPopUpButton *distributionList;
@property (strong) NSArray *addrViewTopLevelObjs;
@end

@interface QSABMailRecentsObjectSource : QSObjectSource
@end

