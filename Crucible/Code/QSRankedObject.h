//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import <Foundation/Foundation.h>

@interface QSRankedObject : NSObject {
    @public
	
    int order;
    float score;
    id object;
    NSString *rankedString;
}
+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(int)order score:(float)newScore;

- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore;
- (NSComparisonResult)nameCompare:(QSRankedObject *)compareObject;

@property float score;
@property int order;
@property(retain) id object;
@property(copy) NSString* rankedString;
@end
