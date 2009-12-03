//
//  QSiTunesTrackSource.m
//  iTunesElement
//
//  Created by Makoto Yamashita on 11/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "QSiTunesTrackSource.h"
#import "QSiTunes.h"


@interface QSObject (QSObject_iTunes_Tracks)
- (id)initWithTrackName:(NSString*)playlistName;
- (id)initWithTrackDescription:(NSDictionary*)trackDesc;
@end

@implementation QSObject (QSObject_iTunes_Tracks)

- (id)initWithTrackName:(NSString*)trackName
{
	if ((self = [self init])) {
		[data setObject:[NSDictionary dictionaryWithObject:trackName forKey:@"Name"]
				 forKey:kQSiTunesTrackType];
		[self setIdentifier:[@"QSiTunes-Track-" stringByAppendingString:trackName]];
		[self setName:trackName];
//		[self setIcon:[[QSiTunes iTunesBundle] imageNamed:@"iTunesAlbumBrowserIcon"]];
		[self setPrimaryType:kQSiTunesTrackType];
	}
	return self;
}

- (id)initWithTrackDescription:(NSDictionary*)trackDesc
{
	if ((self = [self init])) {
		[data setObject:trackDesc forKey:kQSiTunesTrackType];
		[self setIdentifier:[NSString stringWithFormat:@"QSiTunes-Track-%@",
							 [trackDesc objectForKey:@"Track ID"]]];
		[self setName:[trackDesc objectForKey:@"Name"]];
		NSString* albumName = [trackDesc objectForKey:@"Album"];
		NSString* artistName = [trackDesc objectForKey:@"Artist"];
		[self setLabel:[NSString stringWithFormat:@"%@ - %@ - %@",
						[trackDesc objectForKey:@"Name"],
					   (albumName ? albumName : @"No Album"),
					   (artistName ? artistName : @"No Artist")]];
		[self setPrimaryType:kQSiTunesTrackType];
	}
	return self;
}

@end

@implementation QSiTunesTrackSource

- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[[QSiTunes iTunesBundle] imageNamed:@"iTunesAlbumBrowserIcon"]];
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
	return [[QSiTunes iTunesBundle] imageNamed:@"iTunesAlbumBrowserIcon"];
}

- (NSArray *)tracksFallback
{
	NSMutableArray* trackNames = [NSMutableArray arrayWithCapacity:0];
	NSString* tracksCachePath= [[QSiTunes cachePath] stringByAppendingPathComponent:@"tracks.plist"];
	if (![QSiTunes isITunesRunning]
		&& [[NSFileManager defaultManager] fileExistsAtPath:tracksCachePath]) {
		[trackNames addObjectsFromArray:[NSArray arrayWithContentsOfFile:tracksCachePath]];
	} else {
		NSLog(@"Failed to get track names from iTunes libray xml.");
		NSString *event_name = @"get_tracks";
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
			[trackNames addObject:[iThDesc stringValue]];
		}
		[trackNames writeToFile:tracksCachePath atomically:YES];
	}
	return trackNames;
}	

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
	NSMutableArray* resultArray = [NSMutableArray arrayWithCapacity:0];
	// Look for iTunes library xml file (plist)
	NSArray* tracks = [[[QSiTunes iTunesLibrary] objectForKey:@"Tracks"] allValues];
	if (tracks) {
		for (NSDictionary* trackDesc in tracks) {
			QSObject* track = [[QSObject alloc] initWithTrackDescription:trackDesc];
			if (track) [resultArray addObject:[track autorelease]];
		}
		return resultArray;
	}
	// fail, query through Apple Script
	NSMutableArray* trackNames = [NSMutableArray arrayWithCapacity:0];
	[trackNames addObjectsFromArray:[self tracksFallback]];
	for (NSString* trackName in trackNames) {
		QSObject* track = [[QSObject alloc] initWithTrackName:trackName];
		if (track) [resultArray addObject:[track autorelease]];
	}
	return resultArray;
}

@end
