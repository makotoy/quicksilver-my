//
//  QSiTunes.h
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/28/09.
//  Copyright 2009 Makoto Yamashita (QuickSilver-MY project). All rights reserved.
//

// TODO: use external library such as EyeTunes?

#import <Cocoa/Cocoa.h>


@interface QSiTunes : NSObject {

}
+ (NSBundle*)iTunesBundle;
+ (NSAppleScript*)mainScript;
+ (NSString*)cachePath;
+ (BOOL)isITunesRunning;
+ (NSDictionary*)iTunesLibrary;
@end
