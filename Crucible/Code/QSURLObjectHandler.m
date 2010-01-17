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

 *  Derived from Blacktree, Inc. codebase
 *  2010-01-16 Makoto Yamashita
 */
#import "QSURLObjectHandler.h"


@implementation QSURLObjectHandler
// Object Handler Methods


- (NSString *)identifierForObject:(id <QSObject>)object {
	return [object objectForType:QSURLType];
}
- (NSString *)detailsOfObject:(id <QSObject>)object {
	//NSString *url = [object objectForType:QSURLType];
	return [object objectForType:QSURLType];
}

- (void)setQuickIconForObject:(QSObject *)object {
	NSString *url = [object objectForType:QSURLType];
    if ([url hasPrefix:@"mailto:"])
        [object setIcon:[NSImage imageNamed:@"ContactEmail"]];
	else if ([url hasPrefix:@"ftp:"])
        [object setIcon:[QSResourceManager imageNamed:@"AFPClient"]];
	else
		[object setIcon:[QSResourceManager imageNamed:@"DefaultBookmarkIcon"]];
	
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped
{
	if (NSWidth(rect) <= 32 ) return NO;
	
	NSImage *image = [QSResourceManager imageNamed:@"DefaultBookmarkIcon"];
	NSString *url = [object objectForType:QSURLType];
	BOOL isQuery = [url rangeOfString:QUERY_KEY] .location != NSNotFound;
    
	if (![url hasPrefix:@"http:"] && !isQuery) return NO;
	
    [image setSize:[[image bestRepresentationForSize:rect.size] size]];
	[image setFlipped:flipped];
	[image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0];
	
	if ([object iconLoaded]) {
		NSImage *cornerBadge = [object icon];
		if (cornerBadge != image) {
			[cornerBadge setFlipped:flipped];  
			NSImageRep *bestBadgeRep = [cornerBadge bestRepresentationForSize:rect.size];  
			[cornerBadge setSize:[bestBadgeRep size]];
			NSRect badgeRect = rectFromSize([cornerBadge size]);
			badgeRect = centerRectInRect(badgeRect, rect);
			badgeRect = NSOffsetRect(badgeRect, 0, -NSHeight(rect) /6);
			
			[[NSColor colorWithDeviceWhite:1.0 alpha:0.8] set];
			NSRectFillUsingOperation(NSInsetRect(badgeRect, -3, -3), NSCompositeSourceOver);
			[[NSColor colorWithDeviceWhite:0.75 alpha:1.0] set];
			NSFrameRectWithWidth(NSInsetRect(badgeRect, -5, -5), 2);
			[cornerBadge drawInRect:badgeRect
                           fromRect:rectFromSize([cornerBadge size])
                          operation:NSCompositeSourceOver
                           fraction:1.0];
		}
	}
	if (isQuery) {
		NSImage *findImage = [NSImage imageNamed:@"Find"];
		[findImage setSize:NSMakeSize(128, 128)];
		[findImage drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect) *1/3, rect.origin.y, NSWidth(rect)*2/3, NSHeight(rect)*2/3)
                     fromRect:NSMakeRect(0, 0, 128, 128)
					operation:NSCompositeSourceOver fraction:1.0];
	}
	return YES;
}

- (BOOL)loadIconForObject:(QSObject *)object
{
	NSString *urlString = [object objectForType:QSURLType];
    if (!urlString) return NO;
	
    NSURL *url = [NSURL URLWithString:urlString];
	NSString *imageURLStr = [object objectForMeta:kQSObjectIconName];
    NSURL * imageURL = nil;
    if (imageURLStr) imageURL = [NSURL URLWithString:imageURLStr];
    /* TODO: need to find more efficent way
    if (!imageURL) {
        imageURL = [[NSURL alloc] initWithScheme:@"http"
                                            host:[url host]
                                            path:@"/favicon.ico"];
    }
     */
	if (imageURL) {
        NSImage *image = [[NSImage alloc] initByReferencingURL:imageURL];
        if (image) {
            [object setIcon:[image autorelease]];
            return YES;
		}
	}
    NSImage *favicon = nil;	
	for (id<QSFaviconSource> source in [QSReg loadedInstancesForPointID:@"QSFaviconSources"]) {
		if ((favicon = [source faviconForURL:url])) {
            if (![favicon representationOfSize:NSMakeSize(16, 16)]) {
                [favicon createRepresentationOfSize:NSMakeSize(16, 16)];
            }
            [object setIcon:favicon];
            return YES;
        }            
	}
	return NO;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	//if (!fBETA) return NO;
	NSString *urlString = [object objectForType:QSURLType];
	
	NSString *type = [urlString pathExtension];
	
	id <QSParser> parser = [QSReg instanceForKey:type inTable:@"QSURLTypeParsers"];
	
	[QSTasks updateTask:@"DownloadPage" status:@"Downloading Page" progress:0];
	
	NSArray *children = [parser objectsFromURL:[NSURL URLWithString:urlString] withSettings:nil];
	
	[QSTasks removeTask:@"DownloadPage"];
	
	if (children) {
		[object setChildren:children];
		return YES;
	}
	
	return NO;
}
@end
