//
//  QSDirectoryParser.h
//  Quicksilver
//
//  Created by Alcor on 4/6/05.

//  Makoto Yamashita 2009-12-25

#import <Cocoa/Cocoa.h>

@interface QSDirectoryParser : QSParser

- (NSArray *)objectsFromPath:(NSString *)path depth:(int)depth types:(NSArray *)types;
@end

