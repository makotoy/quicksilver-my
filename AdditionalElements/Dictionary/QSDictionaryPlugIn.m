//
//  QSDictionaryPlugIn.m
//  DictPlugin
//
//  Created by Nicholas Jitkoff on 11/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
//  Derived from Quicksilver codebase
//  2010-02-20 Makoto Yamashita

#import "QSDictionaryPlugIn.h"
#import "QSDictionaryUtility.h"

#define THESAURUS_NAME @"Oxford American Writer's Thesaurus"
#define DICTIONARY_NAME	@"New Oxford American Dictionary"

#define DICT_ROOT @"/Library/Dictionaries"
#define ACTIVE_DICT_KEY @"DCSActiveDictionaries"
#define DICT_DOMAIN @"com.apple.DictionaryServices"

NSArray *DCSCopyAvailableDictionaries();
NSString *DCSDictionaryGetName(DCSDictionaryRef dictID);

@implementation QSDictionaryPlugIn
// Currently there is no way to actually use the dictName parameter
- (void)lookupWord:(NSString *)word inDictionary:(NSString *)dictName
{
	word = [word lowercaseString];
    CFRange range = CFRangeMake(0, [word length]);
    NSString *definition;
    DCSDictionaryRef dictRef = NULL;
    for (id dict in DCSCopyAvailableDictionaries()) {
        if ([dictName isEqualToString:DCSDictionaryGetName((DCSDictionaryRef)dict)]) {
            dictRef = (DCSDictionaryRef)dict;
            break;
        }
    }    
    definition = (NSString*)DCSCopyTextDefinition(dictRef, (CFStringRef)word, range);
    
	if (![definition length]) {
        definition = [NSString stringWithFormat:@"\"%@\" could not be found.", word];
    }
    showResultsWindow(definition, word, nil);
}

- (QSObject *)lookupWordInDictionary:(QSObject *)dObject
{
    [self lookupWord:[dObject stringValue] inDictionary:DICTIONARY_NAME];
    return nil;
}

- (QSObject *)lookupWordInThesaurus:(QSObject *)dObject
{
    [self lookupWord:[dObject stringValue] inDictionary:THESAURUS_NAME];
    return nil;
}

@end
