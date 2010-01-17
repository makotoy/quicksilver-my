//
//  QSWindowAnimation.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 10/24/05.

//  2010-01-15 Makoto Yamashita.

#import <Cocoa/Cocoa.h>
#import "QSMoveHelper.h"
#import "QSEmbeddedEffects.h"

#define kQSGSTransformF @"transformFn"
#define kQSGSBrightF @"brightnessFn"
#define kQSGSWarpF @"warpFn"
#define kQSGSAlphaF @"alphaFn"
#define kQSGSType @"type"
#define kQSGSDuration @"duration"
#define kQSEffectsID (CFStringRef)@"com.blacktree.QSCrucible"
#define kQSGSBrightA @"brightnessA"
#define kQSGSAlphaA @"alphaA"
#define kQSGSBrightB @"brightnessB"
#define kQSGSAlphaB @"alphaB"

@interface QSWindowAnimation : NSAnimation {
	@public
	NSWindow *_window;
	int wid;
	CGSConnection cgs;
	
	void (*effectFt)(QSWindowAnimation *);
	
	CGPointWarp *(*warpFt)(QSWindowAnimation *,float,int *,int *);
	
	CGAffineTransform (*transformFt)(QSWindowAnimation *,float);
	struct CGAffineTransform _transformA;
	struct CGAffineTransform _transformB;
	
	float (*alphaFt)(QSWindowAnimation *,float);
	float _alphaA;
	float _alphaB;
	
	float (*brightFt)(QSWindowAnimation *,float);
	float _brightA;
	float _brightB;
	NSDictionary *attributes;
	BOOL restoreTransform;
}
+ (QSWindowAnimation *)effectWithWindow:(NSWindow *)aWindow attributes:(NSDictionary *)attr;
+ (QSWindowAnimation *)showHelperForWindow:(NSWindow *)aWindow;
+ (QSWindowAnimation *)hideHelperForWindow:(NSWindow *)aWindow;

@property (retain) NSDictionary* attributes;
@property (retain) NSWindow* window;
- (void)setTransformFt:(void *)aTransformFt;
//- (void)animate:(id)sender;
//- (void)_transformWindow:(NSWindow *)window toTransformation:(CGAffineTransform)end  alpha:(float)alpha;
- (void)finishAnimation;

- (id)initWithWindow:(NSWindow *)window;

@end
