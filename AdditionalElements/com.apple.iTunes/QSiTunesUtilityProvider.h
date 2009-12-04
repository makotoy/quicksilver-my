//
//  QSiTunesUtilityProvider.h
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/26/09.
//  Copyright 2009 Makoto Yamashita (QuickSilver-MY project). All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSiTunesUtilityProvider : QSActionProvider {

}
- (QSObject *)playInITunes:(QSObject *)dObject;
- (QSObject *)shufflePlaylist:(QSObject *)dObject;

@end
