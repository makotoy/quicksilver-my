//
//  QSiTunes.m
//  iTunesElement
//
//  Created by Makoto Yamashita on 10/28/09.
//  Copyright 2009 Makoto Yamashita (QuickSilver-MY project). All rights reserved.
//

#import "QSiTunes.h"


@implementation QSiTunes
+ (NSBundle*)iTunesBundle
{
	return [NSBundle bundleForClass:[self class]];
}

+ (NSAppleScript*)mainScript
{
	NSString *scriptPath;
	NSURL *scriptURL;
	NSAppleScript *iTunesScript;
	scriptPath = [[self iTunesBundle] pathForResource:@"iTunesScript"
											   ofType:@"scpt"];
	scriptURL = [NSURL fileURLWithPath:scriptPath];
	iTunesScript = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL
														  error:nil];
	return [iTunesScript autorelease];
}

+ (NSString*)cachePath
{
	NSString* cacheDirPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Quicksilver/Caches/iTunes"];
	NSFileManager* fileMan = [NSFileManager defaultManager];
	if (![fileMan fileExistsAtPath:cacheDirPath]) {
		[fileMan createDirectoryAtPath:cacheDirPath
		   withIntermediateDirectories:YES
							attributes:nil
								 error:NULL];
	}
	return cacheDirPath;
}

+ (BOOL)isITunesRunning
{
	NSArray *runningApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSPredicate* iTunesPred = [NSPredicate predicateWithFormat:@"NSApplicationBundleIdentifier = \"com.apple.iTunes\""];
	if ([[runningApps filteredArrayUsingPredicate:iTunesPred] count] > 0) {
		return YES;
	}
	return NO;
}

+ (NSDictionary*)iTunesLibrary
{
	NSString* libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Music/iTunes/iTunes Music Library.xml"];
	return [NSDictionary dictionaryWithContentsOfFile:libraryPath];
}

@end
