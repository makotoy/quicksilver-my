//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-15

#import "QSObjectSource.h"

@implementation QSObjectSource
+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObject:@"selection"]
          triggerChangeNotificationsForDependentKey:@"currentEntry"];
}

- (NSImage *)iconForEntry:(NSDictionary *)theEntry {return nil;}
- (NSString *)nameForEntry:(NSDictionary *)theEntry {return nil;}
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {return nil;}

- (void)invalidateSelf
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:QSCatalogSourceInvalidated
     object:NSStringFromClass([self class])];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    NSLog(@"indexIsValidFromDate:forEntry: called. Catalog Specification is more recent than index, should switch to using it!");    
    return NO;
}

- (void)populateFields { return; }

- (void)updateCurrentEntryModificationDate
{
    [currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]]
                     forKey:kItemModificationDate];	
}

- (NSMutableDictionary *)currentEntry
{ 
	return [[self selection] info];
}

@synthesize selection;
@synthesize settingsView;

- (BOOL)shouldScanOnMainThread { return NO; }
@end





