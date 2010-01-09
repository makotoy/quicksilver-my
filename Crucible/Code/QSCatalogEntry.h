//
//  QSCatalogEntry.h
//  Quicksilver
//
//  Created by Alcor on 2/8/05.

//  2010-01-03 Makoto Yamashita

#import <Cocoa/Cocoa.h>

@interface QSCatalogEntry : NSObject {
	NSDate *indexDate;
	BOOL isPreset;
	
	NSString *name;

	id parent;
	NSMutableArray *children;
	
	NSMutableDictionary *info;
	NSMutableArray *contents;
	NSBundle *bundle;
	BOOL isScanning;
	BOOL isRestricted;
}

+ (QSCatalogEntry *)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (QSCatalogEntry *)initWithDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSDictionary *)dictionaryRepresentation;
- (QSCatalogEntry *)childWithID:(NSString *)theID;
- (QSCatalogEntry *)childWithPath:(NSString *)path;
- (BOOL)isRestricted;
- (BOOL)isSuppressed;
- (BOOL)isPreset;
- (BOOL)isSeparator;
- (BOOL)isGroup;
- (NSInteger)state;
- (int)hasEnabledChildren;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setDeepEnabled:(BOOL)enabled;
- (void)pruneInvalidChildren;
- (NSArray *)leafIDs;
- (NSArray *)leafEntries;
- (NSArray *)deepChildrenWithGroups:(BOOL)groups leaves:(BOOL)leaves disabled:(BOOL)disabled;
- (NSString *) identifier;
- (NSArray *)ancestors;
- (NSString *) name;
- (NSImage *) icon;
- (int)deepObjectCount;
- (BOOL)loadIndex;
- (void)saveIndex;
- (BOOL)indexIsValid;
- (BOOL)isCatalog;
- (id)source;
- (BOOL)canBeIndexed;
- (NSArray *)scannedObjects;
- (NSArray *)scanAndCache;
- (NSArray *)scanForced:(BOOL)force;
@property (retain) NSMutableArray *children;
- (NSMutableArray *)getChildren;
- (NSArray *)contents;
- (NSArray *)contentsScanIfNeeded:(BOOL)canScan;
- (void)setContents:(NSArray *)newContents;
- (NSIndexPath *)catalogIndexPath;
- (NSMutableDictionary *)info;
- (QSCatalogEntry *)uniqueCopy;
- (NSString *)indexLocation;
- (void)setName:(NSString *)newName;
- (NSIndexPath *)catalogSetIndexPath;
@property (retain) NSDate *indexDate;
@property (assign) BOOL isScanning;
- (NSArray *)_contents;
- (NSMutableDictionary *)info;
- (NSString *)countString;
@end
