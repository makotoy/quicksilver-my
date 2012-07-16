//
//  QSSocialAgent.m
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import "QSSocialAgent.h"
#import <JSON/JSON.h>
#define QS_DEL_CACHE_DATE_FMT @"yyyy-MM-dd'T'HH:mm:ss'Z'"


@implementation QSSocialAgent

@synthesize delegate;

- (id)init
{
    if ((self = [super init])) {
        caches = [[NSMutableDictionary alloc] initWithCapacity:0];
        newbookmarks = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSString*)siteName
{
    return @"NeedsToBeOverridden";
}


- (NSDate*)convertTimestampToDate:(NSString*)timestamp
{
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_DEL_CACHE_DATE_FMT];
    NSDate *resDate = [dtFmt dateFromString:timestamp];
    [dtFmt release], dtFmt = nil;
    
    return resDate;
}

- (NSString *)cachePathForUser:(NSString*)username
{
    NSString* cacheDir = QSApplicationSupportSubPath(@"Caches/",YES);
    NSString* siteDir = [cacheDir stringByAppendingPathComponent:[self siteName]];
    
    NSString* basePath = [siteDir stringByAppendingPathComponent:username];
    NSString* jsonPath = [basePath stringByAppendingString:@".json"];
    return jsonPath;
}

- (NSDictionary*)cacheDictionaryForUser:(NSString*)username
{
    NSDictionary* resDict;
    if ((resDict = [caches objectForKey:username])) {
        return resDict;
    }
    NSError* err;
    NSString* jsonRep = [NSString stringWithContentsOfFile:[self cachePathForUser:username]
                                                  encoding:NSUTF16StringEncoding
                                                     error:&err];
    SBJsonParser* jsonParser = [[SBJsonParser alloc] init];
    resDict = [jsonParser objectWithString:jsonRep];
    [jsonParser release];
    return resDict;
}

- (NSDate*)cacheDateForUser:(NSString*)username
{
    NSString* dateStr = [[self cacheDictionaryForUser:username] objectForKey:@"Timestamp"];
    NSDate* cacheDate = [self convertTimestampToDate:dateStr];
    if (!cacheDate) {
        cacheDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    return cacheDate;
}

- (void)writeCacheForUser:(NSString*)username
{
    NSDictionary* newCache = [self cacheDictionaryForUser:username];
    if (!newCache) {
        return;
    }
    SBJsonWriter* jsonWriter = [[SBJsonWriter alloc] init];
    NSString* jsonRep = [jsonWriter stringWithObject:newCache];
    NSError* err;
    NSString* cachePath = [self cachePathForUser:username];
    NSString* cacheDir = [cachePath stringByDeletingLastPathComponent];
    NSFileManager* fileMan = [NSFileManager defaultManager];
    if (![fileMan fileExistsAtPath:cacheDir]) {
        [fileMan createDirectoryAtPath:cacheDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    }
    [jsonRep writeToFile:cachePath
              atomically:NO
                encoding:NSUTF16StringEncoding
                   error:&err];
}

- (NSArray *)cachedBookmarksForUser:(NSString *)username
{
    NSDictionary* cacheDict = [self cacheDictionaryForUser:username];

    if (cacheDict) {
        return [cacheDict objectForKey:@"Bookmarks"];
    }
    return [NSArray array];
}


- (void)updateCacheForUser:(NSString*)username password:(NSString*)password
{
	if (!username || !password) {
        return;
    }
    if (![self cacheDictionaryForUser:username]) {
        [self collectBookmarksForUser:username password:password];
        return;
    }
    
    NSString* cacheStamp = [[self cacheDictionaryForUser:username] objectForKey:@"Timestamp"];
    NSDate* postDate = [self getRecentDateForUser:username password:password];
    if (!postDate) {
        return;
    }    
    NSDate *cacheDate = [self convertTimestampToDate:cacheStamp];
    if ([postDate compare:cacheDate] == NSOrderedDescending) {
        [self collectBookmarksForUser:username password:password];
    }
}

- (void)collectBookmarksForUser:(NSString *)username password:(NSString*)password
{
	if (!username || !password) {
        return;
    }
    [newbookmarks removeAllObjects];
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
    NSString* username = [[aTimer userInfo] objectForKey:@"username"];
    NSDate *cacheDate = [self cacheDateForUser:username];
    BOOL finished = [self tryAddNewBookmarks:newbookmarks
                                   afterDate:cacheDate
                                     forUser:username
                                    password:[[aTimer userInfo] objectForKey:@"password"]];
    
    if (finished) {
        if ([newbookmarks count]) {
            [newbookmarks addObjectsFromArray:[self cachedBookmarksForUser:username]];
            NSMutableDictionary* newCache = [NSMutableDictionary dictionaryWithCapacity:0];
            [newCache setObject:newbookmarks forKey:@"Bookmarks"];
            [newCache setObject:[[newbookmarks objectAtIndex:0] objectForKey:@"time"]
                         forKey:@"Timestamp"];
            [caches setObject:newCache forKey:username];
            [self writeCacheForUser:username];
            [[self delegate] refreshSource];
            [newbookmarks removeAllObjects];
        }
        [aTimer invalidate];
        [aTimer release];
    }
}

- (NSDate*)getRecentDateForUser:(NSString*)user password:(NSString*)password
{
    return nil;
}

- (BOOL)tryAddNewBookmarks:(NSMutableArray*)bookmarks afterDate:(NSDate*)date forUser:(NSString*)user password:(NSString*)password
{
    return YES;
}

@end
