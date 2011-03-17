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
#define QS_DEL_CACHE_DATE_FMT @"yyyy-MM-dd'T'hh:mm:ss" // @"yyyy-MM-dd'T'hh:mm:ss'Z'"
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
        agents = [[NSArray alloc] initWithObjects:[[QSSocialDeliciousAgent alloc] init],
                  [[QSSocialDiigoAgent alloc] init],
                  nil];
        bookmarks = [[NSMutableArray alloc] initWithCapacity:0];
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
        return NO;
    }
    return YES;
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
    if (![super settingsView]){
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

- (NSDate*)convertTimestampToDate:(NSString*)timestamp
{
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_DEL_CACHE_DATE_FMT];
    NSDate *resDate = [dtFmt dateFromString:timestamp];
    [dtFmt release], dtFmt = nil;
    
    return resDate;
}
- (NSString *)cachePathForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username
{
    NSString* cacheDir = QSApplicationSupportSubPath(@"Caches/",YES);
    NSString* siteDir;
    if (site == QSDeliciousPlugIn_Delicious) {
        siteDir = [cacheDir stringByAppendingPathComponent:@"del.icio.us"];
    } else {
        siteDir = [cacheDir stringByAppendingPathComponent:@"diigo.com"];
    }

    NSString* basePath = [siteDir stringByAppendingPathComponent:username];
    NSString* jsonPath = [basePath stringByAppendingString:@".json"];
    return jsonPath;
}

- (NSDictionary*)cacheDictionaryForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username
{
    NSString* cachePath = [self cachePathForSite:site user:username];
    NSError* err;
    NSString* jsonRep = [NSString stringWithContentsOfFile:cachePath
                                                  encoding:NSUTF16StringEncoding
                                                     error:&err];
    SBJsonParser* jsonParser = [[SBJsonParser alloc] init];
    id cacheDict = [jsonParser objectWithString:jsonRep];
    [jsonParser release];
    return cacheDict;
}

- (void)writeCacheForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username
{
    NSMutableDictionary* newCache = [NSMutableDictionary dictionaryWithCapacity:0];
    NSArray* oldBookmarks = [[self cacheDictionaryForSite:site user:username] objectForKey:@"Bookmarks"];
    for (id oldBookmark in oldBookmarks) {
        NSPredicate* pred = [NSPredicate predicateWithFormat:@"hash like %@", [oldBookmark objectForKey:@"hash"]];
        NSArray* match = [bookmarks filteredArrayUsingPredicate:pred];
        if ([match count] == 0) {
            [bookmarks addObject:oldBookmark];
        }
    }
    [newCache setObject:bookmarks forKey:@"Bookmarks"];
    [newCache setObject:[[bookmarks objectAtIndex:0] objectForKey:@"time"]
                 forKey:@"Timestamp"];
    SBJsonWriter* jsonWriter = [[SBJsonWriter alloc] init];
    NSString* jsonRep = [jsonWriter stringWithObject:newCache];
    NSError* err;
    [jsonRep writeToFile:[self cachePathForSite:site user:username] atomically:NO encoding:NSUTF16StringEncoding error:&err];
}

- (NSArray *)cachedBookmarksForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self cachePathForSite:site user:username]]) {
        return [[self cacheDictionaryForSite:site user:username] objectForKey:@"Bookmarks"];
    }
    return [NSArray array];
}

- (void)updateCacheForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username
{
	NSString *password = [self passwordForSite:site user:username];
	if (!username || !password) {
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self cachePathForSite:site user:username]]) {
        [self collectBookmarksForSite:site user:username];
        return;
    }

    NSString* cacheStamp = [[self cacheDictionaryForSite:site user:username] objectForKey:@"Timestamp"];
    NSDate* postDate = [[self agentForSite:site] getRecentDateForUser:username password:password];
    if (!postDate) {
        return;
    }    
    NSDate *cacheDate = [self convertTimestampToDate:cacheStamp];

    if ([postDate compare:cacheDate] == NSOrderedDescending) {
        [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForSite:site user:username]
                                                   error:NULL];
        [self collectBookmarksForSite:site user:username];
    }
}

- (void)collectBookmarksForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username
{
	NSString *password = [self passwordForSite:site user:username];
	if (!username || !password) {
        return;
    }
    [bookmarks removeAllObjects];
    NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", [NSNumber numberWithInt:site], @"site", nil];
    NSTimer *timer = [NSTimer timerWithTimeInterval:5.0
                                             target:self
                                           selector:@selector(getPostsForDateAndFinalize:)
                                           userInfo:userDict
                                            repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer retain];
}

- (void)getPostsForDateAndFinalize:(NSTimer*)aTimer
{    
    NSString* username = [[aTimer userInfo] objectForKey:@"username"];
    QSDeliciousPlugIn_Site site = [[[aTimer userInfo] objectForKey:@"site"] intValue];
    NSString* lastTimeStamp = [[self agentForSite:site] tryAddNewBookmarks:bookmarks
                                                                   forUser:username
                                                                  password:[[aTimer userInfo] objectForKey:@"password"]];
    
    NSString* cacheStamp = [[self cacheDictionaryForSite:site user:username] objectForKey:@"Timestamp"];
    NSDate *postsDate = [self convertTimestampToDate:lastTimeStamp];
    NSDate *cacheDate = [self convertTimestampToDate:cacheStamp];
    
    if (!lastTimeStamp || [postsDate compare:cacheDate] == NSOrderedAscending) {
        [self writeCacheForSite:site user:username];
        [self invalidateSelf];
        
        [aTimer invalidate];
        [aTimer release];
    }
}

- (QSObject *)objectForPost:(NSDictionary *)post
{
	QSObject *newObject=[QSObject makeObjectWithIdentifier:[post objectForKey:@"hash"]];
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
	for (NSDictionary *post in [self cachedBookmarksForSite:site user:username]) {
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
    [self updateCacheForSite:site user:username];
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
