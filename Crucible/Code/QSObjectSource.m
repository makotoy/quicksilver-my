//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-15

#import "QSObjectSource.h"

@implementation QSObjectSource
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet* resPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"currentEntry"]) {
        resPaths = [resPaths setByAddingObject:@"selection"];
    }
    return resPaths;
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
    float timeLapse = [[theEntry objectForKey:kItemModificationDate] floatValue];
    NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeLapse];
    return ([specDate compare:indexDate] == NSOrderedDescending);
//Catalog Specification is more recent than index, should switch to using this!    
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





