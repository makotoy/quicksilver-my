//
//  QSAppleMailPlugIn_Action.m
//  QSAppleMailPlugIn
//
//  Created by Nicholas Jitkoff on 9/28/04.
//
// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30

#import "QSAppleMailPlugIn_Action.h"
#import "QSAppleMailPlugIn_Source.h"
@implementation QSAppleMailPlugIn_Action


#define kQSAppleMailPlugInAction @"QSAppleMailPlugInAction"

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	return [[QSReg getClassInstance:@"QSAppleMailPlugIn_Source"]
			performSelector:@selector(allMailboxes)];

}

- (QSObject *)revealMailbox:(QSObject *)dObject{
	NSString *mailbox=[dObject objectForType:kQSAppleMailMailboxType];
	NSAppleScript *script=[[QSReg getClassInstance:@"QSAppleMailMediator"]
						   performSelector:@selector(mailScript)];
	[script executeSubroutine:@"open_mailbox" arguments:mailbox error:nil];
	return nil;
}

- (QSObject *)revealMessage:(QSObject *)dObject{
	NSArray *message=[[dObject objectForType:kQSAppleMailMessageType]componentsSeparatedByString:@"//"];
	NSAppleScript *script=[[QSReg getClassInstance:@"QSAppleMailMediator"]
						   performSelector:@selector(mailScript)];
	[script executeSubroutine:@"open_message" arguments:message error:nil];
	return nil;
}

- (QSObject *)deleteMessage:(QSObject *)dObject{
	NSArray *message=[[dObject objectForType:kQSAppleMailMessageType]componentsSeparatedByString:@"//"];
	NSAppleScript *script=[[QSReg getClassInstance:@"QSAppleMailMediator"]
						   performSelector:@selector(mailScript)];
	[script executeSubroutine:@"delete_message" arguments:message error:nil];
	return nil;
}
- (QSObject *)moveMessage:(QSObject *)dObject toMailbox:(QSObject *)iObject{
	NSArray *message=[[dObject objectForType:kQSAppleMailMessageType]componentsSeparatedByString:@"//"];
	NSMutableArray *arguments=[NSMutableArray arrayWithArray:message];
	
	[arguments addObject:[iObject objectForType:kQSAppleMailMailboxType]];
	NSAppleScript *script=[[QSReg getClassInstance:@"QSAppleMailMediator"]
						   performSelector:@selector(mailScript)];
	[script executeSubroutine:@"move_message" arguments:arguments error:nil];
	return nil;
}


@end
