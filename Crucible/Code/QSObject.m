//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import "QSObject.h"
#import "QSObject_Pasteboard.h"
#import "QSObject_FileHandling.h"

#import "QSObject_PropertyList.h"

static NSMutableDictionary *objectDictionary;

static NSMutableSet *iconLoadedSet;
static NSMutableSet *childLoadedSet;

static NSTimeInterval globalLastAccess;

static BOOL QSObjectInitialized = NO;

NSSize QSMaxIconSize;

@implementation QSObject
+ (void)initialize {
	if (!QSObjectInitialized) {
        QSMaxIconSize = NSMakeSize(128, 128);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceChanged) name:QSInterfaceChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purgeOldImagesAndChildren) name:QSReleaseOldCachesNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanObjectDictionary) name:QSReleaseOldCachesNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purgeAllImagesAndChildren) name:QSReleaseAllCachesNotification object:nil];
        
        objectDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
        iconLoadedSet = [[NSMutableSet alloc] initWithCapacity:100];
        childLoadedSet = [[NSMutableSet alloc] initWithCapacity:100];
        
        [[NSImage imageNamed:@"Question"] createIconRepresentations];
        
        [[NSImage imageNamed:@"ContactAddress"] createRepresentationOfSize:NSMakeSize(16, 16)];
        [[NSImage imageNamed:@"ContactPhone"] createRepresentationOfSize:NSMakeSize(16, 16)];
        [[NSImage imageNamed:@"ContactEmail"] createRepresentationOfSize:NSMakeSize(16, 16)];
        
        [[NSImage imageNamed:@"defaultAction"] createIconRepresentations];
        QSObjectInitialized = YES;
	}   
}


+ (void)cleanObjectDictionary {
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    unsigned count = 0;
    QSObject *thisObject;
    for (NSString *thisKey in [objectDictionary allKeys]) {
        thisObject = [objectDictionary objectForKey:thisKey];
        if ([thisObject retainCount] < 2) {
            count++;
            [keysToRemove addObject:thisKey];
        }
		//QSLog(@"%d %@", [thisObject retainCount] , [thisObject name]);
    }
    
    for (NSString *thisKey in keysToRemove)
        [objectDictionary removeObjectForKey:thisKey];
    
    [keysToRemove release];
    
    if (DEBUG_MEMORY && count) 
		QSLog(@"Released %i objects", count);
}

+ (void)purgeOldImagesAndChildren {[self purgeImagesAndChildrenOlderThan:1.0];}
+ (void)purgeAllImagesAndChildren {[self purgeImagesAndChildrenOlderThan:0.0];}
+ (void)purgeImagesAndChildrenOlderThan:(NSTimeInterval)interval {
    
    unsigned imagecount = 0;
    unsigned childcount = 0;
    
    for (QSObject *thisObject in [[iconLoadedSet mutableCopy] autorelease]) {
		//	QSLog(@"i%@ %f", thisObject, thisObject->lastAccess);
        if (thisObject->lastAccess && thisObject->lastAccess < (globalLastAccess - interval) ) {
            if ([thisObject unloadIcon])
                imagecount++;
        }
    }
    
    for (QSObject *thisObject in [[childLoadedSet mutableCopy] autorelease]) {
        if (thisObject->lastAccess && thisObject->lastAccess < (globalLastAccess - interval)) {
            if ([thisObject unloadChildren]) childcount++;
        }
    }
    
    if (DEBUG_MEMORY && (imagecount || childcount) ) 
		QSLog(@"Released %i images and %i children  (items before %d) ", imagecount, childcount, (int)interval);
    
}

+ (void)interfaceChanged {
    QSMaxIconSize = [(QSInterfaceController *)[[NSApp delegate] interfaceController] maxIconSize];
	[self purgeAllImagesAndChildren];
}

+ (void)purgeIdentifiers {[objectDictionary removeAllObjects];}

+ (id)objectWithName:(NSString *)aName {
    QSObject *newObject = [[[QSObject alloc] init] autorelease];
    [newObject setName:aName];
    return newObject;
}

+ (void)registerObject:(QSBasicObject *)object withIdentifier:(NSString *)anIdentifier {
    if (object && anIdentifier)
        [objectDictionary setObject:object forKey:anIdentifier];
}

+ (id)makeObjectWithIdentifier:(NSString *)anIdentifier {
	id object = [self objectWithIdentifier:anIdentifier];
	
	if (!object) {
		object = [[[self alloc] init] autorelease];
		[object setIdentifier:anIdentifier];
	}
    return object;
}

+ (id)objectWithIdentifier:(NSString *)anIdentifier {
    return [objectDictionary objectForKey:anIdentifier];
}

- (id)init {
    if ((self = [super init]) ) {
		data = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
        meta = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
        name = nil;
        label = nil;
		icon = nil;
        identifier = nil;
        primaryType = nil;
        lastAccess = 0;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary{
    if (!dictionary) {
		[self release];
		return nil;
	}
    
	if ((self = [self init])) {
        [data setDictionary:[dictionary objectForKey:kData]];
        [meta setDictionary:[dictionary objectForKey:kMeta]];
		[self extractMetadata];
		
		id dup = [self findDuplicateOrRegisterID];
		if (dup) return dup;
/*		if ([self containsType:QSFilePathType])
			[self changeFilesToPaths];*/
	}
    return self;
}

- (void)dealloc {
	[self unloadIcon];
	[self unloadChildren];
    [data release];
    [meta release];
    [cache release];
	
    [name release];
    [label release];  
    [identifier release];
	[icon release];
    [primaryType release];
	[primaryObject release];  
	
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryRepresentation];
    [dict setObject:data forKey:kData];
    [dict setObject:meta forKey:kMeta];
    return dict;
}

- (void)extractMetadata {
	if ([data objectForKey:kQSObjectPrimaryName])
		[self setName:[data objectForKey:kQSObjectPrimaryName]];
	if ([data objectForKey:kQSObjectAlternateName])
		[self setLabel:[data objectForKey:kQSObjectAlternateName]];
	if ([data objectForKey:kQSObjectPrimaryType])
		[self setPrimaryType:[data objectForKey:kQSObjectPrimaryType]];
	if ([data objectForKey:kQSObjectIcon]) {
		id iconRef = [data objectForKey:kQSObjectIcon];
		if ([iconRef isKindOfClass:[NSData class]])
			[self setIcon:[[[NSImage alloc] initWithData:iconRef] autorelease]];
		else if ([iconRef isKindOfClass:[NSString class]])
			[self setIcon:[QSResourceManager imageNamed:iconRef]];
		[self setIconLoaded:YES];
	}
	
	if ([meta objectForKey:kQSObjectObjectID])
		identifier = [[meta objectForKey:kQSObjectObjectID] retain];
	if ([meta objectForKey:kQSObjectPrimaryType])
		primaryType = [[meta objectForKey:kQSObjectPrimaryType] retain];
	if ([meta objectForKey:kQSObjectPrimaryName])
		name = [[meta objectForKey:kQSObjectPrimaryName] retain];
	if ([meta objectForKey:kQSObjectAlternateName])
		label = [[meta objectForKey:kQSObjectAlternateName] retain];
    
	[data removeObjectForKey:QSProcessType]; // Don't carry over process info
}

- (id)findDuplicateOrRegisterID
{
	id dup = [QSObject objectWithIdentifier:[self identifier]];
	if (dup) {
		[self release];
		return [dup retain];
	}
    if ([self identifier]) {
		[QSObject registerObject:self withIdentifier:[self identifier]];
    }
	return nil;
}

- (BOOL)isEqual:(id)anObject {
    if (self != anObject && [anObject isKindOfClass:[QSRankedObject class]]) {
        anObject = [anObject object];
    }
    
	if (self == anObject) return YES;
    if (![[self identifier] isEqualToString:[anObject identifier]]) return NO;
    if ([self primaryObject])
        return [[self primaryObject] isEqual:[anObject primaryObject]];
    NSEnumerator *typesEnumerator = [data keyEnumerator];
    NSString *key;
    while((key = [typesEnumerator nextObject]) ) {
        if (![[data objectForKey:key] isEqual:[anObject objectForType:key]]) return NO;
    }
    return YES;
}

- (NSArray *)splitObjects {
	NSDictionary *dataDict = [self dataDictionary];
	
	NSEnumerator *ke = [dataDict keyEnumerator];
	NSString *key;
	NSArray *value;
    
	int i;
	
	NSMutableArray *splitObjects = [NSMutableArray array];
	
	while((key = [ke nextObject]) ) {
		value = [dataDict objectForKey:key];
		if ([value isKindOfClass:[NSArray class]]) {
			while([splitObjects count] <[value count])
				[splitObjects addObject:[QSObject objectWithName:[self name]]];
			for (i = 0; i<[value count]; i++) {
				[[splitObjects objectAtIndex:i] setObject:[value objectAtIndex:i] forType:key];
			}
		} else {
		}
	}
	return splitObjects;
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level {
    return [data descriptionWithLocale:locale indent:level];
}

- (id)handler {
    return [[QSReg objectHandlers] objectForKey:[self primaryType]];
}

- (id)handlerForType:(NSString *)type selector:(SEL)selector {
	id handler = [[QSReg objectHandlers] objectForKey:type];
    if (!selector || [handler respondsToSelector:selector])
        return handler;
    
	return nil;
}

- (id)handlerForSelector:(SEL)selector {
    id handler = [self handler];
    if (selector && [handler respondsToSelector:selector])
        return handler;
        
    return nil;
}

- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped {
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(drawIconForObject:inRect:flipped:)]) {
		return [handler drawIconForObject:self inRect:rect flipped:flipped];
    }
	return NO;
}

- (id)primaryObject {
    return [self objectForType:[self primaryType]];
}

- (id)_safeObjectForType:(id)aKey {
	return [data objectForKey:aKey];
/*	if (flags.multiTyped) 
		return [data objectForKey:aKey];  
	else if ([[self primaryType] isEqualToString:aKey]) 
		return data;
	return nil;*/
}

- (id)objectForType:(id)aKey {
	id object = [self _safeObjectForType:aKey];
	if ([object isKindOfClass:[NSArray class]] && [object count] == 1) {
            return [object lastObject];
	}
	return object;
}

- (NSArray *)arrayForType:(id)aKey {
	id object = [self _safeObjectForType:aKey];
	if (!object)
        return nil;
	if ([object isKindOfClass:[NSArray class]])
        return object;
	else
        return [NSArray arrayWithObject:object];
}

- (void)setObject:(id)object forType:(id)aKey {
	if (object)
        [data setObject:object forKey:aKey];
	else
        [data removeObjectForKey:aKey];
}

- (id)objectForCache:(id)aKey {
    return [cache objectForKey:aKey];
}

- (void)setObject:(id)object forCache:(id)aKey {
    if (object)
        [[self cache] setObject:object forKey:aKey];
}

- (id)objectForMeta:(id)aKey {
    return [meta objectForKey:aKey];
}

- (void)setObject:(id)object forMeta:(id)aKey {
    if (object)
        [meta setObject:object forKey:aKey];
}

- (NSMutableDictionary *)cache {
	if (!cache) [self setCache:[NSMutableDictionary dictionaryWithCapacity:1]];
	return cache; 	
}

- (void)setCache:(NSMutableDictionary *)aCache {
    if (cache != aCache) {
        [cache release];
        cache = [aCache retain];
    }
}

- (NSArray *)allKeys { return [data allKeys]; }

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([data respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:data];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

- (NSString *)guessPrimaryType {
	NSArray *allKeys = [data allKeys];
	if ([[data allKeys] containsObject:QSFilePathType])
        return QSFilePathType;
	else if ([allKeys containsObject:QSURLType])
        return QSURLType;
	else if ([allKeys containsObject:QSTextType])
        return QSTextType;
	else if ([allKeys containsObject:NSColorPboardType])
        return NSColorPboardType;
	
	if ([allKeys count] == 1)
        return [allKeys lastObject];
	
	return nil;
}

- (BOOL)loadIcon {
    if ([self iconLoaded])
        return NO;
    [self setIconLoaded:YES];
	
	lastAccess = [NSDate timeIntervalSinceReferenceDate];
	globalLastAccess = lastAccess;
    [iconLoadedSet addObject:self];
	
	NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
	if (namedIcon) {
		NSImage *image = [QSResourceManager imageNamed:namedIcon];
		if (image) {
			[self setIcon:image];
			return YES;
		}
	}
	
	NSString *bestType = [self primaryType];
    
    id handler = [[QSReg objectHandlers] objectForKey:bestType];
    if ([handler respondsToSelector:@selector(loadIconForObject:)])
        return [handler loadIconForObject:self];
    
    //// if ([primaryType hasPrefix:@"QSCsontact"])
    //     return NO;
    
	if ([IMAGETYPES intersectsSet:[NSSet setWithArray:[data allKeys]]]) {
        [self setIcon:[[[NSImage alloc] initWithPasteboard:(NSPasteboard *)self] autorelease]];
		[[self icon] createIconRepresentations];
		[[self icon] createRepresentationOfSize:NSMakeSize(128, 128)];
    }
    
    // file type for sound clipping: clps
    if (![self icon]) {
        [self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
        return NO;
    }
    
    return NO;
}

- (BOOL)unloadIcon {
    if (![self iconLoaded]) return NO;
	if ([self retainsIcon]) return NO;
	
	[self setIcon:nil];
	[self setIconLoaded:NO];
	[iconLoadedSet removeObject:self];
    return YES;
}

@synthesize icon;
- (NSImage *)icon {
    lastAccess = [NSDate timeIntervalSinceReferenceDate];
    globalLastAccess = lastAccess;
	
	if (icon)
        return icon;
    
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(setQuickIconForObject:)])
		[handler setQuickIconForObject:self];
	else if ([[self primaryType] isEqualToString:QSContactPhoneType])
        [self setIcon: [NSImage imageNamed:@"ContactPhone"]];
    else if ([[self primaryType] isEqualToString:QSContactAddressType])
        [self setIcon: [NSImage imageNamed:@"ContactAddress"]];
    //else if ([[self primaryType] isEqualToString:QSContactEmailType])
    //  [self setIcon: [NSImage imageNamed:@"ContactEmail"]];
    else if ([[self types] containsObject:@"BookmarkDictionaryListPboardType"])
        [self setIcon:[NSImage imageNamed:@"FadedDefaultBookmarkIcon"]];
    else    
        [self setIcon:[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"]];
    
	if (icon)
        return icon;
	return nil;
}


- (void)setIcon:(NSImage *)newIcon {
	//	if (newIcon) {
	[icon autorelease];
	icon = [newIcon retain];
	[icon setScalesWhenResized:YES];
	[icon setCacheMode:NSImageCacheNever];
	
	//[[self cache] setObject:newIcon forKey:kQSObjectIcon];
	//	} else {
	//[[self cache] removeObjectForKey:kQSObjectIcon];
	//	}
	
}

- (NSArray *)types {
    return [[[data allKeys] mutableCopy] autorelease];
}

- (NSArray *)decodedTypes {
    NSMutableArray *decodedTypes = [NSMutableArray arrayWithCapacity:[data count]];
    NSEnumerator *typesEnumerator = [data keyEnumerator];
    NSString *thisType;
    while((thisType = [typesEnumerator nextObject]) ) {
        [decodedTypes addObject:[thisType decodedPasteboardType]];
    }
    return decodedTypes;
}

@end

@implementation QSObject (Hierarchy)

- (QSBasicObject *)parent {
    QSBasicObject * parent = nil;
    
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(parentOfObject:)])
        parent = [handler parentOfObject:self];
    
    
    if (!parent)
        parent = [objectDictionary objectForKey:[meta objectForKey:kQSObjectParentID]];
    return parent;
}

- (BOOL)hasChildren {
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(objectHasChildren:)])
        return [handler objectHasChildren:self];
    return NO;
}

- (void)setParentID:(NSString *)parentID {
    if (parentID)
        [data setObject:parentID forKey:kQSObjectParentID];  
}

- (BOOL)childrenValid {
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(objectHasValidChildren:)])
        return [handler objectHasValidChildren:self];
    
    //B80
    if ([NSDate timeIntervalSinceReferenceDate] - [self childrenLoadedDate] < 5)
        return YES;
    
    return NO;
}

- (void)loadChildren {
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(loadChildrenForObject:)]) {
		
        if ([handler loadChildrenForObject:self]) {
            
		}
    }
    
    NSArray *components = [self objectForCache:kQSObjectComponents];
    if (components)
        [self setChildren:components];
	
}

- (BOOL)unloadChildren {
	//QSLog(@"unload children of %@", self);
	
    if (![self childrenLoaded])
        return NO;
	//QSLog(@"unloaded %@ %x", self, self);
    [self setChildren:nil];
    [self setAltChildren:nil];
    flags.childrenLoaded = NO;
    [self setChildrenLoadedDate:0];
	[childLoadedSet removeObject:self];
    return YES;
}

- (NSArray *)children {
    //QSLog(@"load for %@ %d %d", self, !flags.childrenLoaded, ![self childrenValid]);
    if (!flags.childrenLoaded || ![self childrenValid])
        [self loadChildren];
	
	return [cache objectForKey:kQSObjectChildren];
}

- (void)setChildren:(NSArray *)newChildren {
	if (newChildren) {
        [[self cache] setObject:newChildren forKey:kQSObjectChildren];
        flags.childrenLoaded = YES;
        [self setChildrenLoadedDate:[NSDate timeIntervalSinceReferenceDate]];
        lastAccess = [NSDate timeIntervalSinceReferenceDate];
        globalLastAccess = lastAccess;
        //QSLog(@"Children loaded for %@", self);
        [childLoadedSet addObject:self];
    }
}

- (NSArray *)altChildren {
	if (!flags.childrenLoaded || ![self childrenValid])
        [self loadChildren];
	return [cache objectForKey:kQSObjectAltChildren];
}

- (void)setAltChildren:(NSArray *)newAltChildren {
	if (newAltChildren)
		[[self cache] setObject:newAltChildren forKey:kQSObjectAltChildren];
}

- (BOOL)childrenLoaded { return flags.childrenLoaded;  }
- (void)setChildrenLoaded:(BOOL)flag { flags.childrenLoaded = flag; }

@end

//Standard Accessors

@implementation QSObject (Accessors)

- (NSString *)identifier {
    if (identifier)
        return identifier;
	if (flags.noIdentifier)
		return nil;
	
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(identifierForObject:)]) {
        [self setIdentifier:[handler identifierForObject:self]];
    }
    if (!identifier)
        flags.noIdentifier = YES;
	
    return identifier;
}

- (void)setIdentifier:(NSString *)newIdentifier {
    [identifier release];
	if (identifier) {
		[objectDictionary removeObjectForKey:identifier];
		[objectDictionary setObject:self forKey:newIdentifier];
	}
	identifier = [newIdentifier retain];
    if (newIdentifier)
        [meta setObject:newIdentifier forKey:kQSObjectObjectID];
}

- (NSString *)name {
	if (!name)
        name = [[meta objectForKey:kQSObjectPrimaryName] retain];
	return name;
}

- (void)setName:(NSString *)newName {
    [name release];
    if ([newName length] > 255) newName = [newName substringToIndex:255];  
	// ***warning   ** this should take first line only?
	
	name = [newName retain];
	if (newName) [meta setObject:newName forKey:kQSObjectPrimaryName];
}

- (void)setDetails:(NSString *)newDetails {
	[self setObject:newDetails forMeta:kQSObjectDetails];
}

- (NSString *)details {
	NSString *details = [meta objectForKey:kQSObjectDetails];
    if (details)
        return details;
    
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(detailsOfObject:)]) {
		details = [handler detailsOfObject:self];
		if (details) [meta setObject:details forKey:kQSObjectDetails];
		return details;
    }
    
    if ([[self objectForType:[self primaryType]] isKindOfClass:[NSString class]])
        return [self objectForType:[self primaryType]];
    
    return nil;
}

- (NSString *)label {
    if (!label)
        label = [[meta objectForKey:kQSObjectAlternateName] retain];
	return label;
}

- (void)setLabel:(NSString *)newLabel {
	if (![newLabel isEqualToString:[self name]]) {
		[label release];
		label = [newLabel retain];
		if (newLabel)
            [meta setObject:newLabel forKey:kQSObjectAlternateName];
		else
            [meta removeObjectForKey:kQSObjectAlternateName];
	} 		    
}

- (NSString *)kind {
	NSString *kind = [meta objectForKey:kQSObjectKind];
    if (kind) return kind;
    
    id handler = [[QSReg objectHandlers] objectForKey:[self primaryType]];
    if ([handler respondsToSelector:@selector(kindOfObject:)]) {
		kind = [handler kindOfObject:self];
		if (kind) {
			[meta setObject:kind forKey:kQSObjectKind];
			return kind;
		}
    }
	
	return [self primaryType];
}

- (NSString *)primaryType {
    if (!primaryType)
		primaryType = [[self guessPrimaryType] retain];
	return primaryType;
}

- (void)setPrimaryType:(NSString *)newPrimaryType {
    [primaryType release];
    primaryType = [newPrimaryType retain];
	[meta setObject:newPrimaryType forKey:kQSObjectPrimaryType];
}

- (NSMutableDictionary *)dataDictionary { return data; }

- (void)setDataDictionary:(NSMutableDictionary *)newDataDictionary {
    [data autorelease];
    data = [newDataDictionary retain];
}

- (BOOL)iconLoaded { return flags.iconLoaded;  }
- (void)setIconLoaded:(BOOL)flag { flags.iconLoaded = flag; }

- (BOOL)retainsIcon  { return flags.retainsIcon;  } ;
- (void)setRetainsIcon:(BOOL)flag {	flags.retainsIcon = (flag > 0); }

- (BOOL)contentsLoaded { return flags.contentsLoaded;  }
- (void)setContentsLoaded:(BOOL)flag { flags.contentsLoaded = flag; }

- (NSTimeInterval) childrenLoadedDate { return [[meta objectForKey:kQSObjectChildrenLoadDate] doubleValue];  }
- (void)setChildrenLoadedDate:(NSTimeInterval)newChildrenLoadedDate {
	[meta setObject:[NSNumber numberWithDouble:newChildrenLoadedDate] forKey:kQSObjectChildrenLoadDate];
}


- (NSTimeInterval) lastAccess { return lastAccess;  }
- (void)setlastAccess:(NSTimeInterval)newlastAccess {
    lastAccess = newlastAccess;
}
@end



@implementation QSObject (Archiving)

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
	
	[meta setDictionary:[coder decodeObjectForKey:@"meta"]];
    [data setDictionary:[coder decodeObjectForKey:@"data"]];
	[self extractMetadata];
	id dup = [self findDuplicateOrRegisterID];
	if (dup) return dup;
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:meta forKey:@"meta"];
    [coder encodeObject:data forKey:@"data"];
}

@end
