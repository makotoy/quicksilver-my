//
//  QSCommandInterfaceController.h
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/24/07.

//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import <Cocoa/Cocoa.h>
#import "QSInterfaceController.h"

@interface QSCommandInterfaceController : QSInterfaceController {
    IBOutlet NSController *pSelector;
    IBOutlet NSController *sSelector;
    QSCommand *command;
    IBOutlet NSTextField *searchField;
}
@end
