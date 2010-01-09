//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#include <stdio.h>
#include <unistd.h>

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <ExceptionHandling/NSExceptionHandler.h>
#import <IOKit/IOCFBundle.h> 
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

#import "QSAboutWindowController.h"
#import "QSAgreementController.h"
#import "QSApp.h"
#import "QSController.h"
#import "QSDonationManager.h"
#import "QSModifierKeyEvents.h"
#import "QSPlugInsPrefPane.h"
#import "QSPreferencesController.h"
#import "QSSetupAssistant.h"
#import "QSTaskViewer.h"
#import "QSUpdateController.h"
#import "QSCatalogPrefPane.h"

#include "QSSandBox.h"

#define EXPIREDATE [NSCalendarDate dateWithYear:2004 month:8 day:1 hour:0 minute:0 second:0 timeZone:nil]
#define DEVEXPIRE 180.0f
#define DEPEXPIRE 365.24219878f


//#include "QSLocalization.h"

extern char** environ;

#define OneIn(i) ((int) (i*(double)random()/(double)0x7fffffff) == 0)

#pragma mark Events
NSString * QSQuicksilverWillQuitEvent = @"QSQuicksilverWillQuitEvent";
NSString * QSQuicksilverLaunchedAtLoginEvent = @"QSQuicksilverLaunchedAtLoginEvent";
NSString * QSQuicksilverLaunchedEvent = @"QSQuicksilverLaunchedEvent";

QSVoyeur *voy;
QSController *QSCon;
static id _sharedInstance;

@interface QCView (Private)
- (void)_pause;
- (void)setClearsBackground:(BOOL)flag;
@end

@interface QSObject (QSURLHandling)
- (void)handleURL:(NSURL *)url;
@end

@interface QSController (Connection)
- (void)startMenuExtraConnection;
- (void) stopMenuExtraConnection;
@end    

@implementation QSController
- (void)awakeFromNib {
	if (!QSCon) QSCon = [self retain];
	
	[preferencesMenu setTarget:self];
	[preferencesMenu setAction:@selector(showPreferences:)];
	[preferencesMenu setKeyEquivalent:@", "];
  
    [[QSRegistry sharedInstance] scanPlugins];
	[[QSRegistry sharedInstance] loadMainExtension];
	if (DEBUG_STARTUP) 
		QSLog(@"Registry loaded");
}

+ (id)sharedInstance {
    if (!QSCon) QSCon = [[[self class] allocWithZone:[self zone]] init];
    return QSCon;
}

+ (void)initialize {
  
//  BOOL runningFromXcode = [[[NSProcessInfo processInfo] environment] valueForKey:@"NSUnbufferedIO"];
	if (DEBUG_STARTUP) QSLog(@"Controller Initialize");
	
	static BOOL initialized = NO;
	/* Make sure code only gets executed once. */
	if (initialized == YES) return;
	
	initialized = YES;
	
	//statusItem = nil;
	if (QSGetLocalizationStatus() && DEBUG_STARTUP) QSLog(@"Enabling Localization");
	
	[NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]
							 returnTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]];
	
	//	NSString *oldPrefs = [@"~/Library/Preferences/com.blacktree.Quicksilver.plist" stringByStandardizingPath];
	//	NSString *newPrefs = [@"~/Library/Preferences/com.blacktree.Quicksilver.plist" stringByStandardizingPath];
	//	NSFileManager *fm = [NSFileManager defaultManager];
	//	if ([fm fileExistsAtPath:[]
	//		copyPath: < #(NSString *)src# > toPath: < #(NSString *)dest# > handler: < #((null))handler#>
	[NDHotKeyEvent setSignature:'DAED'];
	
	//   QSLog(@"-------score: %f", [@"Let's go to the library" scoreForAbbreviation:@"letliby"]);
	[QSVoyeur sharedInstance];
	NSImage *defaultActionImage = [NSImage imageNamed:@"defaultAction"];
	[[defaultActionImage retain] setScalesWhenResized:NO];
	[defaultActionImage setCacheMode:NSImageCacheNever];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"verbose"]) {
		setenv("verbose", "1", YES);
    }
	
	// Pre instantiate to avoid bug
	[NSColor controlShadowColor];
	[NSColor setIgnoresAlpha:NO];
	return;
}

- (void)setupAssistantCompleted:(id)sender {
	runningSetupAssistant = NO;
}

- (void)showExpireDialog {
	[NSApp activateIgnoringOtherApps:YES];
	int result = NSRunInformationalAlertPanel(@"", @"This version of Quicksilver has expired. Please download the latest version.", @"Download", @"OK", nil);
	if (result)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDownloadUpdateURL]]; 	
}

- (id)init {
	if ((self = [super init])) {
		
		_sharedInstance = self;
        
        NSNumber *level = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSLoggingLevel"];
        if (level) [BLogManager setLoggingLevel:[level intValue]];
        
		if (DEBUG_STARTUP) QSLog(@"Controller Init");
		
		// Enforce Expiration Date
		// Check if a devopment version has expired
		NSDate *buildDate = [[[NSFileManager defaultManager]
                               attributesOfItemAtPath:[[NSBundle mainBundle] executablePath]
                               error:NULL] fileModificationDate];
		NSDate *expireDate = [NSDate dateWithTimeInterval:DAYS*(DEVELOPMENTVERSION?DEVEXPIRE:DEPEXPIRE)
                                                sinceDate:buildDate];
		
		if (PRERELEASEVERSION) {
            if ([[NSDate date] timeIntervalSinceDate:expireDate] > 0) {
                [NSApp activateIgnoringOtherApps:YES];
                QSLog(@"Quicksilver Expired %@", expireDate);
                
                [self showExpireDialog];
                
                if (!(GetCurrentKeyModifiers() & (optionKey | rightOptionKey))) {
                    [NSTimer scheduledTimerWithTimeInterval:13*HOURS
                                                     target:self
                                                   selector:@selector(showExpireDialog)
                                                   userInfo:nil
                                                    repeats:YES];
                }
            }
		}
		// Change Icon Colors
		srandom(time(0) * getpid() );
		iconColor = nil;
		[self setIconColor:[NSColor blueColor]];
		
		if (DEBUG_STARTUP) QSLog(@"Images loaded");
		[self startMenuExtraConnection];
	}
	return self;
}


- (void)appWillLaunch:(NSNotification *)notif {
	
	if ([[[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:
		[[NSBundle mainBundle] bundleIdentifier]]) {
		[NSApp terminate:self];
	} else {
		//        QSLog(@"App: %@ %@", [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] , [[NSBundle mainBundle] bundleIdentifier]);
		
	}
}

@synthesize activatedImage;
- (void)setActivatedImage:(NSImage *)newActivatedImage
{
	[activatedImage release];
    activatedImage = [newActivatedImage retain];
	[activatedImage setName:@"Quicksilver-Activated"];
}

@synthesize runningImage;
- (void)setRunningImage:(NSImage *)newRunningImage
{
	[runningImage release];
	runningImage = [newRunningImage retain];
	[runningImage setName:@"Quicksilver-Running"];
}

- (void)recompositeIconImages
{
	NSImage *icon = [NSImage imageNamed:@"Quicksilver h05"];
	[icon setSize:NSMakeSize(128, 128)];
	NSImage *activatedIcon = [[icon copy] autorelease];
	NSImage *runningIcon = [[icon copy] autorelease];
	[activatedIcon lockFocus];
	[[NSImage imageNamed:@"QSIconActivatedBadge"] dissolveToPoint:NSZeroPoint fraction:1.0];
	[activatedIcon unlockFocus];
	[runningIcon lockFocus];
	[[NSImage imageNamed:@"QSIconRunningBadge"] dissolveToPoint:NSZeroPoint fraction:1.0];
	[runningIcon unlockFocus];

	NSColor *uiColor = nil;
	
	if (fSPECIAL) {
		uiColor = [self iconColor];
    } else if (fBETA) {
		uiColor = [NSColor alternateSelectedControlColor];
	} else {
		uiColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	}
	uiColor = [uiColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	CGFloat hue = [uiColor hueComponent];
	CGFloat saturation = [uiColor saturationComponent];
	
	if (fSPECIAL) {		
		hue = (CGFloat) (([[NSCalendarDate calendarDate] secondOfMinute] / 30.0) - 1.0) * 3.14;
		[self setIconColor:[NSColor colorWithCalibratedHue:hue saturation:saturation brightness:1.0 alpha:1.0]];
	}
	NSImage *newActivated = [activatedIcon imageByAdjustingHue:hue saturation:saturation];
	NSImage *newRunning = [runningIcon imageByAdjustingHue:hue saturation:saturation];
	
	[self setActivatedImage:newActivated];
	[self setRunningImage:newRunning];
    [self deactivated:nil];
}

- (int) showMenuIcon { return -1; }

- (void)setShowMenuIcon:(NSNumber *)mode
{
	int priority = 0;
	
	if (statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		[statusItem release];
		statusItem = nil;
	}
	switch ([mode intValue]) {
		case 1: priority = NSNormalStatusItemPriority; break;
		case 2: priority = NSLeftStatusItemPriority; break;
		case 3: priority = NSRightStatusItemPriority; break;
		case 4: priority = NSFarRightStatusItemPriority; break;
		default: return;
	}
	statusItem = [[NSStatusBar systemStatusBar] _statusItemWithLength:29.0f withPriority:priority];
	[statusItem retain];
	[statusItem setImage:[NSImage imageNamed:@"QuicksilverMenu"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"QuicksilverMenuPressed"]];
	[statusItem setMenu:[self statusMenuWithQuit]];
	[statusItem setHighlightMode:YES];
}

- (void)activateDebugMenu
{
	NSMenu *debugMenu = [[[NSMenu alloc] initWithTitle:@"Debug"] autorelease];
	NSMenuItem *theItem;
	theItem = [debugMenu addItemWithTitle:@"Log Object to Console" action:@selector(logObjectDictionary:) keyEquivalent:@""];
	
	theItem = [debugMenu addItemWithTitle:@"Perform Score Test" action:@selector(scoreTest:) keyEquivalent:@""];
	[theItem setTarget:QSLib];
	
	theItem = [debugMenu addItemWithTitle:@"Log Registry" action:@selector(printRegistry:) keyEquivalent:@""];
	[theItem setTarget:QSReg];
	
	theItem = [debugMenu addItemWithTitle:@"Run Setup Assistant..." action:@selector(runSetupAssistant:) keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [debugMenu addItemWithTitle:@"Show Agreement..." action:@selector(showAgreement:) keyEquivalent:@""];
	[theItem setTarget:self];
		
	theItem = [debugMenu addItemWithTitle:@"Release Histories..." action:@selector(sendReleaseAll:) keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [debugMenu addItemWithTitle:@"Purge Image and Child Caches..." action:@selector(purgeAllImagesAndChildren) keyEquivalent:@""];
	[theItem setTarget:[QSObject class]];
	
	theItem = [debugMenu addItemWithTitle:@"Purge Identifiers..." action:@selector(purgeIdentifiers) keyEquivalent:@""];
	[theItem setTarget:[QSObject class]];
	
	theItem = [debugMenu addItemWithTitle:@"Raise Exception..." action:@selector(raiseException) keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [debugMenu addItemWithTitle:@"Crash..." action:@selector(crashQS) keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [debugMenu addItemWithTitle:@"New Prefs..." action:@selector(showPrefs) keyEquivalent:@""];
	[theItem setTarget:[QSPreferencesController class]];
	
	NSMenuItem *debugMenuItem = [[NSApp mainMenu] addItemWithTitle:@"Debug" action:nil keyEquivalent:@""];
	[debugMenuItem setSubmenu:debugMenu];
}

- (void)raiseException
{
	[NSException raise:@"Test Exception"
                format:@"This is only a test; in the event of a real exception, it should be followed by some witty commentary."];
}

- (void)crashQS { QSLog((id)1); }

- (void)keyDown:(NSEvent *)theEvent { NSBeep(); }

// Menu Actions

- (IBAction)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSWindowsShouldHideNotification object:self];
	[QSPreferencesController showPrefs];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"; "]) {
		[self showCatalog:nil];
		return YES;
	}
	return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem
{
	SEL action = [anItem action];
	if (action == @selector(showForums:) 
		 || action == @selector(reportABug:) 
		 || action == @selector(showHelp:) 
		 || action == @selector(donate:)
		 || action == @selector(openIRCChannel:) ) {
		if (![anItem image]) {
			[anItem setImage:[[NSImage imageNamed:@"DefaultBookmarkIcon"] duplicateOfSize:QSSize16]];
	
		}
		return YES;
	}
	if (action == @selector(showReleaseNotes:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Catalog"] duplicateOfSize:QSSize16]];
	}
	if (action == @selector(rescanItems:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Button-Rescan"] duplicateOfSize:QSSize16]];
	}
	if (action == @selector(showPreferences:) || action == @selector(showSettings:) ) {
		if (![anItem image])
			[anItem setImage:[[QSResourceManager imageNamed:@"prefsGeneral"] duplicateOfSize:QSSize16]];
	}
	if (action == @selector(showGuide:) ) {
		if (![anItem image]) {
			[anItem setImage:[[QSResourceManager imageNamed:@"Quicksilver"] duplicateOfSize:QSSize16]];
		}
		return NO;
	}
	if (action == @selector(getMorePlugIns:) ) {
		if (![anItem image]) {
			[anItem setImage:[[NSImage imageNamed:@"QSPlugIn"] duplicateOfSize:QSSize16]];
		}
		return NO;
	}
	if (action == @selector(showCatalog:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Catalog"] duplicateOfSize:QSSize16]];
	}	
	if ([anItem action] == @selector(showShelf:) ) {
		return YES;
	}
	if ([anItem action] == @selector(showTriggers:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Triggers"] duplicateOfSize:QSSize16]];

		return [[QSReg elementsForPointID:@"QSTriggerManagers"] count];
	
	}
	if ([anItem action] == @selector(unsureQuit:) ) {
		[anItem setTitle:([[NSUserDefaults standardUserDefaults] boolForKey:kDelayQuit]
                          ? @"Quit Quicksilver..."
                          : @"Quit Quicksilver")];
	}
	return YES;
}

- (NSProgressIndicator *)progressIndicator
{
    return [interfaceController progressIndicator];
}

- (void)displayStatusMenuAtPoint:(NSPoint)point
{
	QSLog(@"display %f.%f", point.x, point.y);
	NSEvent *theEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:NSMakePoint(500, 500)
									modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0];
	
	[NSMenu popUpContextMenu:[self statusMenu] withEvent:theEvent forView:nil withFont:nil];
}

- (NSMenu *)statusMenu { return [NSApp mainMenu];  }

- (NSMenu *)statusMenuWithQuit
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults boolForKey:@"QSUseFullMenuStatusItem"]) {
		return [NSApp mainMenu];  
	}
	NSMenu *newMenu = [[statusMenu copy] autorelease];
	NSMenuItem *modulesItem = [[NSApp mainMenu] itemWithTag:128];
	
	[newMenu addItem:[[modulesItem copy] autorelease]];
    [newMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *quitItem = [[[NSMenuItem alloc] initWithTitle:@"Quit Quicksilver" action:@selector(terminate:) keyEquivalent:@""] autorelease];
	[quitItem setTarget:NSApp];
	[newMenu addItem:quitItem];
	
	return newMenu;
}

- (void)activateInterfaceTransmogrified:(id)sender
{
	NSWindow *modal = [NSApp modalWindow];
	if (modal) {
		NSBeep();
		[NSApp activateIgnoringOtherApps:YES];
		[modal makeKeyAndOrderFront:self];
	} else {
		id iController = [self interfaceController];
		if (!iController)
			NSBeep();
		[iController activateInTextMode:self];
	}
}

- (void)activateInterface:(id)sender
{
	NSWindow *modal = [NSApp modalWindow];
	if (modal) {
		NSBeep();
		[NSApp activateIgnoringOtherApps:YES];
		[modal makeKeyAndOrderFront:self];
	} else {
	
		QSInterfaceController* iController = [self interfaceController];
		
		if (!iController)
			NSBeep();
		[iController activate:self];
	}
}

- (void)openURL:(NSURL *)url
{
	AESetInteractionAllowed(kAEInteractWithSelf);
	if ([[url scheme] isEqualToString:@"qsinstall"]) {
		QSLog(@"Install: %@", url);
		[[QSPlugInManager sharedInstance] handleInstallURL:url];
	} else if ([[url scheme] isEqualToString:@"qs"]) {
		id handler = [QSReg instanceForKey:[url host] inTable:@"QSInternalURLHandlers"];
		
		//if (VERBOSE) QSLog(@"Handling %@ [%@] ", url, handler);
		if ([handler respondsToSelector:@selector(handleURL:)]) {
			[handler handleURL:url];
		}
	} else {
		QSObject *entry;
		entry = [QSObject URLObjectWithURL:[url absoluteString] title:[NSString stringWithFormat:@"Search %@", [url host]]];
		[entry loadIcon];
		[[self interfaceController] selectObject:entry];
		[self activateInterface:self];
		[[self interfaceController] shortCircuit:self];
	}
	return;
}

- (void)showSplash:sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSImage *splashImage = [NSImage imageNamed:@"QSLigature"];
	if ((fALPHA && OneIn(1000)) || ((fDEV && OneIn(20) ))) splashImage = [self daedalusImage];
	
    splashWindow = [NSWindow windowWithImage:splashImage];
    
    if ([NSApp isPrerelease]) {
        NSRect rect = NSMakeRect(28, 108, 88, 24);
        rect = NSInsetRect(rect, 1, 1);
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRoundedRectangle:rect withRadius:12];
        [[NSColor colorWithCalibratedRed:0.0 green:0.33 blue:0.0 alpha:0.8] set];
        [path fill]; 			
        [[splashWindow contentView] lockFocus];
        NSAttributedString *string = [[[NSAttributedString alloc] initWithString:@"prerelease" 
                                                                   attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]]autorelease];
        [string drawWithRect:NSOffsetRect(centerRectInRect(rectFromSize([string size]), rect), 0, 4) options:NSStringDrawingOneShot];
        [path addClip];
        [QSGlossClipPathForRectAndStyle(rect, 4) addClip];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.1] set];
        NSRectFillUsingOperation(rect, NSCompositeSourceOver);
        
        [[splashWindow contentView] unlockFocus];
    }
	[splashWindow reallyCenter];
	[splashWindow setAlphaValue:0];
	[splashWindow setSticky:YES];
	
	if ([NSApp wasLaunchedAtLogin]) {		
		[splashWindow setLevel:NSNormalWindowLevel-1];
		[splashWindow orderFront:self];
		[splashWindow setAlphaValue:0.25 fadeTime:0.333];
	} else {
		[splashWindow orderFront:self];
		QSWindowAnimation *animation = [QSWindowAnimation showHelperForWindow:splashWindow];
		[animation setTransformFt:QSExtraExtraEffect];
		[animation setDuration:1.0];
		[animation setAnimationBlockingMode:NSAnimationBlocking];
		[animation startAnimation];
	}
	[pool release];
}

- (void)hideSplash:sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (splashWindow) {
		[splashWindow setLevel:NSFloatingWindowLevel];
		[splashWindow flare:self];
		[splashWindow close];
		splashWindow = nil;
	}
	[pool release];
}

- (void)startDropletConnection
{
	if (dropletConnection) return;
	dropletConnection = [[NSConnection new] autorelease];
	[dropletConnection registerName:@"Quicksilver Droplet"];
	[dropletConnection setRootObject:self];
}

- (void)executeCommandAtPath:(NSString *)path
{
	QSCommand *command = [QSCommand commandWithFile:path];
	[command execute];
}

- (void)handlePasteboardDrop:(NSPasteboard *)pb commandPath:(NSString *)path
{
	QSObject *drop = [QSObject objectWithPasteboard:pb];
	[self setDropletProxy:drop];
	[self executeCommandAtPath:path];
	[self setDropletProxy:nil];
}

- (void)searchGoogle:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{    
	if (VERBOSE) QSLog(@"Search Google: %@ %d", userData, [userData characterAtIndex:0]);
	NSWorkspace* sharedSpace = [NSWorkspace sharedWorkspace];
	NSString* queryStr = [NSString stringWithFormat:@"http://www.google.com/search?q=%@&ie=UTF-8",
						  [[pboard stringForType:NSStringPboardType] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[sharedSpace openURL:[NSURL URLWithString:queryStr]];
}

- (void)getSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{    
	if (VERBOSE) QSLog(@"GetSel Service: %@ %d", userData, [userData characterAtIndex:0]);
	[self receiveObject:[[[QSObject alloc] initWithPasteboard:pboard] autorelease]];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
	[self receiveObject:[[QSObject alloc] initWithPasteboard:pboard]];
	return YES;
}

- (void)receiveObject:(QSObject *)object
{
	[[self interfaceController] selectObject:object];
	[self activateInterface:self];
}

@synthesize dropletProxy;

- (void)dealloc
{
    [dropletProxy release], dropletProxy = nil;
    [super dealloc];
}

- (id)resolveProxyObject:(id)proxy
{	
	if ([[proxy identifier] isEqualToString:@"QSDropletItemProxy"]) {
		return dropletProxy;
	} else {
		QSObject *object = [[[self interfaceController] dSelector] objectValue];
		if ([object isKindOfClass:[QSProxyObject class]])
			return nil;
		if ([object isEqual:proxy])
			return nil;
		return object;
	}
	return nil;
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	if ([key isEqual:@"AESelection"]) return YES;
	return NO;
}

//Notifications
- (void)appLaunched:(NSNotification*)notif
{
	NSString *launchedApp = [[notif userInfo] objectForKey:@"NSApplicationName"];
	if ([launchedApp isEqualToString:@"Dock0"]) {
		QSLog(@"%@ Launching ", launchedApp);
	}
}

- (void)appChanged:(NSNotification *)aNotification
{
	NSString *currentApp = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"];
	if (![currentApp isEqualToString:@"Quicksilver"])
		[[NSNotificationCenter defaultCenter] postNotificationName:QSWindowsShouldHideNotification object:self];
}

- (void)delayedStartup
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (DEBUG_STARTUP) QSLog(@"Delayed Startup");
	
	[NSThread setThreadPriority:0.0];
	
	QSTask *task = [QSTask taskWithIdentifier:@"QSDelayedStartup"];
	[task setStatus:@"Updating Catalog"];
	[task startTask:self];
	[QSLib loadMissingIndexes];
	[task stopTask:self];	
	
	[pool release];
}

- (NSString *)internetDownloadLocation
{
	NSDictionary *icDict = [(NSDictionary *)CFPreferencesCopyValue((CFStringRef) @"Version 2.5.4", (CFStringRef) @"com.apple.internetconfig", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
	NSData *data = [[[icDict objectForKey:@"ic-added"] objectForKey:@"DownloadFolder"] objectForKey:@"ic-data"];
	return [[[NDAlias aliasWithData:data] path] stringByStandardizingPath];
}

- (void)checkForFirstRun
{
	QSApplicationLaunchStatusFlags status = [NSApp checkLaunchStatus];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	int lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;

	switch (status) {
		case QSApplicationUpgradedLaunch:
			if (fBETA && lastLocation && ![bundlePath isEqualToString:[lastLocation stringByStandardizingPath]]) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunAlertPanel(@"Running from a new location", @"The previous version of Quicksilver was located in \"%@\". Would you like to move this new version to that location?", @"Move and Relaunch", @"Don't Move", nil, [[lastLocation stringByDeletingLastPathComponent] lastPathComponent]);
				
				if (selection) {
					[NSApp relaunchAtPath:lastLocation movedFromPath:bundlePath];
				}
			}
			
			if ([defaults boolForKey:kShowReleaseNotesOnUpgrade] && (!DEBUG) ) {
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Quicksilver has been updated", nil] , @"You are using a new version of Quicksilver. Would you like to see the Release Notes?", @"Show Release Notes", @"Ignore", nil);
				
				if (selection == 1)
					[self showReleaseNotes:self];
			}
			
			[[NSWorkspace sharedWorkspace] setComment:@"Quicksilver" forFile:[[NSBundle mainBundle] bundlePath]];
			
			if (lastVersion < [@"2000" hexIntValue]) {
                NSFileManager* fileMan = [NSFileManager defaultManager];
				[fileMan moveItemAtPath:QSApplicationSupportSubPath(@"PlugIns", NO)
                                 toPath:QSApplicationSupportSubPath(@"PlugIns (B40 Incompatible) ", NO)
                                error:NULL]; 				
				[fileMan moveItemAtPath:@"/Library/Application Support/Quicksilver/PlugIns"
                                 toPath:@"/Library/Application Support/Quicksilver/PlugIns (B40 Incompatible) "
                                  error:nil]; 				
			}
				newVersion = YES;
			break;
		case QSApplicationDowngradedLaunch:
			[NSApp activateIgnoringOtherApps:YES];
			int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"This is an old version of Quicksilver", nil] ,
													   @"You have previously used a newer version. Perhaps you have duplicate copies?", @"Reveal this copy", @"Ignore", nil);
			
			if (selection == 1) {
				[[NSWorkspace sharedWorkspace] selectFile:[[NSBundle mainBundle] bundlePath] inFileViewerRootedAtPath:@""];
			}
				break;
		case QSApplicationFirstLaunch:
		 {
			NSString *containerPath = [[bundlePath stringByDeletingLastPathComponent] stringByStandardizingPath];
			BOOL shouldInstall = [containerPath isEqualToString:@"/Volumes/Quicksilver"] || [containerPath isEqualToString:[self internetDownloadLocation]];
			
			if (shouldInstall) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunAlertPanel(@"Would you like to install Quicksilver?", @"Quicksilver was launched from a download location.\rWould you like to copy Quicksilver to your applications folder?", @"Install in \"Applications\"", @"Quit", @"Choose Location...");
				NSString *installPath = nil;
				if (selection == 1) {
					installPath = @"/Applications";
				} else if (selection == -1) {
					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
					[openPanel setCanChooseDirectories:YES];
					[openPanel setCanChooseFiles:NO];
					[openPanel setPrompt:@"Install Here"];
					[openPanel setTitle:@"Install Quicksilver"];
					if (NSFileHandlingPanelOKButton == [openPanel runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] file:nil]) {
						installPath = [openPanel filename];
					}
				}
				
				if (installPath) {
					QSLog(@"Installing Quicksilver at: %@", installPath);
					installPath = [installPath stringByAppendingPathComponent:[bundlePath lastPathComponent]];
					[NSApp relaunchAtPath:installPath movedFromPath:bundlePath];
					
				}
				[NSApp terminate:self];
			}
		}
			break;
		default: // QSApplicationNormalLaunch:
			break;
	}
	if (![defaults boolForKey:kSetupAssistantCompleted] || lastVersion <= [@"3694" hexIntValue] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"QSAgreementAccepted"]) { //Never Run Before
		runningSetupAssistant = YES;
	} 	
	[NSApp updateLaunchStatusInfo];
}


- (QSInterfaceController *)interfaceController
{
	return [QSReg preferredCommandInterface];
}

- (void)setInterfaceController:(QSInterfaceController *)newInterfaceController {
	if (interfaceController) {
		[[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllCachesNotification object:self];
		
	}
	[interfaceController release];
	interfaceController = [newInterfaceController retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceChangedNotification object:self];
}

@synthesize iconColor;

- (NSImage *)daedalusImage
{
	return [QSResourceManager imageNamed:@"daedalus"];
}

@end

@implementation QSController (QSNotifications)

- (void)activated:(NSNotification *)aNotification
{
	if ( (fALPHA && OneIn(100) ) || (fDEV && OneIn(10))) {
		[NSApp setApplicationIconImage:[self daedalusImage]];
    } else {
		[NSApp setApplicationIconImage:[NSImage imageNamed:@"Quicksilver-Activated"]];
    }
}

- (void)deactivated:(NSNotification *)aNotification 
{
	[NSApp setApplicationIconImage: [NSImage imageNamed:@"Quicksilver-Running"]];
}

@end

@implementation QSController (IBActions)
- (IBAction)runSetupAssistant:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	runningSetupAssistant = YES;
	[[QSSetupAssistant sharedInstance] run:self];
}

- (IBAction)showForums:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kForumsURL]];
}

- (IBAction)openIRCChannel:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kIRCURL]];
}

- (IBAction)reportABug:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kBugsURL]];
}

- (IBAction)showElementsViewer:(id)sender
{
    QSElementsViewController *viewer = [QSElementsViewController sharedController];
    [viewer showWindow:nil];
}

- (IBAction)showAbout:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	if (!aboutWindowController) {
		aboutWindowController = [[QSAboutWindowController alloc] init];
	}
	[aboutWindowController showWindow:self];
}

- (IBAction)showAgreement:(id)sender
{
	[QSAgreementController showAgreement:sender];
}

- (IBAction)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
	[QSPreferencesController showPrefs];
}

- (IBAction)donate:(id)sender
{
	NSString *baseURL = @"http://quicksilver.blacktree.com/contribute.php";
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:baseURL]];
}

- (IBAction)sendReleaseAll:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllNotification object:nil];
}

- (IBAction)showGuide:(id)sender
{
	[QSPreferencesController showPaneWithIdentifier:@"QSMainMenuPrefPane"];
}

- (IBAction)showSettings:(id)sender
{
	[QSPreferencesController showPaneWithIdentifier:@"QSSettingsPanePlaceholder"];
}

- (IBAction)showCatalog:(id)sender
{
	[QSPreferencesController showPaneWithIdentifier:@"QSCatalogPrefPane"];
}

- (IBAction)showTriggers:(id)sender
{
	[QSPreferencesController showPaneWithIdentifier:@"QSTriggersPrefPane"];
}

- (IBAction)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kHelpURL]];
}

- (IBAction)getMorePlugIns:(id)sender
{
	[QSPlugInsPrefPane getMorePlugIns];
	//	NSString *baseURL = @"http://quicksilver.blacktree.com/plugins.php?feature = ";
	//	int feature = [NSApp featureLevel];
	//	switch (feature) {
	//		case 3: baseURL = [baseURL stringByAppendingString:@"Daedalus"]; break;
	//		default: baseURL = [baseURL stringByAppendingFormat:@"%d", feature]; break;
	//	}
	//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:baseURL]];
}

- (IBAction)unsureQuit:(id)sender
{
	if ([[NSApp currentEvent] type] == NSKeyDown && [[NSUserDefaults standardUserDefaults] boolForKey:kDelayQuit]) {
		if ([[NSApp currentEvent] isARepeat]) return;
		
		QSWindow *quitWindow = nil;
		if (!quitWindowController) {
			quitWindowController = [NSWindowController alloc];
			[quitWindowController initWithWindowNibName:@"QuitConfirm" owner:quitWindowController];

			quitWindow = (QSWindow *)[quitWindowController window];
			[quitWindow setLevel:kCGStatusWindowLevel+1];
			[quitWindow setIgnoresMouseEvents:YES]; [quitWindow center];
			[quitWindow setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect", @"transformFn", @"show", @"type", [NSNumber numberWithFloat:0.15] , @"duration", nil]];
			[quitWindow setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithFloat:0.25] , @"duration", nil]];
		} else {
			quitWindow = (QSWindow *)[quitWindowController window];
		}		
		NSString *currentCharacters = [[NSApp currentEvent] charactersIgnoringModifiers];
		[quitWindow orderFront:self];
		
		NSEvent *theEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.625] inMode:NSDefaultRunLoopMode dequeue:YES];
		
		BOOL shouldQuit = !theEvent;
		
		if (theEvent) {
			theEvent = [NSApp nextEventMatchingMask:NSKeyDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.625] inMode:NSDefaultRunLoopMode dequeue:YES];
			if ([[theEvent charactersIgnoringModifiers] isEqualToString:currentCharacters])
				shouldQuit = YES;
		}
		
		if (shouldQuit) {
			[(NSButton *)[quitWindow initialFirstResponder] setState:NSOnState];
			[[(NSButton *)[quitWindow initialFirstResponder] alternateImage] setSize:QSSize128];
			[[(NSButton *)[quitWindow initialFirstResponder] alternateImage] setFlipped:NO];
			[quitWindow display];
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.333]];
			[quitWindow orderOut:self];
			
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.50]];
			[NSApp terminate:self];  
		}
		[quitWindow orderOut:self];
		// }
	} else {
		[NSApp terminate:self];  
	}
}

- (IBAction)showTaskViewer:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[QSTaskViewer sharedInstance] showWindow:self];
} 

- (IBAction)rescanItems:sender
{
	[[QSLibrarian sharedInstance] startThreadedScan];
}

- (IBAction)forceRescanItems:sender
{
	[[QSLibrarian sharedInstance] startThreadedAndForcedScan];
}

- (IBAction)showReleaseNotes:(id)sender
{
	NSString *readMeFile = [[[NSBundle mainBundle] bundlePath]
                            stringByAppendingPathComponent:@"Contents/SharedSupport/Changes.html"];
	[[NSWorkspace sharedWorkspace] openFile:readMeFile];
}
@end

@implementation QSController (AppleEvents)

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent
{
}

- (id)selection
{
	return [NSAppleEventDescriptor descriptorWithString:@"string"]; 	
}


- (void)setAESelection:(NSAppleEventDescriptor *)desc  types:(NSArray *)types
{
	QSObject *object = nil;
	if ([desc isKindOfClass:[NSString class]]) {
		object = [QSObject objectWithString:(NSString *)desc];
	} else if ([desc isKindOfClass:[NSArray class]]) {
		object = [QSObject fileObjectWithArray:(NSArray *)desc];
	} else if (fDEV) {
		QSLog(@"descriptor %@ %@", NSStringFromClass([desc class]), desc);
		object = [QSObject objectWithAEDescriptor:desc  types:(NSArray *)types];
	}
	QSLog(@"object %@", object);
	[self receiveObject: object];
}

- (void)setAESelection:(NSAppleEventDescriptor *)desc {
	[self setAESelection:desc types:nil];
}

- (NSAppleEventDescriptor *)AESelection {	
	QSObject *selection = (QSObject*)[[self interfaceController] selection];
	QSLog(@"object %@", selection);
	id desc = [selection AEDescriptor];
	if (!desc) desc = [NSAppleEventDescriptor descriptorWithString:[selection stringValue]];
	return desc;
}
@end

@implementation QSController (Connection)

- (void)startMenuExtraConnection
{
	if (controllerConnection) return;
	controllerConnection = [NSConnection new];
    [controllerConnection setRootObject:self];
	if( [controllerConnection registerName:@"QuicksilverControllerConnection"] == NO) {
        QSLog( @"Failed registering service." );
    }
}

- (void) stopMenuExtraConnection
{
    if( !controllerConnection ) return;
    if( [controllerConnection registerName:nil] == NO ) {
        QSLog( @"Failed unregistering service." );
    }
}

- (BOOL) connection:(NSConnection *)conn handleRequest:(NSDistantObjectRequest *)doReq
{
	return NO;
}

- (BOOL) connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnnection
{
	return YES;
}
#pragma mark NSConnection Delegate messages

- (void)connectionDidInitialize:(NSNotification*)notif { }

- (void)connectionDidDie:(NSNotification*)notif { }

@end

#pragma mark -
@implementation QSController (Application)

//- (void)applicationDidResignActive:(NSNotification *)aNotification {}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
	[[NSImage imageNamed:@"NSApplicationIcon"] setSize:NSMakeSize(128, 128)];
	//  QSLog(@"%@", [NSImage imageNamed:@"NSApplicationIcon"])
	[NSApp setApplicationIconImage: [NSImage imageNamed:@"NSApplicationIcon"]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSEventNotification object:QSQuicksilverWillQuitEvent userInfo:nil];
	//QSLog(@"notif");
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSWindowsShouldHideNotification object:self];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self stopMenuExtraConnection];
	//	if (DEBUG) [self writeLeaks];
}

- (void)writeLeaks {
	FILE* fp;
	size_t len;
	char cmd[32] , buf[512];
	snprintf(cmd, sizeof(cmd), "/usr/bin/leaks %d", getpid() );
	if ((fp = popen(cmd, "r") ))
	 {
		while(( len = fread(buf, 1, sizeof(buf), fp) ))
			fwrite(buf, 1, len, stderr);
		pclose(fp);
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	if (DEBUG) {
		[self registerForErrors];
	}
}

- (void)setupSplash {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self showSplash:nil];
		//[NSThread detachNewThreadSelector:@selector(showSplash:) toTarget:self withObject:nil];
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(threadedHideSplash) userInfo:nil repeats:NO];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadedHideSplash) name:@"QSApplicationReallyDidFinishLaunching" object:NSApp]; 	
	}
	
}
- (void)startQuicksilver:(id)sender {
	//	QSLog(@"%@", [[NSProcessInfo processInfo] processName]);
	//
	//			id object = [[NSObject alloc] init];
	//			QSLog(@"Object %@", object);
	//			[object release];
	//			QSLog(@"Object %@", object);
	//		
	
	
	
	[self checkForFirstRun];
	
	NSString *equiv = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSServiceMenuKeyEquivalent"];
	//QSLog(@"Setting service %@", equiv);
	if (equiv && ![equiv isEqualToString:[NSApp keyEquivalentForService:@"Quicksilver/Send to Quicksilver"]]) {
		QSLog(@"Setting Service Key Equivalent to %@", equiv);
		[NSApp setKeyEquivalent:equiv forService:@"Quicksilver/Send to Quicksilver"];
	}
	
	//[self daedalusImage];
	// Show Splash Screen
	BOOL atLogin = [NSApp wasLaunchedAtLogin];
	if (!atLogin)
		[self setupSplash];
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (DEBUG_STARTUP) 
		QSLog(@"Instantiate Classes");
	
	[QSMnemonics sharedInstance];
	[QSLibrarian sharedInstance];
	[QSExecutor sharedInstance];
	[QSTaskController sharedInstance];
	//[QSTaskViewer sharedInstance];
	
	if (DEBUG_STARTUP)
		QSLog(@"Library loaded");
	
	// [[QSPlugInManager sharedInstance] loadPlugInsAtLaunch];
	if (DEBUG_STARTUP) 
		QSLog(@"PlugIns loaded");
	
	[QSLib initCatalog];
	
	
	
	
	[QSLib pruneInvalidChildren:nil];
	[QSLib loadCatalogInfo];
	//	[QSReg instantiatePlugIns];
	
	//	[QSReg suggestOldPlugInRemoval];
	
	[QSExec loadFileActions];
	
	[QSLib reloadIDDictionary:nil];
	[QSLib enableEntries];
	
	if (DEBUG_STARTUP)
		QSLog(@"Catalog loaded");
	
	[QSObject purgeIdentifiers];
	
	if (newVersion && (!DEBUG) ) {
		if (!runningSetupAssistant) {
			QSLog(@"New Version: Purging all Identifiers and Forcing Rescan");
			[QSLibrarian removeIndexes];
			//[[QSProcessMonitor sharedInstance] reloadProcesses];
			[QSLib startThreadedAndForcedScan];
		}
		//#warning REMOVE ME
		//		QSLog(@"deleting plugin cache");
		//		[[NSFileManager defaultManager] removeFileAtPath:QSApplicationSupportSubPath(@"PlugIns.plist", NO) handler:nil];
	} else {
		[QSLib loadCatalogArrays];
	}
	
	[QSLib reloadEntrySources:nil];
	if (atLogin)
		[self setupSplash];
	
	// Instantiate some Classes
	
	//[QSPasteboardMonitor sharedInstance];
	//		if ([defaults boolForKey:kCapturePasteboardHistory]) /
	//			[QSPasteboardController sharedInstance];
	QSSandBoxMain();
	
	
	
	[NSApp setServicesProvider:self];
	
	//  NSConnection *serviceConnection = [[NSConnection allConnections] lastObject];
	
	//QSLog(@"port %@",
	//     [NSConnection connectionWithRegisteredName:@"Stickies" host:nil]);
	
	//QSLog(@"port %d", [[serviceConnection receivePort] machPort]);
	// [serviceConnection setDelegate:self];
	// Setup Activation Hotkey
	
	//HotKeyCenter *center = [HotKeyCenter sharedCenter];
	//id keyCombo = [KeyCombo keyComboWithKeyCode:
	//							 andModifiers:;
	//[center addHotKey:kActivationHotKey combo:keyCombo target:self action:];
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"QSModifierActivationCount"] > 0) {
		QSModifierKeyEvent *modActivation = [[[QSModifierKeyEvent alloc] init] autorelease];
		[modActivation setModifierActivationMask:[[NSUserDefaults standardUserDefaults] integerForKey:@"QSModifierActivationKey"]];
		[modActivation setModifierActivationCount:[[NSUserDefaults standardUserDefaults] integerForKey:@"QSModifierActivationCount"]];
		[modActivation setTarget:self];
		[modActivation setIdentifier:@"QSModKeyActivation"];
		[modActivation setAction:@selector(activateInterface:)];
		[modActivation enable];
	}
	
	//if (newVersion) {
	id oldModifiers = [defaults objectForKey:kHotKeyModifiers];
	id oldKeyCode = [defaults objectForKey:kHotKeyCode];
	
	
	//Update hotkey prefs
	
	if (oldModifiers && oldKeyCode) {
		int modifiers = [oldModifiers unsignedIntValue];
		if (modifiers < (1 << (rightControlKeyBit+1) )) {
			QSLog(@"updating hotkey %d", modifiers);
			[defaults setValue:[NSNumber numberWithInt:carbonModifierFlagsToCocoaModifierFlags(modifiers)] forKey:kHotKeyModifiers];
			[defaults synchronize];
		}
		
		
		QSLog(@"Updating Activation Key");
		[defaults removeObjectForKey:kHotKeyModifiers];
		[defaults removeObjectForKey:kHotKeyCode];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:oldModifiers, @"modifiers", oldKeyCode, @"keyCode", nil];
		[defaults setObject:dict forKey:@"QSActivationHotKey"];
		[defaults synchronize];
	}
	
	//}
	[self bind:@"activationHotKey"
	  toObject:[NSUserDefaultsController sharedUserDefaultsController]
   withKeyPath:@"values.QSActivationHotKey"
	   options:nil];


	quitWindowController = nil;
	aboutWindowController = nil;

	//   [self setUpdateTimer];

	int rescanInterval = [defaults integerForKey:@"QSCatalogRescanFrequency"];
	if (rescanInterval > 0) {
		
		if (DEBUG_STARTUP) QSLog(@"Rescanning every %d minutes", rescanInterval);
		
		[[NSTimer scheduledTimerWithTimeInterval:rescanInterval*60 target:self selector:@selector(rescanItems:) userInfo:nil repeats:YES] retain];
	}


	if (DEBUG_STARTUP) QSLog(@"Register for Notifications");
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];

	if (fSPECIAL)
	[[NSTimer scheduledTimerWithTimeInterval:60*10 target:self selector:@selector(recompositeIconImages) userInfo:nil repeats:YES] retain];
	else if (fBETA)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recompositeIconImages) name:NSSystemColorsDidChangeNotification object:nil];
	else
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recompositeIconImages) name:NSControlTintDidChangeNotification object:NSApp];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidInitialize:) name:NSConnectionDidInitializeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];

	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appWillLaunch:) name:NSWorkspaceWillLaunchApplicationNotification object: nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) 
															name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil];

	//QSLog(@"%@", [[NSProcessInfo processInfo] environment]);

	//[QSAppearanceController sharedInstance];

	[[[NSApp mainMenu] itemAtIndex:0] setTitle:@"Quicksilver"];  

	//	[[[NSApp setDoc]]itemAtIndex:0] setTitle:@"Quicksilver"];  
	if (DEBUG_STARTUP) QSLog(@"Will Finish Launching");


	if (DEBUG || PRERELEASEVERSION) {
		[self activateDebugMenu];
	}


	if (!runningSetupAssistant) {
		[self hideSplash:nil];
		[self runSetupAssistant:nil];
		
	}
	//QSLog()
	char *visiblePref = getenv("QSVisiblePrefPane");
	if (visiblePref) {
	//	QSLog(@"reopeningpref %s", visiblePref);
		[QSPreferencesController showPaneWithIdentifier:[NSString stringWithUTF8String:visiblePref]];
	}
	//if ([defaults boolForKey:@"QSPasteboardHistoryIsVisible"])
	//	[self showClipboards:self];


	//	if (fDEV) {
	//		NSMenuItem *serviceItem = [[[NSMenuItem alloc] initWithTitle:@"Services" action:nil keyEquivalent:@""] autorelease];
	//		[serviceItem setSubmenu:[[NSMenu alloc] initWithTitle:@"Services"]];
	//		[[NSApp mainMenu] insertItem:serviceItem atIndex: [[NSApp mainMenu] indexOfItemWithSubmenu:[NSApp windowsMenu]]+1];
	//		
	//		[NSApp setServicesMenu:[serviceItem submenu]];
	//	}

	[QSResourceManager sharedInstance];

	//if (fBETA)
	//[[QSTriggerCenter sharedInstance] activateTriggers];
	if (DEBUG_STARTUP) QSLog(@"Did Finish Launching\n ");


	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	//if (DEBUG) {
	//	[self setShowStatusMenu:[NSNumber numberWithBool:YES]];
	//} else {

	[self bind:@"showMenuIcon"
	  toObject:[NSUserDefaultsController sharedUserDefaultsController]
   withKeyPath:@"values.QSShowMenuIcon"
	   options:nil];



	//}
	//	
//    if (![(QSApp *)NSApp isUIElement]) {
        [NSApp setApplicationIconImage: [NSImage imageNamed:@"Quicksilver-Running"]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(activated:)
                                                     name:QSInterfaceActivatedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deactivated:)
                                                     name:QSInterfaceDeactivatedNotification
                                                   object:nil];
//    }
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kAutomaticTaskViewer])
	[QSTaskViewer sharedInstance];


	if (!runningSetupAssistant) {
		if (!newVersion) {
			[self rescanItems:self];
		}
	}
	if (newVersion && !DEBUG) [[QSUpdateController sharedInstance] forceStartupCheck];

	[[QSUpdateController sharedInstance] setUpdateTimer];


	/*
	 NSMenuView *view = [[QSMenuView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
	 
	 NSWindow *menuWindow = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 00, 200, 200) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO] retain];
	 [view setMenu:[self statusMenu]];
	 [menuWindow setContentView:view];
	 [menuWindow center];
	 //[menuWindow setIgnoresMouseEvents:YES];
	 [menuWindow orderFront:self];
	 */

	[self recompositeIconImages];
	[[self interfaceController] window];

	if (atLogin)
	[[NSNotificationCenter defaultCenter] postNotificationName:QSEventNotification object:QSQuicksilverLaunchedAtLoginEvent userInfo:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSEventNotification object:QSQuicksilverLaunchedEvent userInfo:nil];

//	if (defaultBool(@"QSEnableISync") )
//	[[QSSyncManager sharedInstance] setup];

	[NSThread detachNewThreadSelector:@selector(delayedStartup) toTarget:self withObject:nil];

	[self startDropletConnection];

  QSLog(@"LaunchLoaders %@", [[QSRegistry sharedInstance] loadedInstancesForPointID:@"QSLoadAtLaunch"]);
}


- (id)activationHotKey {
	return nil;
}
- (void)setActivationHotKey:(id)object {
	//QSLog(@"SetActivation %@", object); 	
	//Deactivate Old
	
	[[QSHotKeyEvent hotKeyWithIdentifier:kActivationHotKey] setEnabled:NO];
	
	QSHotKeyEvent *activationKey = (QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithDictionary:object];
	[activationKey setTarget:self selectorReleased:(SEL) 0 selectorPressed:@selector(activateInterface:)];
	[activationKey setIdentifier:kActivationHotKey];
	[activationKey setEnabled:YES];
	
}
- (void)threadedHideSplash {
	[NSThread detachNewThreadSelector:@selector(hideSplash:) toTarget:self withObject:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self startQuicksilver:aNotification];
	//OSStatus err = AEInstallEventHandler('GURL', 'GURL', NewAEEventHandlerUPP(handleGURLEvent), 0, false);
	//QSLog(@"err %d", err);
	
}



- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self activateInterface:theApplication];
	return YES;
}



- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
	//	QSLog(@"active");
}

- (void)application:(NSApplication *)app openFiles:(NSArray *)fileList {
	NSArray *plugIns = nil;
	if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObjects:@"qspkg", @"qsplugin", nil]]) count]) {
		[[QSPlugInManager sharedInstance] installPlugInsFromFiles:plugIns];
		return;
	}
	
	
	if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObjects:@"qscatalogentry", nil]]) count]) {
		foreach(path, plugIns) {
		    [QSCatalogPrefPane addEntryForCatFile:path];
		}
		return;
	}
	
	if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObjects:@"qscommand", nil]]) count]) {
		foreach(path, plugIns) {
		    [self executeCommandAtPath:path];
		}
		return;
	}
	
	
	QSObject *entry;
	entry = [QSObject fileObjectWithArray:fileList];
	[entry loadIcon];
	[[self interfaceController] selectObject:entry];
	[self activateInterface:self];
	return;
}


- (NSApplicationPrintReply) application:(NSApplication *)application printFiles:(NSArray *)fileNames withSettings:(NSDictionary *)printSettings showPrintPanels:(BOOL)showPrintPanels {
	QSLog(@"Print %@ using %@ show %d", fileNames, printSettings, showPrintPanels) 	;
	return NSPrintingFailure;
}

@end

void QSSignalHandler(int i) {
	printf("signal %d", i);
	QSLog(@"Current Tasks %@", [[QSTaskController sharedInstance] tasks]);
	[NSApp activateIgnoringOtherApps:YES];
	int result = NSRunCriticalAlertPanel(@"An error has occured", @"Quicksilver must be relaunched to regain stability.", @"Relaunch", @"Quit", nil, i);
    QSLog(@"result %d", result);
	if (result == 1) {
		[NSApp relaunch:nil];
	}
	exit(-1);
}

@implementation QSController (ErrorHandling)
- (void)registerForErrors {
				return;
	signal(SIGBUS, QSSignalHandler);
	signal(SIGSEGV, QSSignalHandler);
	
	if (fDEV) {
		NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
		[handler setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
		[handler setDelegate:self];
	}
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask
{
	[exception printStackTrace];
	return NO; 	
} // mask is QSLog < exception type > Mask, exception's userInfo has stack trace for key NSStackTraceKey

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask
{
	
	return YES;
}

@end








