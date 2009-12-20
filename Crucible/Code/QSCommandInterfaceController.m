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
- (void) firstResponderChanged:(NSResponder *)aResponder {}

- (void) awakeFromNib {
  //NSLog(@"pselect %@", pSelector);
  [dSelector bind:@"objectValue" toObject:pSelector withKeyPath:@"objectValue" options:nil];
  [aSelector bind:@"objectValue" toObject:sSelector withKeyPath:@"objectValue" options:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//  if (context == pSelector) {
    NSLog(@"charge %@ %@ %@", keyPath, object, change);
    [dSelector setObjectValue:[(QSSearchObjectView*)pSelector objectValue]];
//  }
}

#pragma mark Menu Actions

- (void)shortCircuit:(id)sender {
  //QSLog(@"scirr");
	[self fireActionUpdateTimer];
  NSArray *array = [aSelector resultArray];
	
  int argumentCount = [(QSAction *)[aSelector objectValue] argumentCount];
	
  
  if (sender == iSelector) {
		
    int index = [array indexOfObject:[aSelector objectValue]];
		
    int count = [array count];
    if (index != count-1)
      array = [[array subarrayWithRange:NSMakeRange(index+1, count-index-1)] arrayByAddingObjectsFromArray:
               [array subarrayWithRange:NSMakeRange(0, index+1)]];
    argumentCount = 0;
    [[self window] makeFirstResponder:nil];
  }
  
  if (argumentCount != 2) {
    
    
    
    QSAction *action = nil;
    QSAction *bestAction = nil;
    for(action in array) {
      if ([action argumentCount] == 2) {
        bestAction = action;
        [aSelector selectObject:action];
        [self updateIndirectObjects];
        break;
      }
    }
    if (!bestAction) {
      NSBeep();
      return;
    }
  }
  [[self window] makeFirstResponder:iSelector];
}

- (void)updateActionsNow {
	[actionsUpdateTimer invalidate]; 	
	
	//QSLog(@"act on %@", [dSelector objectValue]);
    [aSelector setEnabled:YES];
    NSString *type = [NSString stringWithFormat:@"QSActionMnemonic:%@", [[dSelector objectValue] primaryType]];
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

- (void)willHideMainWindow:(id)sender {
    if ([[self window] isVisible] && ![[self window] attachedSheet]) {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceDeactivatedNotification object:self];
	[[self window] makeFirstResponder:nil];
    }
}

- (void)showMainWindow:(id)sender
{
  [(QSWindow *)[self window] makeKeyAndOrderFront:sender];
}

#pragma mark Notifications

- (BOOL)preview { return preview;  }

- (void)setPreview: (BOOL)flag
{
  preview = flag;
}

@end
















