//
//  QSCommandInterfaceController.m
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/24/07.

//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import "QSCommandInterfaceController.h"

#import "QSController.h"

@implementation QSCommandInterfaceController
- (void) awakeFromNib
{
    [dSelector bind:@"objectValue" toObject:pSelector withKeyPath:@"objectValue" options:nil];
    [aSelector bind:@"objectValue" toObject:sSelector withKeyPath:@"objectValue" options:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
// NOTE: was " if (context == pSelector) { "
    NSLog(@"charge %@ %@ %@", keyPath, object, change);
    [dSelector setObjectValue:[(QSSearchObjectView*)pSelector objectValue]];
}

#pragma mark Menu Actions

- (void)updateActionsNow
{
    [actionsUpdateTimer invalidate]; 	
    [aSelector setEnabled:YES];
    NSString *type = [NSString stringWithFormat:@"QSActionMnemonic:%@",
			       [[dSelector objectValue] primaryType]];
    NSArray *actions = [self rankedActions];

// FIXME: This is incorrect, but the correct one below doesn't work...
    [self updateControl:(QSSearchObjectView*)sSelector withArray:actions];
    [self updateControl:(QSSearchObjectView*)aSelector withArray:actions];
    [self updateControl:(QSSearchObjectView*)sSelector withArray:actions];
    /*
      [self updateControl:dSelector withArray:actions];
      [self updateControl:aSelector withArray:actions];
      [self updateControl:iSelector withArray:actions];
     */	
    [aSelector setMatchedString:type];
    [aSelector setSearchString:nil];
}

- (void)willHideMainWindow:(id)sender
{
    if ([[self window] isVisible] && ![[self window] attachedSheet]) {
	[[NSNotificationCenter defaultCenter]
	    postNotificationName:QSInterfaceDeactivatedNotification object:self];
	[[self window] makeFirstResponder:nil];
    }
}

- (void)showMainWindow:(id)sender
{
  [(QSWindow *)[self window] makeKeyAndOrderFront:sender];
}

@end
















