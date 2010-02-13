

#import <Foundation/Foundation.h>
@interface QSCaminoBookmarksParser : QSParser
- (NSArray *)caminoBookmarksForDict:(NSDictionary *)dict;
@end
@interface QSOldCaminoBookmarksParser : QSParser
- (NSArray *)linksFromCamino:(NSString *)html;
@end
