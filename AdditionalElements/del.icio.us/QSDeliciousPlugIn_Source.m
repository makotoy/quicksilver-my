//
//  QSDeliciousPlugIn_Source.m
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSDeliciousPlugIn_Source.h"

#define kQSDeliciousTagType @"us.icio.del.tag"

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
    return [QSApplicationSupportSubPath(@"Caches/del.icio.us/",YES)
              stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", username]];
}

- (NSArray *)cachedBookmarksForUser:(NSString *)username
{
	return [NSArray arrayWithContentsOfFile:[self cachePath:username]];
}

- (NSString *)passwordForUser:(NSString *)username
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@@del.icio.us/", username]];
	return [url keychainPassword];	
}

- (NSArray *)bookmarksForUser:(NSString *)username
{
	NSString *password = [self passwordForUser:username];
	if (!username || !password) return nil;
	NSString *apiurl;
    [posts removeAllObjects];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self cachePath:username]]) {
        [posts addObjectsFromArray:[self cachedBookmarksForUser:username]];
        apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/recent?",
                  username, password];
    } else {
        apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/all?",
                  username, password];
    }
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiurl]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:60.0];
	[theRequest setValue:@"Quicksilver (Blacktree,MacOSX)" forHTTPHeaderField:@"User-Agent"];
    NSError *error = nil;
    NSHTTPURLResponse* response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest
                                         returningResponse:&response
                                                     error:&error];
    if (error) {
        NSLog(@"Could not retrieve posts, code: %d domain: %@ desc: %@", [error code], [error domain], [error localizedDescription]);
        return nil;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- do nothing for now");
        return nil;
    }
	NSXMLParser *postParser = [[NSXMLParser alloc]initWithData:data];
	[postParser setDelegate:self];
	[postParser parse];
    [postParser release], postParser = nil;
	[posts writeToFile:[self cachePath:username] atomically:NO];
	return posts;
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
	for (NSDictionary *post in [self bookmarksForUser:username]) {
		QSObject *newObject = [self objectForPost:post];
		[tagSet addObjectsFromArray:[[post objectForKey:@"tag"] componentsSeparatedByString:@" "]];
		[objects addObject:newObject];
	}
	if ([[theEntry objectForKey:@"includeTags"] boolValue]){
		for (NSString *tag in tagSet){
			QSObject* newObject=[QSObject makeObjectWithIdentifier:[NSString stringWithFormat:@"[del.icio.us tag]:%@",tag]];
			[newObject setObject:tag forType:kQSDeliciousTagType];
			[newObject setObject:username forMeta:@"us.icio.del.username"];
			[newObject setName:tag];
			[newObject setPrimaryType:kQSDeliciousTagType];
			[objects addObject:newObject];
		}
	}
    return objects;
}

- (NSArray *)objectsForTag:(NSString *)tag username:(NSString *)username
{	
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	for (NSDictionary* post in [self cachedBookmarksForUser:username]) {
		if ([[post objectForKey:@"tag"] rangeOfString:tag].location == NSNotFound) {
            continue;
        }
		[objects addObject:[self objectForPost:post]];
	}
	return objects;
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
    NSString* urlStr = [NSString stringWithFormat:@"http://%@:%@@del.icio.us/", [self username], newPassword];
	NSURL *url=[NSURL URLWithString:urlStr];
	if ([newPassword length]) [url addPasswordToKeychain];
}
/*
- (void)setQuickIconForObject:(QSObject *)object
{
	[object setIcon:[[NSBundle bundleForClass:[self class]] imageNamed:@"bookmark_icon"]];
}
*/

@end
