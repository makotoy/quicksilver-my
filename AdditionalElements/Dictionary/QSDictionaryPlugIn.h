//
//  QSDictionaryPlugIn.h
//  DictPlugin
//
//  Created by Nicholas Jitkoff on 11/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
//  Derived from Quicksilver codebase
//  2010-02-20 Makoto Yamashita

#import <Cocoa/Cocoa.h>

@interface QSDictionaryPlugIn : NSObject {
}
- (QSObject *)lookupWordInDictionary:(QSObject *)dObject;
- (QSObject *)lookupWordInThesaurus:(QSObject *)dObject;
- (void)lookupWord:(NSString *)word inDictionary:(NSString *)dictName;

@end
