//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-15

#import "QSObject_ContactHandling.h"
#import "ABPerson_Display.h"
#import "QSABSource.h"

@implementation QSAddressBookObjectSource
- (id)init
{
    self = [super init];
	if (self) {
		contactDictionary = [[NSMutableDictionary alloc]init];
		addressBookModDate = [NSDate timeIntervalSinceReferenceDate];
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addressBookChanged:)
                                                     name:kABDatabaseChangedExternallyNotification
                                                   object:nil];
	}
	return self;
}

- (BOOL)usesGlobalSettings {return YES;}

- (NSView *)settingsView
{
    if (![super settingsView]) {
        [NSBundle loadNibNamed:@"QSAddressBookObjectSource" owner:self];
	}
    return [super settingsView];
}

@synthesize groupList;
@synthesize distributionList;

- (NSArray *)contactGroups
{
	NSMutableArray *groups = [NSMutableArray arrayWithCapacity:0];
	[groups addObjectsFromArray:[[[ABAddressBook sharedAddressBook]
                                     groups]
                                    valueForKey:kABGroupNameProperty]];
	[groups removeObject:@"Me"];
	[groups sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[groups insertObject:@"All Contacts" atIndex:0];

	return groups;
}

- (NSArray *)contactDistributions
{
	NSMutableArray *groups = [NSMutableArray arrayWithCapacity:0];
	[groups addObjectsFromArray:[[[ABAddressBook sharedAddressBook]
                                  groups]
                                 valueForKey:kABGroupNameProperty]];
	[groups removeObject:@"Me"];
	[groups sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[groups insertObject:@"None" atIndex:0];
    
	return groups;
}
/*
- (void)refreshGroupList {
	[groupList removeAllItems];
	[distributionList removeAllItems];
	

	NSLog(@"group %@", groups);
	[groupList addItemWithTitle:@"All Contacts"];
	[[groupList menu]addItem:[NSMenuItem separatorItem]];
	[groupList addItemsWithTitles:groups];
	
	[distributionList addItemWithTitle:@"Default Emails"];
	[[distributionList menu]addItem:[NSMenuItem separatorItem]];
	[distributionList addItemsWithTitles:groups];
}
*/
- (NSImage *)iconForEntry:(NSDictionary *)theEntry
{
    return [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Address Book.app"];
}

- (NSArray *)contactWebPages
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
	ABAddressBook *book = [ABAddressBook sharedAddressBook];
	NSArray *people = [book people];
	for (id thePerson in people) {
		NSString *homePage = [thePerson valueForProperty:kABHomePageProperty];
		if (!homePage) continue;
		
		NSString *name = @"(no name)";
		NSString *namePiece;		
		BOOL showAsCompany = [[thePerson valueForProperty:kABPersonFlags] intValue] & kABShowAsMask & kABShowAsCompany;
		if (showAsCompany) {
			if ((namePiece = [thePerson valueForProperty:kABOrganizationProperty])) {
				name = namePiece;
            }
		} else {
			NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:3];
			if ((namePiece = [thePerson valueForProperty:kABFirstNameProperty]))
				[nameArray addObject:namePiece];
			if ((namePiece = [thePerson valueForProperty:kABMiddleNameProperty]))
				[nameArray addObject:namePiece];
			if ((namePiece = [thePerson valueForProperty:kABLastNameProperty]))
				[nameArray addObject:namePiece];
			if ([nameArray count])name = [nameArray componentsJoinedByString:@" "];
		}
		QSObject *object = [QSObject URLObjectWithURL:homePage
                                          title:name];
		[array addObject:object];
	}
	NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName"
                                                                     ascending:YES];
    [array sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
	return array;
}

- (void) addressBookChanged:(NSNotification *)notif
{
	NSArray *inserted = [[notif userInfo] objectForKey:kABInsertedRecords];
	NSArray *updated = [[notif userInfo] objectForKey:kABUpdatedRecords];
	NSArray *deleted = [[notif userInfo] objectForKey:kABDeletedRecords];
	if ([updated count]) {
		NSArray* updates = [contactDictionary objectsForKeys:updated notFoundMarker:[NSNull null]];

		for (QSObject *person in updates) {
			if ([person isKindOfClass:[QSObject class]])
				[person loadContactInfo];
		}		
	} 
	if ([inserted count]) {
		ABAddressBook *book = [ABAddressBook sharedAddressBook];
		ABSearchElement *groupSearch = [ABGroup searchElementForProperty:kABGroupNameProperty
                                                                   label:nil
                                                                     key:nil
                                                                   value:@"Quicksilver"
                                                              comparison:kABPrefixMatchCaseInsensitive];
		ABGroup *qsGroup = [[book recordsMatchingSearchElement:groupSearch] lastObject];
		
		for (NSString* thisID in inserted) {
			ABPerson *person = (ABPerson *)[book recordForUniqueId:thisID];
			
			if ([[qsGroup members]containsObject:person]) {
                QSObject *thisPerson = [QSObject objectWithPerson:person];
				[contactDictionary setObject:thisPerson forKey:thisID];
			}
		}
		
	} 
	if ([deleted count]) {
		[contactDictionary removeObjectsForKeys:deleted];
	}
	[self invalidateSelf];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	return ([indexDate timeIntervalSinceReferenceDate] > addressBookModDate);
}

- (void)invalidateSelf
{
	addressBookModDate = [NSDate timeIntervalSinceReferenceDate];
	[super invalidateSelf];
}


- (BOOL)scanInMainThread { return YES;}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
  NSArray *abchildren = [self objectsForEntry:nil];
  [object setChildren:abchildren];
  return YES;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    NSArray *people = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *group = [defaults stringForKey:@"QSABGroupLimit"];
    if (!group) group = @"Quicksilver";
    ABSearchElement *groupSearch = [ABGroup searchElementForProperty:kABGroupNameProperty
                                                               label:nil
                                                                 key:nil
                                                               value:group
                                                          comparison:kABPrefixMatchCaseInsensitive];
    ABGroup *qsGroup = [[book recordsMatchingSearchElement:groupSearch] lastObject];
    people = [qsGroup members];
    
    if (![people count]) people = [book people];
    for (id thePerson in people) {
        if ([defaults boolForKey:@"QSABIncludeContacts"]) {
            [array addObject:[QSObject objectWithPerson:thePerson]];
        }
        if ([defaults boolForKey:@"QSABIncludePhone"]) {
            [array addObjectsFromArray:[QSContactObjectHandler phoneObjectsForPerson:thePerson asChild:NO]];
        }
        if ([defaults boolForKey:@"QSABIncludeURL"]) {
            [array addObjectsFromArray:[QSContactObjectHandler URLObjectsForPerson:thePerson asChild:NO]];
        }
        if ([defaults boolForKey:@"QSABIncludeIM"]) {
            [array addObjectsFromArray:[QSContactObjectHandler imObjectsForPerson:thePerson asChild:NO]];
        }
        if ([defaults boolForKey:@"QSABIncludeEmail"]) {
            [array addObjectsFromArray:[QSContactObjectHandler emailObjectsForPerson:thePerson asChild:NO]];
        }
    }
    return array;
}

@end



@implementation QSABMailRecentsObjectSource
- (NSImage *)iconForEntry:(NSDictionary *)theEntry
{
    return [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Mail.app"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray *abArray = [NSMutableArray arrayWithCapacity:1];
	NSEnumerator *personEnumerator = [[[ABAddressBook sharedAddressBook] performSelector:@selector(mailRecents)] objectEnumerator];
	ABPerson *thePerson;
	while ((thePerson = [personEnumerator nextObject])) {
        
		NSString *email = [thePerson valueForProperty:kABEmailProperty];
		
		if ([thePerson valueForProperty:@"PersonUID"]) continue;  
		
// warning: I should use this to set the default email for an addressbook contact
		
		NSString *name = [thePerson displayName];
		
		if (email) {
			QSObject *emailObject = [QSObject URLObjectWithURL:[NSString stringWithFormat:@"mailto:%@", email]
                                                         title:[NSString stringWithFormat:@"%@ (recent email)", [name length] ? name : email]];
			
			[abArray addObject:emailObject];
		}
	}
	return abArray;
}

@end

# define kContactShowAction @"QSABContactShowAction"
# define kContactEditAction @"QSABContactEditAction"

@implementation QSABContactActions

// - (NSArray *)actions {
//	
//	NSMutableArray *actionArray = [NSMutableArray arrayWithCapacity:5];
//	//NSString *chatApp = [[NSWorkspace sharedWorkspace]absolutePathForAppBundleWithIdentifier:[QSReg chatMediatorID]];
//	
//	//NSImage *chatIcon = [[NSWorkspace sharedWorkspace]iconForFile:chatApp];
//	   
//	//  NSImage *finderProxyIcon = [[(QSController *)[NSApp delegate]finderProxy]icon];  
//	
//	QSAction *action;
//	
//	action = [QSAction actionWithIdentifier:kContactShowAction];
//	[action setIcon:        [QSResourceManager imageNamed:@"com.apple.AddressBook"]];
//	[action setProvider:    self];
//	[action setArgumentCount:1];
//	[actionArray addObject:action];  
//	
//	action = [QSAction actionWithIdentifier:kContactEditAction];
//	[action setIcon:        [QSResourceManager imageNamed:@"com.apple.AddressBook"]];
//	[action setProvider:    self];
//	[action setArgumentCount:1];
//	[actionArray addObject:action];  
//	
//	
//	
//	return actionArray; 	
//}

/*
 - (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
   NSMutableArray *newActions = [NSMutableArray arrayWithCapacity:1];
   if ([[dObject primaryType] isEqualToString:@"ABPeopleUIDsPboardType"]) {
     ABPerson *person = (ABPerson *)[[ABAddressBook sharedAddressBook] recordForUniqueId:[dObject identifier]];
     
     [newActions addObject:kContactShowAction];
     [newActions addObject:kContactEditAction];
     
     
     if (0 && [(NSArray *)[person valueForProperty:kABAIMInstantProperty]count]) {
       [newActions addObject:kContactIMAction];  
       // ***warning   * learn to check if they are online
       [newActions addObject:kContactSendItemIMAction];
       
       //  Person *thisPerson = [[[AddressCard alloc]initWithABPerson:person]autorelease];
       //  [IMService connectToDaemonWithLaunch:NO];
       
     }
     // [AddressBookPeople loadBuddyList];
     
     // People *people = [[[People alloc]init]autorelease];
     //[people addPerson:thisPerson];
     //NSLog(@"%@", );
     //  [People sendMessageToPeople:[NSArray arrayWithObject:thisPerson]];
     // [self defaultEmailAddress];
   }else if ([dObject objectForType:QSTextType]) {
     [newActions addObject:kItemSendToContactIMAction];
   }
   
   return newActions;
 }
 
 
 - (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
   //  NSLog(@"request");
   if ([action isEqualToString:kContactSendItemEmailAction]) {
     return nil; //[QSLibarrayForType:NSFilenamesPboardType];
   }
   if ([action isEqualToString:kContactSendItemIMAction]) {
     
     QSObject *textObject = [QSObject textProxyObjectWithDefaultValue:@""];
     return [NSArray arrayWithObject:textObject]; //[QSLibarrayForType:NSFilenamesPboardType];
                                                  //   return [NSArray arrayWithObject:QSTextProxy]; //[QSLibarrayForType:NSFilenamesPboardType];
   }
   if ([action isEqualToString:kItemSendToContactEmailAction]) {
     QSLibrarian *librarian = QSLib;
     return [librarian scoredArrayForString:nil inSet:[librarian arrayForType:@"ABPeopleUIDsPboardType"]];
     return [[librarian arrayForType:@"ABPeopleUIDsPboardType"] sortedArrayUsingSelector:@selector(nameCompare:)];
   }
   return nil;
 }
 
 - (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
   //NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
   if ([[action identifier] isEqualToString:kContactShowAction]) {
			} else if ([[action identifier] isEqualToString:kContactEditAction]) {
      }
   else if ([[action identifier] isEqualToString:kContactEmailAction]) {
     ABPerson *person = (ABPerson *)[[ABAddressBook sharedAddressBook] recordForUniqueId:[dObject identifier]];
     NSString *address = [[person valueForProperty:kABEmailProperty]valueAtIndex:0];
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", address]]];
   }
   return nil;
 }
 
 */

- (QSObject *)showContact:(QSObject *)dObject {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"addressbook://%@", [dObject objectForType:QSABPersonType]]]];
	return nil;
}

- (QSObject *)editContact:(QSObject *)dObject {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"addressbook://%@?edit", [dObject objectForType:QSABPersonType]]]];
	return nil;
}
/*
 NOTE: IM facility discarded?
 
- (QSObject *)sendItemViaIM:(QSObject *)dObject toPerson:(QSObject *)iObject
{
	if ([dObject validPaths]) {
		[[QSReg preferredChatMediator] sendFile:[dObject stringValue] toPerson:[iObject identifier]];
	} else {
		[[QSReg preferredChatMediator] sendText:[dObject stringValue] toPerson:[iObject identifier]];
	}	
	return nil;
}

- (QSObject *)composeIMToPerson:(QSObject *)dObject {
	[[QSReg preferredChatMediator] chatWithPerson:[dObject identifier]];
	return nil;
}
*/

@end
