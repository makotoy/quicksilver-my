

#import <Foundation/Foundation.h>
//#import <QSCore/QSCore.h>


@interface QSABContactActions : QSObjectSource
@end
@interface QSAddressBookObjectSource : QSObjectSource{
	NSTimeInterval addressBookModDate;
	NSMutableDictionary *contactDictionary;
	
	IBOutlet NSPopUpButton *groupList;
	IBOutlet NSPopUpButton *distributionList;
}
@property (retain) NSPopUpButton *groupList;
@property (retain) NSPopUpButton *distributionList;

@end

@interface QSABMailRecentsObjectSource : QSObjectSource
@end

