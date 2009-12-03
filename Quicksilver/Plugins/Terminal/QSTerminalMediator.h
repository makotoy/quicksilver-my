//
//  QSTerminalMediator.h
//  PlugIns
//
//  Created by Nicholas Jitkoff on 9/29/04.

//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import <Cocoa/Cocoa.h>
// #import <QSCore/QSRegistry.h>
// #import "QSRegistry.h"

#define kQSTerminalMediators @"QSTerminalMediators"

@protocol QSTerminalMediator
- (void)performCommandInTerminal:(NSString *)command;
@end

@interface QSRegistry (QSTerminalMediator)
- (NSString *)preferredTerminalMediatorID;
- (id <QSTerminalMediator>)preferredTerminalMediator;
@end

@interface QSAppleTerminalMediator : NSObject <QSTerminalMediator>
@end