//
//  QSLSTools.m
//  Quicksilver
//
//  Created by Alcor on 4/6/05.

//  2010-01-16 Makoto Yamashita

#import "QSLSTools.h"

NSString *QSApplicationPathForURL(NSString *urlString){
	NSURL *appURL = nil; 
	LSGetApplicationForURL((CFURLRef)[NSURL URLWithString: urlString],kLSRolesAll, NULL, (CFURLRef *)&appURL); 
	
	return [appURL path];
}

NSString *QSApplicationIdentifierForURL(NSString *urlString){
	NSString *path=QSApplicationPathForURL(urlString);
	if (!path)return nil;
	NSDictionary *infoDict=(NSDictionary *)CFBundleCopyInfoDictionaryForURL((CFURLRef)[NSURL fileURLWithPath:path]);
	[infoDict autorelease];
	return [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
}
