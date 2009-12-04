//
//  QSiTunesUtilityProvider.m
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/26/09.
//  Copyright 2009 Makoto Yamashita (QuickSilver-MY project). All rights reserved.
//

#import "QSiTunesUtilityProvider.h"
#import "QSiTunes.h"
#import "QSiTunesTrackSource.h"

@implementation QSiTunesUtilityProvider
- (QSObject *)playInITunes:(QSObject *)dObject
{
	if ([[dObject primaryType] isEqualTo:kQSiTunesTrackType]) {
		NSDictionary* trackDesc = [dObject objectForType:kQSiTunesTrackType];
		NSArray* trackArgs = [NSArray arrayWithObjects:
							  [trackDesc objectForKey:@"Name"],
							  [trackDesc objectForKey:@"Album"],
							  nil];		
		[[QSiTunes mainScript] executeSubroutine:@"play_track"
									   arguments:trackArgs error:NULL];
	} else {
		NSString *thingName = [dObject objectForType:NSStringPboardType];
		if (!thingName) thingName = [dObject stringValue];
		if (thingName) {
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
