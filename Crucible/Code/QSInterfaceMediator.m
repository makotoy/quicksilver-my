//
//  QSInterfaceMediator.m
//  Quicksilver
//
//  Created by Alcor on 7/28/04.

//  Derived from Blacktree, Inc. codebase
//  Makoto Yamashita 2009-12-20

#import "QSInterfaceMediator.h"

@implementation QSRegistry (QSCommandInterface)
- (NSString*)preferredCommandInterfaceID
{
	NSString *key = [[NSUserDefaults standardUserDefaults]
                     stringForKey:kQSCommandInterfaceControllers];
	if (![self elementForPointID:kQSCommandInterfaceControllers withID:key]) {
        return @"QSCubeInterface";
    }
	return key;
}

- (QSInterfaceController*)preferredCommandInterface
{
	QSInterfaceController* mediator = [prefInstances objectForKey:kQSCommandInterfaceControllers];
	
	if (!mediator) {
		mediator = [self instanceForKey:[self preferredCommandInterfaceID]
                                inTable:kQSCommandInterfaceControllers];
		if (mediator) {
			[prefInstances setObject:mediator forKey:kQSCommandInterfaceControllers];
        }
	}
	return mediator;
}
@end