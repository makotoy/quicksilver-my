//
//  QSDeliciousPlugIn_Source.h
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSSocialAgent.h"

typedef enum _QSDeliciousPlugIn_Site {
    QSDeliciousPlugIn_Delicious,
    QSDeliciousPlugIn_Diigo
} QSDeliciousPlugIn_Site;

@interface QSDeliciousPlugIn_Source : QSObjectSource {
	NSMutableArray *tags;
    NSArray *agents;
    NSMutableArray *bookmarks;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passField;
}
- (QSSocialAgent*)agentForSite:(QSDeliciousPlugIn_Site)site;
- (NSDate*)convertTimestampToDate:(NSString*)timestamp;
- (NSArray *)cachedBookmarksForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username;
- (NSString *)cachePathForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username;
- (NSDictionary*)cacheDictionaryForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username;
- (void)writeCacheForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username;
- (void)updateCacheForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username;
- (void)collectBookmarksForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username;
- (NSString *)passwordForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username;
@end
