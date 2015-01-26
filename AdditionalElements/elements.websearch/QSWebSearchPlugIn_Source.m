//
//  QSWebSearchPlugIn_Source.m
//  QSWebSearchPlugIn
//
//  Modified by Makoto Yamashita on 10/19/05.
//  Created by Nicholas Jitkoff on 11/24/04.
//  Copyright Quicksilver project 2004-2009. All rights reserved.
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSWebSearchPlugIn_Source.h"

@implementation QSWebSearchSource

@synthesize searchSourceTabTopLevelObjects;

- (BOOL)isVisibleSource {return YES;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
	NSDate *specDate = [NSDate dateWithTimeIntervalSinceReferenceDate:
						[[theEntry objectForKey:kItemModificationDate]floatValue]];

	return ([specDate compare:indexDate] == NSOrderedDescending);	
}

- (NSImage *) iconForEntry:(NSDictionary *)dict
{
    return [QSResourceManager imageNamed:@"Find"];
}

- (NSString *)identifierForObject:(id <QSObject>)object
{
    return nil;
}

- (NSArray *) objectsForEntry:(NSDictionary *)theEntry
{	
	NSMutableArray *urlArray=[theEntry objectForKey:@"queryList"];
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	foreach(urlDict,urlArray) {
		QSObject *newObject = [QSObject URLObjectWithURL:[urlDict objectForKey:@"url"]
											       title:[urlDict objectForKey:@"name"]];
		NSNumber *encoding = [urlDict objectForKey:@"encoding"];
		if (!encoding) {
			encoding = [NSNumber numberWithInt:0];
		}
		[newObject setObject:encoding forMeta:kQSStringEncoding];
		if (newObject)[objects addObject:newObject];
	}
    return objects;   
}

- (NSView *) settingsView
{
    if (![super settingsView]) {
        NSArray *topLevelObjs;
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"QSWebSearchSource" owner:self topLevelObjects:&topLevelObjs];
        [self setSearchSourceTabTopLevelObjects:topLevelObjs];
	}
    return [super settingsView];
}

- (void)populateFields
{
    [self willChangeValueForKey:@"urlArray"];
	[self didChangeValueForKey:@"urlArray"];
	[encodingCell setMenu:[self encodingMenu]];
}

static NSMenu *encodingMenu=nil;
- (NSMenu *)encodingMenu
{
	if (!encodingMenu){	
		encodingMenu=[[NSMenu alloc]initWithTitle:@"Encodings"];
		
		const CFStringEncoding *encodings;
		encodings = CFStringGetListOfAvailableEncodings();
		int i;
		for (i=0; encodings[i] != kCFStringEncodingInvalidId; i++) {
			NSString *encodingName = (NSString *)CFStringGetNameOfEncoding(encodings[i]);
			if (i && encodings[i]-encodings[i-1]>16){
				[encodingMenu addItem:[NSMenuItem separatorItem]];
			}			
			[[encodingMenu addItemWithTitle:encodingName action:nil
							  keyEquivalent:@""]
				setTag:encodings[i]];
		}
	}
	return encodingMenu;  
}

- (void)objectDidEndEditing:(id)editor
{
	[self updateCurrentEntryModificationDate];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:QSCatalogEntryChanged
	 object:[self currentEntry]];
}

- (void)setUrlArray:(id)array
{	
	NSMutableDictionary *entry=[self currentEntry];
	[entry setObject:array forKey:@"queryList"];
}

- (NSMutableArray *)urlArray
{
	NSMutableDictionary *entry=[self currentEntry];
	NSMutableArray *urlArray=[entry objectForKey:@"queryList"];
	if (!urlArray){
		urlArray=[NSMutableArray array];
		[entry setObject:urlArray forKey:@"queryList"];
	}
	return urlArray;
}

@end
