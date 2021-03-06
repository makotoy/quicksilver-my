/*
 Copyright 2007 Blacktree, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 
  Derived from Blacktree codebase
  2009-11-30 Makoto Yamashita
*/

#import "QSFileSystemObjectHandler.h"

static NSDictionary *bundlePresetChildren = nil;

NSArray *recentDocumentsForBundle(NSString *bundleIdentifier) {
    return [NSArray array];
}


@implementation QSFileSystemObjectHandler
// Object Handler Methods
- (id)init {
	self = [super init];
	if (self != nil) {
		applicationIcons = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (NSMutableDictionary *)applicationIcons {
	return applicationIcons; 	
}

- (QSObject *)parentOfObject:(QSObject *)object {
    
    QSObject * parent = nil;
    
    if ([object singleFilePath]) {
        if ([[object singleFilePath] isEqualToString:@"/"]) parent = [QSComputerProxy sharedInstance];
        else parent = [QSObject fileObjectWithPath:[[object singleFilePath] stringByDeletingLastPathComponent]];
    }
    return parent;
}

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type {
	return [object arrayForType:type]; 	
	return nil;
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	if (NSWidth(rect) <= 32) return NO;
	NSString *path = [object singleFilePath];
	
	
	//icon
	//	cache? - use
	//	loader? 
	//	
	//	
	if (0 && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication) {
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			
			NSString *handlerName = [[QSReg elementsByIDForPointID:@"QSBundleDrawingHandlers"] objectForKey:bundleIdentifier];
			if (handlerName) {
				id handler = [QSReg getClassInstance:handlerName];
				if (handler) {
					if ([handler respondsToSelector:@selector(drawIconForObject:inRect:flipped:)])
						return [handler drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped];
					return NO;
				}
			}
		}
	}
	
	return NO;
    //	if (!path || [[path pathExtension] caseInsensitiveCompare:@"prefpane"] != NSOrderedSame) return NO;
    //	
    //	NSImage *image = [NSImage imageNamed:@"PrefPaneTemplate"];
    //	
    //	[image setSize:[[image bestRepresentationForSize:rect.size] size]];
    //	//[image adjustSizeToDrawAtSize:rect.size];
    //	[image setFlipped:flipped];
    //	[image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0f];
    //	
    //	if ([object iconLoaded]) {
    //		NSImage *cornerBadge = [object icon];
    //		if (cornerBadge != image) {
    //			[cornerBadge setFlipped:flipped];  
    //			
    //			NSRect badgeRect = NSMakeRect(16+48+rect.origin.x, 16+36+rect.origin.y, 32, 32);
    //			NSImageRep *bestBadgeRep = [cornerBadge bestRepresentationForSize:badgeRect.size];  
    //			
    //			[cornerBadge setSize:[bestBadgeRep size]];
    //			
    //			[[NSColor colorWithDeviceWhite:1.0 alpha:0.8] set];
    //			//NSRectFillUsingOperation(NSInsetRect(badgeRect, -14, -14), NSCompositeSourceOver);
    //			NSBezierPath *path = [NSBezierPath bezierPath];
    //			[path appendBezierPathWithRoundedRectangle:NSInsetRect(badgeRect, -10, -10) withRadius:4];
    //			
    //			
    //			[[NSColor colorWithDeviceWhite:1.0 alpha:1.0] setFill];
    //			[[NSColor colorWithDeviceWhite:0.75 alpha:1.0] setStroke];
    //			[path fill];
    //			[path stroke];
    //			
    //			NSFrameRectWithWidth(NSInsetRect(badgeRect, -5, -5), 2);
    //			
    //			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    //			[cornerBadge drawInRect:badgeRect fromRect:rectFromSize([cornerBadge size]) operation:NSCompositeSourceOver fraction:1.0];
    //			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    //			
    //		}
    //	}
    //	return YES;
    //	
	
}

- (NSString *)kindOfObject:(QSObject *)object {
	NSString *path = [object singleFilePath];
	LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
	if (infoRec.flags & kLSItemInfoIsApplication) {
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication) {
			return @"QSKindApplication";
		}
	}
	
	return nil; 	
}

- (NSString *)detailsOfObject:(id <QSObject>)object {
    NSArray *theFiles = [object arrayForType:QSFilePathType];
	if ([theFiles count] == 1) {
		NSString *path = [theFiles lastObject];
		
		NSFileManager *manager = [NSFileManager defaultManager];
        
		if (QSIsLocalized) {
			return [[manager componentsToDisplayForPath:path] componentsJoinedByString:@":"];
		} else if ([path hasPrefix:NSTemporaryDirectory()]) {
			return [@"(Quicksilver) " stringByAppendingPathComponent:[path lastPathComponent]];
		} else {
			return [path stringByAbbreviatingWithTildeInPath];
		}
	}
	else  if ([theFiles count] >1) {
		return [[theFiles arrayByPerformingSelector:@selector(lastPathComponent)] componentsJoinedByString:@", "];
	}
	return nil;
}

- (void)setQuickIconForObject:(QSObject *)object {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [object singleFilePath];
    BOOL isDirectory;
    [manager fileExistsAtPath:path isDirectory:&isDirectory];
    if (isDirectory) {
        if ([[path pathExtension] isEqualToString:@"app"] || [[NSArray arrayWithObjects:@"'APPL'", nil] containsObject: NSHFSTypeOfFile(path)])
            [object setIcon:[QSResourceManager imageNamed:@"GenericApplicationIcon"]];
        else
            [object setIcon:[QSResourceManager imageNamed:@"GenericFolderIcon"]];
    } else {
        [object setIcon:[QSResourceManager imageNamed:@"UnknownFSObjectIcon"]];
    }
}

- (BOOL)loadIconForObject:(QSObject *)object {
    NSImage *theImage = nil;
    NSArray *theFiles = [object arrayForType:QSFilePathType];
    if (!theFiles) return NO;
	NSFileManager *manager = [NSFileManager defaultManager];
    if ([theFiles count] == 1) {
        NSString *path = [theFiles lastObject];
        if ([manager fileExistsAtPath:path]) {
            LSItemInfoRecord infoRec;
            //OSStatus status=
            LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
			
            if (infoRec.flags & kLSItemInfoIsPackage) {
                //        NSBundle *bundle = [NSBundle bundleWithPath:firstFile];
                //        NSString *bundleImageName = nil;
                //if ([[firstFile pathExtension] isEqualToString:@"prefPane"]) {
                //          bundleImageName = [[bundle infoDictionary] objectForKey:@"NSPrefPaneIconFile"];
                //					
                //					if (!bundleImageName) bundleImageName = [[bundle infoDictionary] objectForKey:@"CFBundleIconFile"];
                //					if (bundleImageName) {
                //						NSString *bundleImagePath = [bundle pathForResource:bundleImageName ofType:nil];
                //						theImage = [[[NSImage alloc] initWithContentsOfFile:bundleImagePath] autorelease];
                //					}
                //				}
            }
            if (!theImage && 1) {
                theImage = [NSImage imageWithPreviewOfFileAtPath:path ofSize:NSMakeSize(512, 512) asIcon:YES];
                //        NSURL *fileURL = [NSURL fileURLWithPath:path];
                //        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger: 128] 
                //                                                            forKey:kQLThumbnailOptionIconModeKey];
                //        CGSize iconSize = {512.0, 512.0} ;
                //        
                //        QLThumbnailRef thumbnail = QLThumbnailCreate(NULL, (CFURLRef) fileURL, iconSize, (CFDictionaryRef)options);
                //        if (thumbnail) {
                //          CGImageRef cgImage = QLThumbnailCopyImage(thumbnail);
                //          if (cgImage) {
                //            NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithCGImage:cgImage] autorelease];
                //            theImage = [[[NSImage alloc] init] autorelease];
                //            [theImage addRepresentation:rep];
                //            CFRelease(cgImage);
                //          }
                //          CFRelease(thumbnail);
                //        }
                
            }
            if (!theImage && [[NSUserDefaults standardUserDefaults] boolForKey:@"QSLoadImagePreviews"]) {
                NSString *type = [manager typeOfFile:path];
                
                
                if ([[NSImage imageUnfilteredFileTypes] containsObject:type]) {
                    theImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
                } else {
                    id provider = [QSReg instanceForKey:type inTable:@"QSFSFileTypePreviewers"];
                    //QSLog(@"provider %@", [QSReg elementsForPointID:@"QSFSFileTypePreviewers"]);
                    theImage = [provider iconForFile:path ofType:type];
                }
            }
            if (!theImage)
                theImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
			
            
			// ***warning * This caused a crash?
        }
        
    } else {
		NSMutableSet *set = [NSMutableSet set];
		NSWorkspace *w = [NSWorkspace sharedWorkspace];
		NSString *theFile;
		for (theFile in theFiles) {
			NSString *type = [manager typeOfFile:theFile];
			
			[set addObject:type?type:@"'msng'"];
			
		}
		
		//QSLog(@"%@, set", set);
		if ([set containsObject:@"'fold'"]) {
			[set removeObject:@"'fold'"];
			[set addObject:@"'fldr'"];
			
			
		}
		if ([set count] == 1)
			theImage = [w iconForFileType:[set anyObject]];
		else
			theImage = [w iconForFiles:theFiles];
    }
    
    if (theImage) {
        [theImage createRepresentationOfSize:NSMakeSize(32, 32)];
		[theImage createRepresentationOfSize:NSMakeSize(16, 16)];
    }
    if (QSMaxIconSize.width<128) { 
		// ***warning * use this better
		//if (VERBOSE) QSLog(@"stripping maxsize for object %@", object);
        [theImage removeRepresentation:[theImage representationOfSize:NSMakeSize(128, 128)]];
        
    }
    //  QSLog(@"Reps for %@\r%@", [object name] , [theImage representations]);
    //[theImage setScalesWhenResized:YES];
    if (!theImage) theImage = [QSResourceManager imageNamed:@"GenericQuestionMarkIcon"];
    
    
    [object setIcon:theImage];
    return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object {
    if (!object) return NO;
    BOOL isDirectory;
	NSString *path = [object singleFilePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
		
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
		
        if (infoRec.flags & kLSItemInfoIsAliasFile) return YES;
		
		if (infoRec.flags & kLSItemInfoIsApplication) {
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			//CFBundleRef bundle = CFBundleCreate (NULL, (CFURLRef) [NSURL fileURLWithPath:path]);
			//NSString *bundleIdentifier = CFBundleGetIdentifier(bundle);
			
			if (!bundleIdentifier) return NO;
            BElement *handler = [QSReg elementForPointID:@"QSBundleChildHandlers"
                                                  withID:bundleIdentifier];
			if (handler) return YES;
			
			NSArray *recentDocuments = (NSArray *)CFPreferencesCopyValue((CFStringRef) @"NSRecentDocumentRecords", (CFStringRef) bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			[recentDocuments autorelease];
			if (recentDocuments) return YES;
		}
		
		return isDirectory && !(infoRec.flags & kLSItemInfoIsPackage);
	}
    return NO;
    
}

- (BOOL)objectHasValidChildren:(QSObject *)object
{
    if ([object fileCount] == 1) {
        NSString *path = [object singleFilePath];		
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication) {
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			
			id handler = [QSReg instanceForPointID:@"QSBundleChildHandlers" withID:bundleIdentifier];
			
			if (handler) {
				if ([handler respondsToSelector:@selector(objectHasValidChildren:)]) {
					return [handler objectHasValidChildren:object];
                }
                // TODO: This should return YES only if loaded in last 10 min or something
			}			
			return YES;
		}
        NSTimeInterval modDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL]
                                     fileModificationDate] timeIntervalSinceReferenceDate];
        if (modDate > [object childrenLoadedDate]) return NO;
    }
    return YES;    
}

- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>)sender ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject {
    if (![iObject arrayForType:QSFilePathType]) return NSDragOperationNone;
	if ([dObject fileCount] >1) return NSDragOperationGeneric;
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    if ([dObject isApplication]) {
		return NSDragOperationPrivate;
        if (sourceDragMask&NSDragOperationPrivate) return NSDragOperationPrivate;
    } else if ([dObject isFolder]) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSDragOperation defaultOp = [manager defaultDragOperationForMovingPaths:[dObject validPaths] toDestination:[(QSObject *)iObject singleFilePath]];
        if (defaultOp == NSDragOperationMove) {
            if (sourceDragMask&NSDragOperationMove) return NSDragOperationMove;
            if (sourceDragMask&NSDragOperationCopy) return NSDragOperationCopy;
        } else if  (defaultOp == NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return sourceDragMask&NSDragOperationGeneric;
}

- (NSString *)actionForDragMask:(NSDragOperation)operation ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject {
	if ([dObject fileCount] > 1) return nil;
    
    NSDragOperation sourceDragMask = operation;
    if ([dObject isApplication]) {
        //if (sourceDragMask&NSDragOperationPrivate)
		return  @"FileOpenWithAction";
    } else if ([dObject isFolder]) {
        //  NSFileManager *manager = [NSFileManager defaultManager];
        if (sourceDragMask&NSDragOperationMove)
            return @"FileMoveToAction";
        else if (sourceDragMask&NSDragOperationCopy)
            return @"FileCopyToAction";
    }
    return nil;
}

- (NSAppleEventDescriptor *)AEDescriptorForObject:(QSObject *)object {
	return [NSAppleEventDescriptor aliasListDescriptorWithArray:[object validPaths]];
}

- (NSString *)identifierForObject:(id <QSObject>)object {
    NSArray *paths = [object arrayForType:QSFilePathType];
    
    if ([paths count] == 1)
        return [[paths lastObject] stringByResolvingSymlinksInPath];
    return [paths componentsJoinedByString:@" "];
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
    NSArray *newChildren = nil;
    NSArray *newAltChildren = nil;
	
    if ([object fileCount] == 1) {
        NSString *path = [object singleFilePath];
        if (![path length]) return NO;
        BOOL isDirectory;
        NSFileManager *manager = [NSFileManager defaultManager];
        
        LSItemInfoRecord infoRec;
        LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestAllInfo, &infoRec);
        
        if (infoRec.flags & kLSItemInfoIsAliasFile) {
            path = [manager resolveAliasAtPath:path];
            if ([manager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory) {
                [object setChildren:[NSArray arrayWithObject:[QSObject fileObjectWithPath:path]]];
				return YES;
			}
        }
		NSMutableArray *fileChildren = [NSMutableArray arrayWithCapacity:1];
		NSMutableArray *visibleFileChildren = [NSMutableArray arrayWithCapacity:1];
		for (NSString* file in [manager contentsOfDirectoryAtPath:path error:NULL]) {
			file = [path stringByAppendingPathComponent:file];
			[fileChildren addObject:file];
			if ([manager isVisible:file]) [visibleFileChildren addObject:file];
		}		
		newChildren = [QSObject fileObjectsWithPathArray:visibleFileChildren];
		newAltChildren = [QSObject fileObjectsWithPathArray:fileChildren];
		
		if (newAltChildren) [object setAltChildren:newAltChildren];
		
		if (infoRec.flags & kLSItemInfoIsApplication) {
			// ***warning * omit other types of bundles
			//newChildren = nil;
			
			NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
			id handler = [QSReg instanceForPointID:@"QSBundleChildHandlers" withID:bundleIdentifier];
			
			if (handler) {
				return [handler loadChildrenForObject:object];
			} else {
				if (!bundlePresetChildren) {
                    QSLog(@"preset load");
					bundlePresetChildren = [[QSReg elementsByIDForPointID:@"QSBundleChildPresets"] retain];
					//[[NSDictionary dictionaryWithContentsOfFile:
					//	[[NSBundle mainBundle] pathForResource:@"BundleChildPresets" ofType:@"plist"]]retain];
				}
				
				NSString *childPreset = [bundlePresetChildren objectForKey:bundleIdentifier];
				if (childPreset) {
					if (VERBOSE) QSLog(@"using preset %@", childPreset);
					QSCatalogEntry *theEntry = [QSLib entryForID:childPreset];
					newChildren = [theEntry contentsScanIfNeeded:YES];
				} else {
					NSArray *recentDocuments = recentDocumentsForBundle(bundleIdentifier);
					newChildren = [QSObject fileObjectsWithPathArray:recentDocuments];
                    
					foreach(child, newChildren) {
						[child setObject:bundleIdentifier forMeta:@"QSPreferredApplication"];
					}
				}
			}
		} else if ((infoRec.flags & kLSItemInfoIsPackage) || !(infoRec.flags & kLSItemInfoIsContainer) ) {
			//NSString *type = [[NSFileManager defaultManager] typeOfFile:path];
			
			NSString *uti = QSUTIWithLSInfoRec(path, &infoRec);
			//QSUTIForExtensionOrType((NSString *)infoRec.extension, infoRec.filetype);
			
			//QSLog(@"uti %@ %@", uti, UTTypeCopyDescription(uti) );
			
			id handler = [QSReg instanceForKey:uti inTable:@"QSFSFileTypeChildHandlers"];
			if (handler)
				return [handler loadChildrenForObject:object];
			
			id <QSParser> parser = [QSReg instanceForKey:uti inTable:@"QSFSFileTypeParsers"];
			NSArray *children = [parser objectsFromPath:path withSettings:nil];
			if (children) {
				[object setChildren:children];
				return YES;
			}
		}
	} else {
		newChildren = [QSObject fileObjectsWithPathArray:[object arrayForType:QSFilePathType]];
	}
	if (newChildren) [object setChildren:newChildren];
	
	return YES;
}

- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
	NSString *path = [dObject objectForType:QSFilePathType];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef) [NSURL fileURLWithPath:path] , kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication) {
			NSMutableArray *actions = [[QSExec validActionsForDirectObject:dObject indirectObject:iObject] mutableCopy];
            NSString *bundleIdentifier = [[NSBundle bundleWithPath:path] bundleIdentifier];
            NSArray *appActions = [QSReg elementsForPointID:@"QSApplicationActions"];
			for (BElement* elem in appActions) {
				if ([[elem identifier] isEqualTo:bundleIdentifier]) {
					foreachkey(actionID, actionDict, [elem plistContent]) {
						[actions addObject:
						 [QSAction actionWithDictionary:actionDict
											 identifier:actionID
												 bundle:nil]];
					}
				}
			}
			return [actions autorelease];			
		}
	}
	return nil;
}
@end