//
//  QSSocialDeliciousAgent.m
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import "QSSocialDeliciousAgent.h"


@implementation QSSocialDeliciousAgent

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
    [dates release], dates = nil;
    [super dealloc];
}

- (id)getRecentDateForUser:(NSString*)user password:(NSString*)password
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
        NSLog(@"Could not retrieve recent posts, code: %d domain: %@ desc: %@",
              [error code], [error domain], [error localizedDescription]);
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
    return [[posts objectAtIndex:0] objectForKey:@"time"];
}

- (id)tryAddNewBookmarks:(NSMutableArray*)bookmarks forUser:(NSString*)user password:(NSString*)password
{
    if (!user || !password) {
        return nil;
    }
	NSString *apiurl;
    
    apiurl = [NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/all?start=%d&results=%d",
              user, password, [bookmarks count], 100];
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
        NSLog(@"Could not retrieve posts from Delicious: %@", apiurl);// for %@, code: %d domain: %@ desc: %@",
        //dateStr, [error code], [error domain], [error localizedDescription]);
        return nil;
    } else if ([response statusCode] == 999) {
        NSLog(@"Received code 999 -- service temporarily unavailable -- while trying to obtain posts.  Do nothing for now");
        return nil;
    }
    [posts removeAllObjects];
	NSXMLParser *postsParser = [[NSXMLParser alloc] initWithData:data];
	[postsParser setDelegate:self];
	[postsParser parse];
    [postsParser release], postsParser = nil;
    
    [bookmarks addObjectsFromArray:posts];
    return [[posts lastObject] objectForKey:@"time"];
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
