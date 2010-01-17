// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30

#import <AddressBook/AddressBook.h>

NSString *formattedContactName(NSString *firstName, NSString *lastName,
							   NSString *middleName, NSString *suffix,
							   NSString *prefix);

@interface QSContactObjectHandler : NSObject {
}
+ (NSArray *)URLObjectsForPerson:(ABPerson *)person asChild:(BOOL)asChild;
+ (NSArray *)emailObjectsForPerson:(ABPerson *)person asChild:(BOOL)asChild;
+ (NSArray *)phoneObjectsForPerson:(ABPerson *)person asChild:(BOOL)asChild;
+ (NSArray *)addressObjectsForPerson:(ABPerson *)person asChild:(BOOL)asChild;
+ (NSArray *)imObjectsForPerson:(ABPerson *)person asChild:(BOOL)asChild;
- (BOOL)loadChildrenForObject:(QSObject *)object;
@end

@interface QSObject (ContactHandling)
+ (id)objectWithPerson:(ABPerson *)person;
- (NSString *)nameForRecord:(ABRecord *)record;
- (id)initWithPerson:(ABPerson *)person;
- (void)loadContactInfo;
- (BOOL)useDefaultIMFromPerson:(ABPerson *)person;
- (BOOL)useDefaultEmailFromPerson:(ABPerson *)person;
- (NSString *)addressBookIdentifier;
@end