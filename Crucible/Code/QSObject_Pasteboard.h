

#import <Foundation/Foundation.h>

#import "QSObject.h"

@interface QSObject (Pasteboard)
+ (id)objectWithPasteboard:(NSPasteboard *)pasteboard;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;
- (void)addContentsOfPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types;

- (void)guessName;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
- (void)pasteboardChangedOwner:(NSPasteboard *)sender;
- (NSData *)dataForType:(NSString *)dataType;
@end