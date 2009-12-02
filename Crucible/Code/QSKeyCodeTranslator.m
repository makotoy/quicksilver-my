//
//  QSKeyCodeTranslator.m
//  Quicksilver
//
//  Created by Alcor on 8/12/04.

//  Derived from Blacktree codebase
//  Modified by Makoto Yamashita 2009-11-11.


#import "QSKeyCodeTranslator.h"

#define kKeyCodeTableSize 256

typedef struct {
    short transtable[kKeyCodeTableSize];
} Ascii2KeyCodeTable;

Ascii2KeyCodeTable keytable;

@implementation QSKeyCodeTranslator
+(void) initialize{
    [self InitAscii2KeyCodeTable];
}

+(OSStatus)InitAscii2KeyCodeTable{
	//QSLog(@"init table");
	int i, j, k;
    /* set up our table to all minus ones */
    for (i = 0; i < kKeyCodeTableSize; i++) keytable.transtable[i] = -1;
	TISInputSourceRef layoutRef;
	layoutRef = TISCopyCurrentKeyboardLayoutInputSource();
	CFDataRef layoutDataRef;
	layoutDataRef = TISGetInputSourceProperty(layoutRef, kTISPropertyUnicodeKeyLayoutData);
	UCKeyboardLayout* uckl = (UCKeyboardLayout*)CFDataGetBytePtr(layoutDataRef);
	ByteCount keyToCharOffset;
	UCKeyToCharTableIndex* ucktch;
	for (i = 0; i < uckl-> keyboardTypeCount; i++) {
		keyToCharOffset = uckl->keyboardTypeList[i].keyToCharTableIndexOffset;
		ucktch = (UCKeyToCharTableIndex*)((unsigned char *)uckl + keyToCharOffset);
		for (j = 0; j < ucktch->keyToCharTableCount; j++) {
			UCKeyOutput *keyToCharData;
			keyToCharData = (UCKeyOutput *)(((unsigned char*)uckl) + (ucktch->keyToCharTableOffsets[j]) );
			for (k = 0; k < ucktch->keyToCharTableSize; k++) {
				if (kUCKeyOutputTestForIndexMask & keyToCharData[k]) continue;
				UniChar uniCh = (kUCKeyOutputGetIndexMask & keyToCharData[k]);
				if (uniCh < kKeyCodeTableSize && keytable.transtable[ uniCh ] == -1) {
					keytable.transtable[ uniCh ] = k;
				}
			}
		}
	}    
    return noErr;
}

+(short)keyCodeForCharacter:(char)asciiCode
{
	return keytable.transtable[(UniChar)asciiCode];
}

+ (UniChar)unicharForKeyCode:(CGKeyCode)keyCode
{
	int i;
	for (i = 0; i < kKeyCodeTableSize; i++) {
		if (keytable.transtable[i] == keyCode) return (UniChar)i;
	}
	return kNullCharCode;
}

@end


