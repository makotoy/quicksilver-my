//  QSChromeParser.h
//  QSChromeParser
//
//  Created by Makoto Yamashita for Quicksilver.
//  Apache License v2

#import <Foundation/Foundation.h>
@interface QSChromeBookmarksParser : QSParser {
}
@end

NSArray* chromeBookmarksForDict(NSDictionary *dict);

