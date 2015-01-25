// QSSafariPlugin.h
// QuickSilver Gamma project
// Derived from Blacktree codebase
// Makoto Yamashita 2015

#import <Foundation/Foundation.h>
#import <QSCrucible/QSCrucible.h>

@interface QSSafariObjectHandler : NSObject
- (NSArray *)safariChildren;
@end

@interface QSSafariBookmarksParser : QSParser
- (NSArray *)safariBookmarksForDict:(NSDictionary *)dict deep:(BOOL)deep includeProxies:(BOOL)proxies;
-(QSObject *)bookmarkGroupObjectForDict:(NSDictionary *)dict;
-(QSObject *)bookmarkLeafObjectForDict:(NSDictionary *)dict;
@end
@interface QSSafariHistoryParser : QSParser
@end
