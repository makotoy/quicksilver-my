// Derived from Blacktree codebase
// 2009-11-30 Makoto Yamashita

#import "QSTextSource.h"

#define textTypes [NSArray arrayWithObjects:@"'TEXT'",@"txt",@"html",@"htm",nil]

#define kQSTextTypeAction @"QSTextTypeAction"

#define kQSTextDiffAction @"QSTextDiffAction"
#define kQSLargeTypeAction @"QSLargeTypeAction"


@implementation QSTextActions

- (QSObject *)showLargeType:(QSObject *)dObject{
	QSShowLargeType([dObject stringValue]);
	return nil;
}

- (QSObject *)showDialog:(QSObject *)dObject{
	[NSApp activateIgnoringOtherApps:YES];
	NSRunInformationalAlertPanel(@"Quicksilver", [dObject stringValue], @"OK", nil, nil);
	
	return nil;
}

- (QSObject *)speakText:(QSObject *)dObject{
	
	NSString *string=[dObject stringValue];
	string=[string stringByReplacing:@"\"" with:@"\\\""];
	string=[NSString stringWithFormat:@"say \"%@\"",string];

	[[[[NSAppleScript alloc]initWithSource:string]autorelease]executeAndReturnError:nil];


	return nil;
}

- (QSObject *) typeObject:(QSObject *)dObject
{
    //  QSLog( AsciiToKeyCode(&ttable, "m") {
    //  short AsciiToKeyCode(Ascii2KeyCodeTable *ttable, short asciiCode) {
    
    QSLog([dObject objectForType:QSTextType]);
    
    [self typeString2:[dObject objectForType:QSTextType]];
    
    return nil;
}

-(void)typeString:(NSString *)string
{
	const char *s = [string UTF8String];
	int i;
	for (i = 0; i < strlen(s); i++){
		CGKeyCode code = [QSKeyCodeTranslator keyCodeForCharacter:s[i]];
        CGEventRef vKeyDownEventRef, vKeyUpEventRef;
        vKeyDownEventRef = CGEventCreateKeyboardEvent(NULL, code, true);
        vKeyUpEventRef = CGEventCreateKeyboardEvent(NULL, code, false);
        if (isupper(s[i])) {
            CGEventSetFlags(vKeyDownEventRef, kCGEventFlagMaskShift);
            CGEventSetFlags(vKeyUpEventRef, kCGEventFlagMaskShift);
        }
        CGEventPost(kCGHIDEventTap, vKeyDownEventRef);
        CGEventPost(kCGHIDEventTap, vKeyUpEventRef);
        
        CFRelease(vKeyDownEventRef);
        CFRelease(vKeyUpEventRef);
	}
}


-(void)typeString2:(NSString *)string{
	string=[string stringByReplacing:@"\n"with:@"\r"];
	NSAppleScript *sysEventsScript=[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"System Events" ofType:@"scpt"]] error:nil];
	NSDictionary *errorDict=nil;
	//NSAppleEventDescriptor *desc=
	[sysEventsScript executeSubroutine:@"type_text" arguments:string error:&errorDict];
	if (errorDict) QSLog(@"Execute Error: %@",errorDict);
}
@end




