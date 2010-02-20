//
//  DictPlugin.h
//  DictPlugin
//
//  Created by Kevin Ballard on 8/1/04.
//  Copyright TildeSoft 2004. All rights reserved.
//
//  Derived from Quicksilver codebase
//  2010-02-20 Makoto Yamashita

#import <Foundation/Foundation.h>

@interface DictPlugin : QSActionProvider
{
	NSTask *dictTask;
	NSImage *dictIcon;
	NSString *dictTaskStatus;
	NSMutableData *buffer;
}
- (QSObject *) define:(QSObject *)dObject;
- (void) definitionFinished:(NSNotification *)aNotification;
- (void) dataAvailable:(NSNotification *)aNotification;
- (void) processBuffer;

@end
