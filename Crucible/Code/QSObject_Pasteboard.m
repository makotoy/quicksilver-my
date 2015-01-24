/* Derived from Blacktree, Inc. codebase
 * 2010-01-03 Makoto Yamashita.
 */

#import "QSObject_Pasteboard.h"
#import "QSTypes.h"

#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"

#define QS_OBJ_ADDR_KEY @"QSObjectAddress"
#define QS_OBJ_ID_KEY @"QSObjectID"

id objectForPasteboardType(NSPasteboard *pasteboard, NSString *type) {
    if ([PLISTTYPES containsObject:type]) {
        return [pasteboard propertyListForType:type];
    } else if ([NSStringPboardType isEqualToString:type] || [type hasPrefix:@"QSObject"]) {
        return [pasteboard stringForType:type];
    } else if ([NSURLPboardType isEqualToString:type]) {
        return [[NSURL URLFromPasteboard:pasteboard] absoluteString];
    }
    // TODO: else if ([NSFileContentsPboardType isEqualToString:type]);
	// TODO: else if ([NSColorPboardType isEqualToString:type]);
    return [pasteboard dataForType:type];
}

BOOL writeObjectToPasteboard(NSPasteboard *pasteboard, NSString *type, id data) {
    if ([NSURLPboardType isEqualToString:type]) {
        [[NSURL URLWithString:data] writeToPasteboard:pasteboard];
		[pasteboard addTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];		
        [pasteboard setString:(![data hasPrefix:@"mailto:"] ? data : [data substringFromIndex:7])
                      forType:NSStringPboardType];
    } else if ([PLISTTYPES containsObject:type] || [data isKindOfClass:[NSDictionary class]]
               || [data isKindOfClass:[NSArray class]]) {
        [pasteboard setPropertyList:data forType:type];
    } else if ([data isKindOfClass:[NSString class]]) {
        [pasteboard setString:data forType:type];
    } else {
        [pasteboard setData:data forType:type];
    }
    // TODO: else if ([NSColorPboardType isEqualToString:type]);
    // TODO: else if ([NSFileContentsPboardType isEqualToString:type]);
    return YES;
}


@implementation QSObject (Pasteboard)
+ (id)objectWithPasteboard:(NSPasteboard *)pasteboard
{
    if ([[pasteboard types] containsObject:QSPrivatePboardType]
        || [[pasteboard types] containsObject:@"de.petermaurer.TransientPasteboardType"]) {
        return nil;
    }
    if ([[pasteboard types] containsObject:QS_OBJ_ID_KEY]) {
        return [QSObject objectWithIdentifier:[pasteboard stringForType:QS_OBJ_ID_KEY]];
    }
    if ([[pasteboard types] containsObject:QS_OBJ_ADDR_KEY]) {
        NSArray *objectIdentifier = [[pasteboard stringForType:QS_OBJ_ADDR_KEY] componentsSeparatedByString:@":"];
        int objProcId = [[objectIdentifier objectAtIndex:0] intValue];
        int thisProcId = [[NSProcessInfo processInfo] processIdentifier];
        if (objProcId == thisProcId) {
            return (QSObject *)[[objectIdentifier lastObject] integerValue];
        } else if (VERBOSE) {
            QSLog(@"Ignored old object: %@", objectIdentifier);
        }
    }    
    return [[[QSObject alloc] initWithPasteboard:pasteboard] autorelease];
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
    return [self initWithPasteboard:pasteboard types:nil];
}

- (void)addContentsOfClipping:(NSString *)path
{
    // text clipping uses deprecated Carbon
}

- (void)addContentsOfPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types
{
    NSArray *typeCands = (types ? types : [pasteboard types]);
    NSMutableArray *typeArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *ignoreTypes = [NSArray arrayWithObjects:QS_OBJ_ADDR_KEY, @"CorePasteboardFlavorType 0x4D555246", @"CorePasteboardFlavorType 0x54455854", nil];
    for  (NSString *thisType in typeCands) {
        if ([[pasteboard types] containsObject:thisType] && ![ignoreTypes containsObject:thisType]) {
            id theObject = objectForPasteboardType(pasteboard, thisType);
            if (theObject && thisType) [self setObject:theObject forType:thisType];  
			// ***warning   * change these to use decodedPasteboardType
            else QSLog(@"bad data for %@", thisType);
            [typeArray addObject:[thisType decodedPasteboardType]];
        }
    }
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types
{
    if ((self = [self init])) {
        if (!types) {
            types = [pasteboard types];
        }
		NSString *source = @"Clipboard";
		if (pasteboard == [NSPasteboard generalPasteboard])
			source = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"];
		
		if ([source isEqualToString: @"com.microsoft.RDC"]) {
			QSLog(@"Ignoring RDC Clipboard");
			[self release];
			return nil;
		} else if (VERBOSE) {
			//QSLog(@"Clipsource:%@", source);
		}
		
        [self setDataDictionary:[NSMutableDictionary dictionaryWithCapacity:[[pasteboard types] count]]];
        [self addContentsOfPasteboard:pasteboard types:types];
		
		[self setObject:source forMeta:kQSObjectSource];
        [self setObject:[NSDate date] forMeta:kQSObjectCreationDate];
        
        // if (VERBOSE) QSLog(@"Created object with types:\r%@", [typeArray componentsJoinedByString:@", "]);
        id value;
		if ((value = [self objectForType:NSRTFPboardType])) {
            NSAttributedString* aStr = [[NSAttributedString alloc] initWithRTF:value documentAttributes:nil];
			value = [aStr string];
            [aStr autorelease];
			[self setObject:value forType:QSTextType];
		}
        if ([self objectForType:QSTextType]) {
			[self sniffString]; 	
		}
        if ([self objectForType:kQSObjectPrimaryName]) {
            [self setName:[self objectForType:kQSObjectPrimaryName]];
        } else {
            [self setName:@"Unknown Clipboard Object"];
            [self guessName];
        }
        [self loadIcon];
    }
    return self;
}

- (void)guessName
{
    NSString * newName = nil;
    //QSLog(@"webtitl %@", [pasteboard propertyListForType:@"WebURLsWithTitlesPboardType"]);
    if ([self objectForType:NSFilenamesPboardType]) {
        [self setPrimaryType:NSFilenamesPboardType];
        [self getNameFromFiles];
    } else if ([self objectForType:NSStringPboardType]) {
        newName = [[self objectForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self setName:newName];
    } else {
        if ([self objectForType:NSPDFPboardType])
            newName = @"PDF Image";
        else if ([self objectForType:[@"'icns'" encodedPasteboardType]])
            newName = @"Finder Icon";
        else if ([self objectForType:NSPostScriptPboardType])
            newName = @"PostScript Image";
        else if ([self objectForType:NSTIFFPboardType])
            newName = @"TIFF Image";  
        else if ([self objectForType:NSColorPboardType])
            newName = @"Color Data";
        else if ([self objectForType:NSFileContentsPboardType])
            newName = @"File Contents";
        else if ([self objectForType:NSFontPboardType])
            newName = @"Font Information";
        else if ([self objectForType:NSHTMLPboardType])
            newName = @"HTML Data";
        else if ([self objectForType:NSRulerPboardType])
            newName = @"Paragraph formatting";
        else if ([self objectForType:NSHTMLPboardType])
            newName = @"HTML Data";
        else if ([self objectForType:NSTabularTextPboardType])
            newName = @"Tabular Text";
        else if ([self objectForType:NSVCardPboardType])
            newName = @"VCard data";
        else if ([self objectForType:NSFilesPromisePboardType])
            newName = @"Promised Files";  
        
        NSString *source = [self objectForMeta:kQSObjectSource];
        if (source) {
            NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:source];
            NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:path];
            if (!appName) appName = source;
            newName = [newName stringByAppendingFormat: @" - %@", appName];
        }
        [self setName:newName];
    }    
    /*
     TODO
     
     NSRTFPboardType
     Rich Text Format (RTF)
     
     NSRTFDPboardType
     RTFD formatted file contents
     
     NSStringPboardType
     NSString data
     */
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes
{
    if (!types) {
        types = [[[[self dataDictionary] allKeys] mutableCopy] autorelease];
    
	// ***warning   * should only include available types
    } else {
        NSMutableSet *typeSet = [NSMutableSet setWithArray:types];
        [typeSet intersectSet:[NSSet setWithArray:[[self dataDictionary] allKeys]]];
        types = [[[typeSet allObjects] mutableCopy] autorelease];
    }    
    if (!includeTypes && [types containsObject:NSFilenamesPboardType]) {
		includeTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
		[pboard declareTypes:includeTypes owner:self];
	} else if (!includeTypes && [types containsObject:NSURLPboardType]) {
            includeTypes = [NSArray arrayWithObject:NSURLPboardType];
    }
	[pboard declareTypes:types owner:self];
    /*
     
	 // ***warning   ** Should add additional information for file items     if ([paths count] == 1) {
     [[self data] setObject:[[NSURL fileURLWithPath:[paths lastObject]]absoluteString] forKey:NSURLPboardType];  
     [[self data] setObject:[paths lastObject] forKey:NSStringPboardType];  
     }
     
     */
    for (NSString *thisType in includeTypes) {
        if ([types containsObject:thisType]) {
			// QSLog(@"includedata, %@", thisType);
            [self pasteboard:pboard provideDataForType:thisType];
        }
    }
    if ([self identifier]) {
        [pboard addTypes:[NSArray arrayWithObject:QS_OBJ_ID_KEY] owner:self];
        writeObjectToPasteboard(pboard, QS_OBJ_ID_KEY, [self identifier]);
    }
	
    [pboard addTypes:[NSArray arrayWithObject:QS_OBJ_ADDR_KEY] owner:self];
	//   QSLog(@"types %@", [pboard types]);
    return YES;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type {
    //if (VERBOSE) QSLog(@"Provide: %@", [type decodedPasteboardType]);
    if ([type isEqualToString:QS_OBJ_ADDR_KEY]) {
        writeObjectToPasteboard(sender, type, [NSString stringWithFormat:@"%d:%ld", [[NSProcessInfo processInfo] processIdentifier] , (long int)self]);
	} else {
		id theData = nil;
		id handler = [self handlerForType:type selector:@selector(dataForObject:pasteboardType:)];
		if (handler)
			theData = [handler dataForObject:self pasteboardType:type];
		if (!theData)
			theData = [self objectForType:type];
		if (theData) writeObjectToPasteboard(sender, type, theData);
	} 	
}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender {
    //if (sender == [NSPasteboard generalPasteboard] && VERBOSE)
	//   QSLog(@"%@ Lost the Pasteboard: %@", self, sender);
}

- (NSData *)dataForType:(NSString *)dataType {
    id theData = [data objectForKey:dataType];
    if ([theData isKindOfClass:[NSData class]]) return theData;
    return nil;
}
@end
