//
//  NSAppleScript_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import "NSAppleScript+QSSubroutineDiscovery.h"
#import "NSData_RangeExtensions.h"

#import <Carbon/Carbon.h>

@implementation NSAppleScript (QSSubroutineDiscovery)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path
{
	NSData *scriptData=[NSData dataWithContentsOfMappedFile:path];
	NSMutableArray *validHandlers=[NSMutableArray array];
	for (NSString *handler in array){
		if ([scriptData offsetOfData:[handler dataUsingEncoding:NSASCIIStringEncoding]]!=NSNotFound)
			[validHandlers addObject:handler];
	}
	return validHandlers;
}
@end
