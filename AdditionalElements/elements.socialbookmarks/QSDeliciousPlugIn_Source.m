//
//  QSDeliciousPlugIn_Source.m
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSDeliciousPlugIn_Source.h"
#import "QSSocialDeliciousAgent.h"
#import "QSSocialDiigoAgent.h"
#import <JSON/JSON.h>

#define kQSDeliciousTagType @"us.icio.del.tag"
#define QS_DEL_API_DATE_FMT @"yyyy-MM-dd"


@implementation QSDeliciousPlugIn_Source
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet* resPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"currentPassword"]) {
        resPaths = [resPaths setByAddingObject:@"selection"];
    }
    return resPaths;
}

+ (NSURL*)urlForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username
{
    NSString* formatStr;
    if (site == QSDeliciousPlugIn_Delicious) {
        formatStr = @"http://%@@del.icio.us/";
    } else {
        formatStr = @"http://%@@diigo.com/";
    }
    NSString* urlStr = [NSString stringWithFormat:formatStr, username];
    
	return [NSURL URLWithString:urlStr];
}

+ (NSURL*)urlForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username password:(NSString*)password
{
    NSString* formatStr;
    if (site == QSDeliciousPlugIn_Delicious) {
        formatStr = @"http://%@:%@@del.icio.us/";
    } else {
        formatStr = @"http://%@:%@@diigo.com/";
    }
    NSString* urlStr = [NSString stringWithFormat:formatStr, username, password];
    
	return [NSURL URLWithString:urlStr];
}

- (id)init
{
    if (self == [super init]) {
        QSSocialDeliciousAgent* deliciousAgent = [[QSSocialDeliciousAgent alloc] init];
        [deliciousAgent setDelegate:self];
        QSSocialDiigoAgent* diigoAgent = [[QSSocialDiigoAgent alloc] init];
        [diigoAgent setDelegate:self];
        agents = [[NSArray alloc] initWithObjects:deliciousAgent, diigoAgent, nil];
    }
    return self;
}

- (void)dealloc
{
    [agents release], agents = nil;
    [super dealloc];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    if (-[indexDate timeIntervalSinceNow] < 10 * 60) {
        // ten minutes, keep cache but incr update
        return YES;
    }
    return NO;
}

- (BOOL)isVisibleSource { return YES; }

- (NSImage *)iconForEntry:(NSDictionary *)dict
{
    return [[NSBundle bundleForClass:[self class]] imageNamed:@"bookmark_icon"];
}

- (NSString *)identifierForObject:(id <QSObject>)object
{
    return nil;
}

- (NSView *)settingsView
{
    if (![super settingsView]) {
        [NSBundle loadNibNamed:@"QSDeliciousPlugInSource" owner:self];
    }
    return [super settingsView];
}

- (QSSocialAgent*)agentForSite:(QSDeliciousPlugIn_Site)site
{
    if (site < [agents count]) {
        return [agents objectAtIndex:site];
    }
    return nil;
}

- (void)refreshSource
{
    /* Do nothing for now.  It's likely to be immediately after objectsForEntry,
     so the index of this source is still valid until next rescan.  invalidateSelf
     only invokes rescanForced:NO
    [self invalidateSelf];
     */
}

- (QSObject *)objectForPost:(NSDictionary *)post
{
	QSObject *newObject = [QSObject makeObjectWithIdentifier:[post objectForKey:@"hash"]];
	[newObject setObject:[post objectForKey:@"href"] forType:QSURLType];
	[newObject setName:[post objectForKey:@"description"]];
	[newObject setDetails:[post objectForKey:@"extended"]];
	[newObject setPrimaryType:QSURLType];

	return newObject;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSString *username = [theEntry objectForKey:@"username"];
    QSDeliciousPlugIn_Site site = [[theEntry objectForKey:@"site"] intValue];
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	NSMutableSet *tagSet = [NSMutableSet set];
	for (NSDictionary *post in [[self agentForSite:site] cachedBookmarksForUser:username]) {
		QSObject *newObject = [self objectForPost:post];
		[tagSet addObjectsFromArray:[[post objectForKey:@"tag"] componentsSeparatedByString:@" "]];
		[objects addObject:newObject];
	}
	if ([[theEntry objectForKey:@"includeTags"] boolValue]) {
		for (NSString *tag in tagSet) {
			QSObject* newObject;
            newObject = [QSObject makeObjectWithIdentifier:[NSString stringWithFormat:@"[del.icio.us tag]:%@",tag]];
			[newObject setObject:tag forType:kQSDeliciousTagType];
			[newObject setObject:username forMeta:@"us.icio.del.username"];
			[newObject setName:tag];
			[newObject setPrimaryType:kQSDeliciousTagType];
			[objects addObject:newObject];
		}
	}
    [[self agentForSite:site] updateCacheForUser:username
                                        password:[self passwordForSite:site user:username]];
    return objects;
}

- (void)populateFields
{
	[self willChangeValueForKey:@"selection"];
	[self didChangeValueForKey:@"selection"];
}

- (NSString *)currentPassword
{
    NSString *username = [[self currentEntry] objectForKey:@"username"];
    
	if (!username) return nil;
    
    QSDeliciousPlugIn_Site site = [[[self currentEntry] objectForKey:@"site"] intValue];    
    NSURL* url = [QSDeliciousPlugIn_Source urlForSite:site user:username];
    
	return [url keychainPassword];
}

- (void)setCurrentPassword:(NSString *)newPassword
{
	if ([newPassword length]) {
        QSDeliciousPlugIn_Site site = [[[self currentEntry] objectForKey:@"site"] intValue];    
        NSURL *url = [QSDeliciousPlugIn_Source urlForSite:site
                                                     user:[[self currentEntry] objectForKey:@"username"]
                                                 password:newPassword];
        [url addPasswordToKeychain];
    }
}

- (NSString *)passwordForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username
{
	NSURL *url = [QSDeliciousPlugIn_Source urlForSite:site user:username];
	return [url keychainPassword];	
}

@end
