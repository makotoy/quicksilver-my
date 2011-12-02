//
//  QSSocialAgent.h
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define QS_SOCIAL_DELICIOUS_TIME_FMT @"yyyy-MM-dd'T'HH:mm:ss'Z'"

@protocol QSSocialAgentDelegate <NSObject>

- (void)refreshSource;

@end

@interface QSSocialAgent : NSObject {
    NSMutableDictionary* caches;
    NSMutableArray *newbookmarks;
    id<QSSocialAgentDelegate> delegate;
}
- (NSString*)siteName;
- (NSString *)cachePathForUser:(NSString*)username;
- (NSDictionary*)cacheDictionaryForUser:(NSString*)username;
- (NSDate*)cacheDateForUser:(NSString*)username;
- (void)writeCacheForUser:(NSString*)username;
- (NSArray *)cachedBookmarksForUser:(NSString *)username;
- (void)updateCacheForUser:(NSString*)username password:(NSString*)password;
- (void)collectBookmarksForUser:(NSString *)username password:(NSString*)password;
- (void)getPostsForDateAndFinalize:(NSTimer*)aTimer;
- (NSDate*)getRecentDateForUser:(NSString*)user password:(NSString*)password;
- (BOOL)tryAddNewBookmarks:(NSMutableArray*)bookmarks afterDate:(NSDate*)date forUser:(NSString*)user password:(NSString*)password;

@property(retain) id<QSSocialAgentDelegate> delegate;
@end
