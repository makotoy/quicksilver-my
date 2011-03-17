//
//  QSSocialDiigoAgent.m
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import "QSSocialDiigoAgent.h"
#import <JSON/JSON.h>
#include <CommonCrypto/CommonDigest.h>

#define QS_SOCIAL_DIIGO_TIME_FORMAT @"yyyy/MM/dd HH:mm:ss Z"

@interface QSSocialDiigoAgent(PrivateClassMethods)
+ (NSString*)convertDiigoDateRep:(NSString*)dateRep;
+ (id)retrieveDiigoObject:(NSString*)apiURLStr;
+ (NSString*)hashRep:(NSString*)inputStr;
+ (id)cacheEntryForDiigoRecord:(NSDictionary*)diigoRep;
@end

@implementation QSSocialDiigoAgent(PrivateClassMethods)

+ (NSString*)convertDiigoDateRep:(NSString*)dateRep
{
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_SOCIAL_DIIGO_TIME_FORMAT];
    NSDate* date = [dtFmt dateFromString:dateRep];
    [dtFmt release], dtFmt = nil;
    
    dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
    NSString* resStr = [dtFmt stringFromDate:date];
    [dtFmt release], dtFmt = nil;
    return resStr;
}

+ (NSString*)hashRep:(NSString*)inputStr
{
    unsigned char md[20];
    const char* inbuff = [inputStr UTF8String];
    CC_SHA1(inbuff, strlen(inbuff), md);
    int i;
    char outbuff[41];
    for (i = 0; i < 20; i++) {
        snprintf(outbuff + 2 * i, 3, "%02x", md[i]);
    }
    outbuff[40] = 0x00;
    NSString* resStr = [NSString stringWithCString:outbuff encoding:NSASCIIStringEncoding];
    return resStr;
}

+ (id)retrieveDiigoObject:(NSString*)apiURLStr
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiURLStr]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:4.0];
	[request setValue:@"Quicksilver (MacOSX) Social Bookmarks Plugin" forHTTPHeaderField:@"User-Agent"];
    NSHTTPURLResponse* response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error || [response statusCode] != 200) {
        QSLog(@"Could not retrieve posts from Diigo. Return code: %d, desc: %@",
              [response statusCode],
              (error ? [error localizedDescription] : @"error nil"));
        return nil;
    }
    NSString* jsonRep = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    SBJsonParser* jsonParser = [[SBJsonParser alloc] init];
    id resObj = [jsonParser objectWithString:jsonRep];
    [jsonParser release];
    [jsonRep release];
    return resObj;
}

+ (id)cacheEntryForDiigoRecord:(NSDictionary*)diigoRep
{
    NSDictionary* resDict;
    NSString* tagRep = @"";
    for (id tag in [[diigoRep objectForKey:@"tags"] componentsSeparatedByString:@","]) {
        tagRep = [tagRep stringByAppendingFormat:@" %@", tag];
    }
    if ([tagRep length]) {
        tagRep = [tagRep substringFromIndex:1];
    }
    resDict = [NSDictionary dictionaryWithObjectsAndKeys:
               [diigoRep objectForKey:@"url"], @"href",
               [diigoRep objectForKey:@"title"], @"description",
               [diigoRep objectForKey:@"desc"], @"extended",
               [QSSocialDiigoAgent hashRep:[diigoRep objectForKey:@"url"]], @"hash",
               [QSSocialDiigoAgent convertDiigoDateRep:[diigoRep objectForKey:@"updated_at"]], @"time",
               tagRep, @"tag",
               nil];
    return resDict;
}
@end

@implementation QSSocialDiigoAgent

- (NSDate*)getRecentDateForUser:(NSString*)user password:(NSString*)password
{
    NSString* apiURLStr;
    apiURLStr = [NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks?start=0&count=1&user=%@&filter=all",
                 user, password, user];
    id latestBmkList = [QSSocialDiigoAgent retrieveDiigoObject:apiURLStr];
    NSString* dateRep = [[latestBmkList objectAtIndex:0] objectForKey:@"updated_at"];
    NSDateFormatter* dtFmt = [[NSDateFormatter alloc] init];
    [dtFmt setDateFormat:QS_SOCIAL_DIIGO_TIME_FORMAT];
    NSDate* resDate = [dtFmt dateFromString:dateRep];
    [dtFmt release];
    return resDate;
}

- (id)tryAddNewBookmarks:(NSMutableArray*)bookmarks forUser:(NSString*)user password:(NSString*)password
{
    NSString* apiURLStr;
    apiURLStr = [NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks?start=%d&count=100&user=%@&filter=all",
                 user, password, [bookmarks count], user];
    id bmkList = [QSSocialDiigoAgent retrieveDiigoObject:apiURLStr];
    for (id bmk in bmkList) {
        [bookmarks addObject:[QSSocialDiigoAgent cacheEntryForDiigoRecord:bmk]];
    }
    if ([bmkList count] < 100) {
        return nil;
    }
    return [[bookmarks lastObject] objectForKey:@"time"];
}

@end
