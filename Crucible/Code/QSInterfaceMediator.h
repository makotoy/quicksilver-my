//
//  QSInterfaceMediator.h
//  Quicksilver
//
//  Created by Alcor on 7/28/04.

//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-20

#import <Cocoa/Cocoa.h>
#import <QSElements/QSElements.h>

#define QSPreferredCommandInterface [QSReg preferredCommandInterface]
#define kQSCommandInterfaceControllers @"QSCommandInterfaceControllers"

@interface QSRegistry (QSCommandInterface)
- (NSString *)preferredCommandInterfaceID;
- (QSInterfaceController *)preferredCommandInterface;
@end
