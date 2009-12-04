//
//  QSiTunesPlaylistSource.m
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/27/09.
//  Copyright 2009 Makoto Yamashita (QuickSilver-MY project). All rights reserved.
//

#import "QSiTunesPlaylistSource.h"
#import "QSiTunes.h"


@interface QSObject (QSObject_iTunes_Playlists)
- (id)initWithPlaylistName:(NSString*)playlistName;
@end

@implementation QSObject (QSObject_iTunes_Playlists)

- (id)initWithPlaylistName:(NSString*)playlistName
{
	if ((self = [self init])) {
		[data setObject:[NSArray arrayWithObject:playlistName] forKey:kQSiTunesPlaylistType];
		[self setIdentifier:[@"QSiTunes-Playlist-" stringByAppendingString:playlistName]];
		[self setName:playlistName];
		[self setIcon:[[QSiTunes iTunesBundle] imageNamed:@"iTunesPlaylistIcon"]];
		[self setPrimaryType:kQSiTunesPlaylistType];
	}
	return self;
}

@end

@implementation QSiTunesPlaylistSource

- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[[QSiTunes iTunesBundle] imageNamed:@"iTunesPlaylistIcon"]];
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
	return [[QSiTunes iTunesBundle] imageNamed:@"iTunesLibraryPlaylistIcon"];
}

- (NSArray *)playlistsFallback
{
	NSMutableArray* playlistNames = [NSMutableArray arrayWithCapacity:0];
	NSString* playlistCachePath = [[QSiTunes cachePath] stringByAppendingPathComponent:@"playlist.plist"];
	if (![QSiTunes isITunesRunning]
		&& [[NSFileManager defaultManager] fileExistsAtPath:playlistCachePath]) {
		[playlistNames addObjectsFromArray:[NSArray arrayWithContentsOfFile:playlistCachePath]];
	} else {
		NSString *event_name = @"get_playlists";
		NSAppleEventDescriptor* event;
		NSAppleEventDescriptor* targetAddress;
		NSAppleEventDescriptor* subroutineDescriptor;
		
		int pid = [[NSProcessInfo processInfo] processIdentifier];
		targetAddress = [[NSAppleEventDescriptor alloc]
						 initWithDescriptorType:typeKernelProcessID
						 bytes:&pid length:sizeof(pid)];
		event = [[[NSAppleEventDescriptor alloc]
				  initWithEventClass:kASAppleScriptSuite
				  eventID:kASSubroutineEvent
				  targetDescriptor:targetAddress
				  returnID:kAutoGenerateReturnID
				  transactionID:kAnyTransactionID] autorelease];
		subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:event_name];
		[event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
		
		NSDictionary* errorInfo = nil;
		NSAppleEventDescriptor* scriptRes;
		scriptRes = [[QSiTunes mainScript] executeAppleEvent:event error:&errorInfo];
		if (errorInfo) {
			NSLog(@"Error: %@", errorInfo);
		}
		NSInteger i;
		NSAppleEventDescriptor* iThDesc;
		for (i = 1; (iThDesc = [scriptRes descriptorAtIndex:i]); i++) {
			[playlistNames addObject:[iThDesc stringValue]];
		}
		[playlistNames writeToFile:playlistCachePath atomically:YES];
	}
	return playlistNames;
}	

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray* playlistNames = [NSMutableArray arrayWithCapacity:0];
	// Look for iTunes library xml file (plist)
	NSArray* playlists = [[QSiTunes iTunesLibrary] objectForKey:@"Playlists"];
	if (playlists) {
		for (NSDictionary* playlistDesc in playlists) {
			[playlistNames addObject:[playlistDesc objectForKey:@"Name"]];
		}
	} else {
		// fail, query through Apple Script
		[playlistNames addObjectsFromArray:[self playlistsFallback]];
	}
	NSMutableArray* resultArray = [NSMutableArray arrayWithCapacity:0];
	for (NSString* playlistName in playlistNames) {
		QSObject* playlist = [[QSObject alloc] initWithPlaylistName:playlistName];
		if (playlist) [resultArray addObject:[playlist autorelease]];
	}
	return resultArray;
}
@end

