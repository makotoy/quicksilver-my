//
//  QSDeliciousPlugIn_Source.h
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30


@interface QSDeliciousPlugIn_Source : QSObjectSource <NSXMLParserDelegate> {
	NSMutableArray *posts;
	NSMutableArray *tags;
	NSMutableArray *dates;
	
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passField;
}

- (void)collectBookmarksForUser:(NSString *)username;
- (NSArray *)cachedBookmarksForUser:(NSString *)username;
- (NSString *)cachePath:(NSString*)username;
- (NSDictionary*)cacheDictionaryForUser:(NSString*)username;
- (void)writeCache:(NSString*)username;
- (void)updateCacheForUser:(NSString*)username;
- (void)getDatesForUser:(NSString *)username;
- (NSString *)passwordForUser:(NSString *)username;
@end
