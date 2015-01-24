//
//  NSPasteboard_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Sun Nov 09 2003.

//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import "NSPasteboard_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"

#import "QSKeyCodeTranslator.h"

void QSForcePaste(){
	CGEventRef vKeyDownEventRef, vKeyUpEventRef;
	CGKeyCode keyCode = [QSKeyCodeTranslator keyCodeForCharacter:'v'];
	vKeyDownEventRef = CGEventCreateKeyboardEvent(NULL, keyCode, true);
	vKeyUpEventRef = CGEventCreateKeyboardEvent(NULL, keyCode, false);
	CGEventSetFlags(vKeyDownEventRef, kCGEventFlagMaskCommand);
	CGEventSetFlags(vKeyUpEventRef, kCGEventFlagMaskCommand);

	CGEventPost(kCGHIDEventTap, vKeyDownEventRef);
	CGEventPost(kCGHIDEventTap, vKeyUpEventRef);

	CFRelease(vKeyDownEventRef);
	CFRelease(vKeyUpEventRef);
}
