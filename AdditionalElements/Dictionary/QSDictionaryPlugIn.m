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

CFArrayRef DCSCopyAvailableDictionaries();
CFStringRef DCSDictionaryGetName(DCSDictionaryRef dictID);
DCSDictionaryRef DCSGetDefaultDictionary();
DCSDictionaryRef DCSGetDefaultThesaurus();

@implementation QSDictionaryPlugIn

- (void)lookupWord:(NSString *)word inDictionary:(NSString *)dictName
{
	word = [word lowercaseString];
    CFRange range = CFRangeMake(0, [word length]);
    NSString *definition;
    DCSDictionaryRef dictRef = NULL;
    NSArray* dArray = (NSArray*)DCSCopyAvailableDictionaries();
    for (id dummy in dArray) {
        DCSDictionaryRef dict = (DCSDictionaryRef)dummy;
        if ([dictName isEqualToString:(NSString*)DCSDictionaryGetName(dict)]) {
            dictRef = dict;
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
    DCSDictionaryRef dict = DCSGetDefaultDictionary();
    NSString* dictName = (NSString*)DCSDictionaryGetName(dict);
    if (!dictName) dictName = DICTIONARY_NAME;
    [self lookupWord:[dObject stringValue] inDictionary:dictName];
    return nil;
}

- (QSObject *)lookupWordInThesaurus:(QSObject *)dObject
{
    DCSDictionaryRef dict = DCSGetDefaultThesaurus();
    NSString* dictName = (NSString*)DCSDictionaryGetName(dict);
    if (!dictName) dictName = THESAURUS_NAME;
    [self lookupWord:[dObject stringValue] inDictionary:dictName];
    return nil;
}

@end
