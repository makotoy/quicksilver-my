//
//  QSCIEffectOverlay.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/20/05.

//  2010-01-09 Makoto Yamashita

#import <Cocoa/Cocoa.h>

@interface QSCIEffectOverlay : NSObject {
	CGSWindow wid;
	CGSWindowFilterRef fid;
	CGSConnection cid;
}
- (void)setFilter:(NSString *)filter;
- (void)setLevel:(CGWindowLevel)level;
- (void)createOverlayInRect:(CGRect)r;
@end
