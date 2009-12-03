//
//  QSiTunesUtilityProvider.m
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "QSiTunesUtilityProvider.h"
#import "QSiTunes.h"
#import "QSiTunesTrackSource.h"

@implementation QSiTunesUtilityProvider
- (QSObject *)playInITunes:(QSObject *)dObject
{
	NSString *thingName = [dObject objectForType:NSStringPboardType];
	if (!thingName) thingName = [dObject stringValue];
	if (thingName) {
		if ([[dObject primaryType] isEqualTo:kQSiTunesTrackType]) {
			thingName = [[dObject objectForType:kQSiTunesTrackType]
						 objectForKey:@"Name"];
			[[QSiTunes mainScript] executeSubroutine:@"play_track"
										   arguments:thingName error:NULL];
		} else {
			[[QSiTunes mainScript] executeSubroutine:@"play_ambiguous"
										   arguments:thingName error:NULL];
		}
	}
	return dObject;
}

- (QSObject *)shufflePlaylist:(QSObject *)dObject
{
	NSString *playlistName = [dObject objectForType:NSStringPboardType];
	if (!playlistName) playlistName = [dObject stringValue];
	if (playlistName) {
		[[QSiTunes mainScript] executeSubroutine:@"shuffle_playlist"
								   arguments:playlistName error:NULL];
	}
	return dObject;
}
@end
