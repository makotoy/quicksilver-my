//
//  QSDeliciousPlugIn_Source.m
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSDeliciousPlugIn_Source.h"

#import <JSON/JSON.h>

#define kQSDeliciousTagType @"us.icio.del.tag"
#define QS_DEL_CACHE_DATE_FMT @"yyyy-MM-dd"

@implementation QSDeliciousPlugIn_Source
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet* resPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"currentPassword"]) {
        resPaths = [resPaths setByAddingObject:@"selection"];
    }
    return resPaths;
}

- (id)init
{
    if (self == [super init]) {
        posts = [[NSMutableArray alloc] initWithCapacity:0];
        dates = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    [posts release], posts = nil;
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

- (NSString *)cachePath:(NSString*)username
{
    NSString* cacheDir = QSApplicationSupportSubPath(@"Caches/del.icio.us/",YES);
    NSString* basePath = [cacheDir stringByAppendingPathComponent:username];
    NSString* jsonPath = [basePath stringByAppendingString:@".json"];
    return jsonPath;
}

- (NSDictionary*)cacheDictionaryForUser:(NSString*)username
{
    NSString* cachePath = [self cachePath:username];
    NSError* err;
    NSString* jsonRep = [NSString stringWithContentsOfFile:cachePath
                                                  encoding:NSUTF16StringEncoding
                                                     error:&err];
    SBJsonParser* jsonParser = [[SBJsonParser alloc] init];
    id cacheDict = [jsonParser objectWithString:jsonRep];
    return cacheDict;
}

- (void)writeCache:(NSString*)username
{
    NSMutableDictionary* newCache = [NSMutableDictionary dictionaryWithCapacity:0];
    [newCache setObject:posts forKey:@"Bookmarks"];
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_DEL_CACHE_DATE_FMT];
    [newCache setObject:[dtFmt stringFromDate:[NSDate date]] forKey:@"Timestamp"];
    [dtFmt release], dtFmt = nil;
    SBJsonWriter* jsonWriter = [[SBJsonWriter alloc] init];
    NSString* jsonRep = [jsonWriter stringWithObject:newCache];
    NSError* err;
    [jsonRep writeToFile:[self cachePath:username] atomically:NO encoding:NSUTF16StringEncoding error:&err];
}

- (NSArray *)cachedBookmarksForUser:(NSString *)username
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self cachePath:username]]) {
        return [[self cacheDictionaryForUser:username] objectForKey:@"Bookmarks"];
    }
    return [NSArray array];
}

- (void)updateCacheForUser:(NSString*)username
{
	NSString *password = [self passwordForUser:username];
	if (!username || !password) {
        return;
    }
    NSString *apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/recent",
              username, password];
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiurl]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:4.0];
	[theRequest setValue:@"Quicksilver (MacOSX) Social Bookmarks Plugin" forHTTPHeaderField:@"User-Agent"];
    NSError *error = nil;
    NSHTTPURLResponse* response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
                                         returningResponse:&response
                                                     error:&error];
    if (error) {
        NSLog(@"Could not retrieve recent posts, code: %d domain: %@ desc: %@",
              [error code], [error domain], [error localizedDescription]);
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain recent posts.  Do nothing for now");
    } else {
        NSXMLParser *postsParser = [[NSXMLParser alloc] initWithData:data];
        [postsParser setDelegate:self];
        [postsParser parse];
        [postsParser release], postsParser = nil;

        [self invalidateSelf];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self cachePath:username]]) {
        [self collectBookmarksForUser:username];
        return;
    }
    NSString* cacheStamp = [[self cacheDictionaryForUser:username] objectForKey:@"Timestamp"];

    if ([dates count] == 0) {
        [self getDatesForUser:username];
    }
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_DEL_CACHE_DATE_FMT];
    NSDate *postsDate = [dtFmt dateFromString:[dates objectAtIndex:0]];
    NSDate *cacheDate = [dtFmt dateFromString:cacheStamp];
    [dtFmt release], dtFmt = nil;
    
    if ([postsDate compare:cacheDate] == NSOrderedDescending) {
        [[NSFileManager defaultManager] removeItemAtPath:[self cachePath:username]
                                                   error:NULL];
        [self collectBookmarksForUser:username];
    }
}

- (NSString *)passwordForUser:(NSString *)username
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@@del.icio.us/", username]];
	return [url keychainPassword];	
}

- (void)getDatesForUser:(NSString *)username
{
	NSString *password = [self passwordForUser:username];
	if (!username || !password) {
        return;
    }
    NSString *apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/dates",
                        username, password];
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiurl]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:60.0];
	[theRequest setValue:@"Quicksilver (MacOSX) Social Bookmarks Plugin" forHTTPHeaderField:@"User-Agent"];
    NSError *error = nil;
    NSHTTPURLResponse* response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
                                         returningResponse:&response
                                                     error:&error];
    if (error) {
        NSLog(@"Could not retrieve date list, code: %d domain: %@ desc: %@", [error code], [error domain], [error localizedDescription]);
        return;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain date list.  Do nothing for now");
        return;
    }
    [dates removeAllObjects];
	NSXMLParser *datesParser = [[NSXMLParser alloc] initWithData:data];
	[datesParser setDelegate:self];
	[datesParser parse];
    [datesParser release], datesParser = nil;
}

- (void)collectBookmarksForUser:(NSString *)username
{
	NSString *password = [self passwordForUser:username];
	if (!username || !password) {
        return;
    }
    if ([dates count] == 0) {
        [self getDatesForUser:username];
    }
    [posts removeAllObjects];

    NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", nil];
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
    NSString *username = [[aTimer userInfo] objectForKey:@"username"];
	NSString *password = [[aTimer userInfo] objectForKey:@"password"];
	if (!username || !password) {
        [aTimer invalidate], [aTimer release];
        return;
    }
	NSString *apiurl;
    NSString *dateStr = [dates objectAtIndex:0];
    [dates removeObjectAtIndex:0];
    
    apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/get?dt=%@",
              username, password, dateStr];
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiurl]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:4.0];
	[theRequest setValue:@"Quicksilver (MacOSX) Social Bookmarks Plugin" forHTTPHeaderField:@"User-Agent"];
    NSError *error = nil;
    NSHTTPURLResponse* response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
                                         returningResponse:&response
                                                     error:&error];
    if (error) {
        NSLog(@"Could not retrieve posts");// for %@, code: %d domain: %@ desc: %@",
              //dateStr, [error code], [error domain], [error localizedDescription]);
        [aTimer invalidate], [aTimer release];
        return;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain posts for %@.  Do nothing for now", dateStr);
        [aTimer invalidate], [aTimer release];
        return;
    }
	NSXMLParser *postsParser = [[NSXMLParser alloc] initWithData:data];
	[postsParser setDelegate:self];
	[postsParser parse];
    [postsParser release], postsParser = nil;

    [self writeCache:username];
    [self invalidateSelf];

    if ([dates count] == 0) {
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
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	NSMutableSet *tagSet=[NSMutableSet set];
	for (NSDictionary *post in [self cachedBookmarksForUser:username]) {
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
    [self updateCacheForUser:username];
    return objects;
}

- (NSArray *)objectsForTag:(NSString *)tag username:(NSString *)username
{	
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"tag contains %@", tag];

    return [[self cachedBookmarksForUser:username] filteredArrayUsingPredicate:pred];
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
	[object setChildren:
     [self objectsForTag:[object objectForType:kQSDeliciousTagType] 
                username:[object objectForMeta:@"us.icio.del.username"]]];
	return YES;
}

#pragma mark XML Stuff

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{	
	if ([elementName isEqualToString:@"post"] && attributeDict) {
        NSPredicate* postPred = [NSPredicate predicateWithFormat:@"href = %@",
                                   [attributeDict objectForKey:@"href"]];
        NSArray* matches = [posts filteredArrayUsingPredicate:postPred];
        if ([matches count]) {
            NSUInteger index = [posts indexOfObject:[matches objectAtIndex:0]];
            [posts replaceObjectAtIndex:index withObject:attributeDict];
        } else {
            [posts addObject:attributeDict];
        }
    } else if ([elementName isEqualToString:@"date"]) {
        NSString *dateStr = [attributeDict objectForKey:@"date"];
        if (![dates containsObject:dateStr]) {
            [dates addObject:dateStr];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
}

#pragma mark Pref Pane UI

- (NSString *) mainNibName{	return @"QSDeliciousPrefPane"; }

- (void)populateFields
{
	[self willChangeValueForKey:@"username"];
	[self didChangeValueForKey:@"username"];
}

- (NSString *)username
{
	return [[self currentEntry] objectForKey:@"username"];
}

- (void)setUsername:(NSString*)newUsername
{
	[[self currentEntry] setObject:newUsername forKey:@"username"];
}

- (NSString *)currentPassword
{
	if (![self username]) return nil;
    NSString* urlStr = [NSString stringWithFormat:@"http://%@@del.icio.us/", [self username]];
	NSURL *url=[NSURL URLWithString:urlStr];

	return [url keychainPassword];
}

- (void)setCurrentPassword:(NSString *)newPassword
{
	if ([newPassword length]) {
        NSString* urlStr = [NSString stringWithFormat:@"http://%@:%@@del.icio.us/", [self username], newPassword];
        NSURL *url=[NSURL URLWithString:urlStr];
        [url addPasswordToKeychain];
    }
}
/*
- (void)setQuickIconForObject:(QSObject *)object
{
	[object setIcon:[[NSBundle bundleForClass:[self class]] imageNamed:@"bookmark_icon"]];
}
*/

@end
