//
//  QSiTunes.h
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSiTunes : NSObject {

}
+ (NSBundle*)iTunesBundle;
+ (NSAppleScript*)mainScript;
+ (NSString*)cachePath;
+ (BOOL)isITunesRunning;
+ (NSDictionary*)iTunesLibrary;
@end
