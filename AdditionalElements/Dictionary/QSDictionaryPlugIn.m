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

#define THESAURUS_NAME @"Oxford American Writers Thesaurus"
#define DICTIONARY_NAME	@"New Oxford American Dictionary"

@implementation QSDictionaryPlugIn
// Currently there is no way to actually use the dictName parameter
- (void)lookupWord:(NSString *)word inDictionary:(NSString *)dictName
{
	word=[word lowercaseString];
    CFRange range;
    range.location = 0;
    range.length = [word length];
    NSString *definition;
    definition = (NSString*)DCSCopyTextDefinition( NULL, (CFStringRef)word, range);
    
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
