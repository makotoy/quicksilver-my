//  QSChromeParser.h
//  QSChromeParser
//
//  Created by Makoto Yamashita for Quicksilver.
//  Apache License v2

#import <Foundation/Foundation.h>
@interface QSChromeBookmarksParser : QSParser
- (NSArray *)chromeBookmarksForDict:(NSDictionary *)dict;
@end
