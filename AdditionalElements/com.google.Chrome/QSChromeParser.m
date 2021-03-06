//  QSChromeParser.m
//  QSChromeParser
//
//  Created by Makoto Yamashita for Quicksilver.
//  Apache License v2

#import "QSChromeParser.h"
#import <JSON/JSON.h>

@implementation QSChromeBookmarksParser
- (BOOL)validParserForPath:(NSString *)path
{
    return [[path lastPathComponent] isEqualToString:@"Bookmarks"];
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings
{
    NSString *dictRep = [NSString stringWithContentsOfFile:[path stringByStandardizingPath]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* dict = [parser objectWithString:dictRep error:NULL];
    NSArray* roots = [[dict objectForKey:@"roots"] allValues];
    NSMutableArray* resArray = [NSMutableArray arrayWithCapacity:0];
    [roots enumerateObjectsUsingBlock:
     ^(id obj, NSUInteger idx, BOOL *stop){
         [resArray addObjectsFromArray:chromeBookmarksForDict(obj)];
     }];
    return resArray;
}
@end

NSArray* chromeBookmarksForDict(NSDictionary *dict)
{
    if ([dict objectForKey:@"children"]) {
        NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
        [[dict objectForKey:@"children"] enumerateObjectsUsingBlock:
          ^(id child, NSUInteger idx, BOOL *stop){
            [array addObjectsFromArray:chromeBookmarksForDict(child)];
          }];
        return  array;
    } else {
        NSString *url = [dict objectForKey:@"url"];
        NSString *title = [dict objectForKey:@"name"];
        if (!(url && title)) return nil;
        
        QSObject *leaf = [QSObject URLObjectWithURL:url title:title];
        if (leaf) return [NSArray arrayWithObject:leaf];
    }
    return nil;
}

