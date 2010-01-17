//
//  QSTerminalMediator.m
//  PlugIns
//
//  Created by Nicholas Jitkoff on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//
//  2010-01-15 Makoto Yamashita.
#import "QSTerminalMediator.h"

@implementation QSRegistry (QSTerminalMediator)
- (NSString *)preferredTerminalMediatorID
{
	NSString *key=[[NSUserDefaults standardUserDefaults] stringForKey:kQSTerminalMediators];
	if (![[self tableNamed:kQSTerminalMediators] objectForKey:key]) {
        key = @"com.apple.Terminal";
    }
	return key;
}

- (id <QSTerminalMediator>)preferredTerminalMediator
{
	id mediator = [prefInstances objectForKey:kQSTerminalMediators];
	if (!mediator) {
		mediator = [self instanceForKey:[self preferredTerminalMediatorID]
                                inTable:kQSTerminalMediators];
		if (mediator) {
			[prefInstances setObject:mediator forKey:kQSTerminalMediators];
        }
	}
	return mediator;
}
@end

@implementation QSAppleTerminalMediator
- (void)performCommandInTerminal:(NSString *)command
{
    NSString* scriptPath = [[NSBundle bundleForClass:[self class]]
                              pathForResource:@"Terminal" ofType:@"scpt"];
    NSAppleScript *termScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath]
                                                                       error:nil];
    [termScript executeSubroutine:@"do_script" arguments:command error:nil];
    [[NSWorkspace sharedWorkspace] switchToApplication:[[NSWorkspace sharedWorkspace] dictForApplicationName:@"Terminal"]
                                       frontWindowOnly:YES];
    [termScript release], termScript = nil;
}
@end
