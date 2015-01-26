// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30


#import "QSMailMediator.h"
#import <QSCrucible/QSResourceManager.h>
#import <QSCrucible/NSAppleScript+QSSubroutine.h>
#import <CoreServices/CoreServices.h>

NSString *defaultMailClientID(){
    CFURLRef appURLRef;
    OSStatus err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString: @"mailto:"],kLSRolesAll, NULL, &appURLRef);
    if (err == kLSApplicationNotFoundErr) {
        NSLog(@"defaultMailClientID could not find a mail app.");
        return nil;
    } else if (err != noErr){
		NSLog(@"defaultMailClientID encountered some unhandlable error.");
		return nil;
	}
    CFStringRef bdlIdStrRef = CFDictionaryGetValue(CFBundleCopyInfoDictionaryForURL(appURLRef), kCFBundleIdentifierKey);
    return (NSString*) bdlIdStrRef;
}

@implementation QSMailMediator

+ (id <QSMailMediator>)defaultMediator
{
    return [QSReg QSMailMediator];
}

- (void) sendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
	[self sendEmailWithScript:[self mailScript] to:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow];
}

- (void) sendEmailWithScript:(NSAppleScript *)script to:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
    if (!sender) sender = @"";
    if (!addresses) {
        NSRunAlertPanel(@"Invalid address", @"Missing email address", nil,nil,nil);
        return;
    }
    NSLog(@"Sending Email:\r     To: %@\rSubject: %@\r   Body: %@\rAttachments: %@\r",[addresses componentsJoinedByString:@", "],subject,body,[pathArray componentsJoinedByString:@"\r"]);
    
    NSDictionary *errorDict=nil;
    NSString *subroutineName = sendNow ? @"send_mail" : @"compose_mail";
    NSArray *subroutineArgs = @[subject, body, sender, addresses, (pathArray ? pathArray : [NSArray array])];
	[script executeSubroutine:subroutineName
                    arguments:subroutineArgs
                        error:&errorDict];

    if (errorDict) {
        NSRunAlertPanel(@"An error occured while sending mail",
                        @"Apple Script Execution returned error: %@",
                        nil,nil,nil,
                        [errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
    }
}

- (NSString *)scriptPath
{
    return nil;
}

- (NSAppleScript *)mailScript
{
    NSString *path;
    if (!mailScript && (path = [self scriptPath])){
        mailScript=[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
    }
    return mailScript;
}

@synthesize mailScript;

@end


@implementation QSRegistry (QSMailMediator)

- (id <QSMailMediator>)QSMailMediator
{
	id <QSMailMediator> mediator=[prefInstances objectForKey:kQSMailMediators];
	if (!mediator){
		mediator = [self instanceForKey:[QSReg QSMailMediatorID] inTable:kQSMailMediators];
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSMailMediators];
		else NSLog(@"Mediator not found %@",[[NSUserDefaults standardUserDefaults] stringForKey:kQSMailMediators]);
	}
	
	return mediator;
}
- (NSString *)QSMailMediatorID{
	NSString *key=[[NSUserDefaults standardUserDefaults] stringForKey:kQSMailMediators];
	if (!key)key=defaultMailClientID();
	return key;
}

@end

@interface QSResourceManager (QSMailMediator)
- (NSImage *)defaultMailClientImage;
@end

@implementation QSResourceManager (QSMailMediator)
- (NSImage *)defaultMailClientImage
{
	return [[NSWorkspace sharedWorkspace]iconForFile:[[NSWorkspace sharedWorkspace]absolutePathForAppBundleWithIdentifier:[QSReg QSMailMediatorID]]];
}
@end



