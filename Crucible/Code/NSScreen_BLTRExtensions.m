//
//  NSScreen_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 12/19/04.

//

#import "NSScreen_BLTRExtensions.h"
#import <objc/objc-runtime.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOFramebufferShared.h>
#import <IOKit/graphics/IOGraphicsInterface.h>

#import <IOKit/graphics/IOGraphicsLib.h>
#import <IOKit/graphics/IOGraphicsTypes.h>
#import <Carbon/Carbon.h>

#import <ApplicationServices/ApplicationServices.h>

static void KeyArrayCallback(const void *key, const void *value, void *context) { CFArrayAppendValue(context, key);  }

CFStringRef QSGetLocalDisplayName(CGDirectDisplayID display)
{
    CFArrayRef		langKeys, orderLangKeys;
    CFStringRef		langKey, localName;
    io_connect_t displayPort;
    CFDictionaryRef dict, names;
	
    localName = NULL;
    displayPort = CGDisplayIOServicePort(display);
    if ( displayPort == MACH_PORT_NULL )
        return NULL;   /* No physical device to get a name from */
    dict = IOCreateDisplayInfoDictionary(displayPort, 0);
	
    names = CFDictionaryGetValue( dict, CFSTR(kDisplayProductName) );
    /* Extract all the  display name locale keys */
    langKeys = CFArrayCreateMutable( kCFAllocatorDefault, 0,  
									 &kCFTypeArrayCallBacks );
    CFDictionaryApplyFunction( names, KeyArrayCallback, (void  
														 *)langKeys );
    /* Get the preferred order of localizations */
    orderLangKeys = CFBundleCopyPreferredLocalizationsFromArray(  
																  langKeys );
	
//CFShow(names);
//	CFShow(langKeys);
	
    CFRelease( langKeys );
	
    if( orderLangKeys && CFArrayGetCount(orderLangKeys) )
    {
        langKey = CFArrayGetValueAtIndex( orderLangKeys, 0 );
        localName = CFDictionaryGetValue( names, langKey );
        CFRetain( localName );
		
//		CFShow(langKey);
//		CFShow(localName);
    }
	
    CFRelease(orderLangKeys);
    CFRelease(dict);
    return localName;
}



@implementation NSScreen (BLTRExtensions)
-(int)screenNumber
{
	id sNumObj = [[self deviceDescription]objectForKey:@"NSScreenNumber"];
	if (sNumObj) return [sNumObj intValue];
     
	int screenNumber;
	object_getInstanceVariable(self, "_screenNumber", (void*)&screenNumber);
 	return screenNumber;
} 
-(BOOL)usesOpenGLAcceleration{
	return (BOOL)CGDisplayUsesOpenGLAcceleration((CGDirectDisplayID)[self screenNumber]);
}
-(NSString *)deviceName{
	NSString *name = (NSString *)QSGetLocalDisplayName((CGDirectDisplayID)[self screenNumber]);
	//QSLog(@"Display: %@",name);
	if (!name){
		uint32_t model = CGDisplayModelNumber((CGDirectDisplayID)[self screenNumber]);
		uint32_t vendor = CGDisplayVendorNumber((CGDirectDisplayID)[self screenNumber]);
		
		NSString *infoPath = [NSString stringWithFormat:@"/System/Library/Displays/Overrides/DisplayVendorID-%x/DisplayProductID-%x",vendor, model];
		NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		name=[info objectForKey:@"DisplayProductName"];
		
		if (!name)name=[NSString stringWithFormat:@"Unknown Display (%x:%x)",vendor, model];
	}
	
	return name;
}

-(BOOL)supportsQE{
	NSNumber* screenNum = [NSNumber numberWithInt:[self screenNumber]];
	BOOL supportsQuartzExtreme = CGDisplayUsesOpenGLAcceleration( (CGDirectDisplayID) [screenNum pointerValue] );
	return supportsQuartzExtreme;
}

+(NSScreen *)screenWithNumber:(int)number{
	NSEnumerator *e=[[self screens]objectEnumerator];
	NSScreen *screen;
	while((screen=[e nextObject])){
		if ([screen screenNumber]==number){
			return screen;
		}
	}
	//QSLog(@"Can't find Screen %d",number);	
	
//	QSLog(@"screenx %d %d",[screen screenNumber],number);
	return nil;
}
@end
