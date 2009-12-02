//
//  QSKeyCodeTranslator.h
//  Quicksilver
//
//  Created by Alcor on 8/12/04.

//  Derived from Blacktree codebase
//  Modified by Makoto Yamashita 2009-11-11.

#import <Cocoa/Cocoa.h>

@interface QSKeyCodeTranslator : NSObject {

}
+(OSStatus)InitAscii2KeyCodeTable;
+(short)keyCodeForCharacter:(char)asciiCode;
+ (UniChar)unicharForKeyCode:(CGKeyCode)keyCode;

@end
