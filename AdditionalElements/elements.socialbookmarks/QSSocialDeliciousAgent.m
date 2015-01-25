//
//  QSSocialDeliciousAgent.m
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import "QSSocialDeliciousAgent.h"

#define QS_SOCIAL_DELICIOUS_TIME_FMT @"yyyy-MM-dd'T'HH:mm:ss'Z'"

@implementation QSSocialDeliciousAgent

- (id)init
{
    if ((self = [super init])) {
        posts = [[NSMutableArray alloc] initWithCapacity:0];
        dates = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc
{
    [posts release], posts = nil;
    [dates release], dates = nil;
    [super dealloc];
}

- (NSString*)siteName
{
    return @"delicious";
}

- (NSDate*)getRecentDateForUser:(NSString*)user password:(NSString*)password
{
    NSString *apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/recent",
                        user, password];
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
        NSLog(@"Could not retrieve recent posts, code: %ld domain: %@ desc: %@",
              (long)[error code], [error domain], [error localizedDescription]);
        return nil;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain recent posts.  Do nothing for now");
        return nil;
    }
    NSXMLParser *postsParser = [[NSXMLParser alloc] initWithData:data];
    [postsParser setDelegate:self];
    [posts removeAllObjects];
    [postsParser parse];
    [postsParser release], postsParser = nil;
    
    if ([posts count] == 0) {
        NSLog(@"Trying to get recent posts, but there were no recent posts. Empty account or authentication error?");
        return nil;
    }
    NSString* dateStr = [[posts objectAtIndex:0] objectForKey:@"time"];
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_SOCIAL_DELICIOUS_TIME_FMT];
    NSDate* resDate = [dtFmt dateFromString:dateStr];
    [dtFmt release], dtFmt = nil;
    return resDate;
}

- (BOOL)tryAddNewBookmarks:(NSMutableArray*)bookmarks afterDate:(NSDate*)date forUser:(NSString*)user password:(NSString*)password
{
    if (!user || !password) {
        return YES;
    }
	NSString *apiurl;
    
    apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/all?start=%ld&results=%d",
              user, password, (unsigned long)[bookmarks count], 100];
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
        NSLog(@"Could not retrieve posts from Delicious, code: %ld domain: %@ desc: %@",
              (long)[error code], [error domain], [error localizedDescription]);
        return YES;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain posts.  Do nothing for now");
        return YES;
    }
    [posts removeAllObjects];
	NSXMLParser *postsParser = [[NSXMLParser alloc] initWithData:data];
	[postsParser setDelegate:self];
	[postsParser parse];
    [postsParser release], postsParser = nil;
    if ([posts count] == 0) {
        return YES;
    }
    NSString *oldestPostDateStr = [[posts lastObject] objectForKey:@"time"];

    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_SOCIAL_DELICIOUS_TIME_FMT];
    NSDate *oldestDate = [dtFmt dateFromString:oldestPostDateStr];
    [dtFmt release], dtFmt = nil;

    if ([oldestDate compare:date] == NSOrderedDescending) {
        [bookmarks addObjectsFromArray:posts];
        return NO;
    }
    for (id post in posts) {
        NSDateFormatter* postDtFmt = [[NSDateFormatter alloc] init];
        [postDtFmt setDateFormat:QS_SOCIAL_DELICIOUS_TIME_FMT];
        NSDate *postDate = [postDtFmt dateFromString:[post objectForKey:@"time"]];
        [postDtFmt release], postDtFmt = nil;
        if ([postDate compare:date] == NSOrderedDescending) {
            [bookmarks addObject:post];
        } else {
            break;
        }
    }
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

@end
