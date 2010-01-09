/*
 * Derived from Blacktree, Inc. codebase
 * 2010-01-09 Makoto Yamashita
 */

#import <Carbon/Carbon.h>

#import "NSEvent+BLTRExtensions.h"

@implementation NSEvent (BLTRExtensions)
- (NSUInteger)standardModifierFlags
{
	NSUInteger standardModifierFlags = [self modifierFlags] & (NSCommandKeyMask|NSAlternateKeyMask|NSControlKeyMask|NSShiftKeyMask|NSFunctionKeyMask);
	return standardModifierFlags;
}
@end