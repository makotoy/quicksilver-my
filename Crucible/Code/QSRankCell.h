

#import <Foundation/Foundation.h>


@interface QSRankCell : NSCell {
	float score;
	NSInteger order;
}
@property (assign) float score;
@property (assign) NSInteger order;
@end
