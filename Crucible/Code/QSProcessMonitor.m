/*
 *  Derived from Blacktree, Inc. codebase
 *  2010-01-16 Makoto Yamashita
 */

#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDProcess.h"
#import "NDProcess+QSMods.h"

#import "QSProcessMonitor.h"
#import "QSTypes.h"

#import "NSEvent+BLTRExtensions.h"
#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"
OSStatus GetPSNForAppInfo(ProcessSerialNumber *psn,NSDictionary *theApp){
    if (!theApp) return 1;
    (*psn).highLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    (*psn).lowLongOfPSN=[[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    return noErr;
}
@implementation QSProcessMonitor
+ (id)sharedInstance{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[self allocWithZone:[self zone]] init];
    return _sharedInstance;
}

+ (NSArray *)processes
{
    NSMutableArray *resultsArray=[NSMutableArray array];
    ProcessSerialNumber serialNumber;
    
    Str255                             procName;
    serialNumber.highLongOfPSN = kNoProcess;
    serialNumber.lowLongOfPSN  = kNoProcess;

    ProcessInfoRec             procInfo;
#ifdef __LP64__
	FSRef appFSRef;
	procInfo.processAppRef = &appFSRef;
#else
    FSSpec appFSSpec;
    procInfo.processAppSpec = &appFSSpec;
#endif
    
    procInfo.processInfoLength              = sizeof(ProcessInfoRec);
    procInfo.processName                    = procName;
    
    while (procNotFound != GetNextProcess(&serialNumber)) {
        if (noErr == GetProcessInformation(&serialNumber, &procInfo)) {
            if ('\0' == procName[1]) procName[1] = '0';
            
            NSString *procName = (NSString*)CFStringCreateWithPascalString(NULL,procInfo.processName,kCFStringEncodingMacRoman);
            [resultsArray addObject:[procName autorelease]];
        }
    }
    return resultsArray;
}


OSStatus appChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	QSLog(@"app change event unhandled!\n");
	return CallNextEventHandler(nextHandler, theEvent);
}




- (void)regisiterForAppChangeNotifications{
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassApplication;
	eventType.eventKind = kEventAppFrontSwitched;
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(appChanged);
	OSStatus err=InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, &eventType, NULL, NULL);
	if (err) QSLog(@"gmod registration err %d",err);
}

- (id) init{
    if ((self=[super init])){
		[self regisiterForAppChangeNotifications];
		processes=[[NSMutableArray arrayWithCapacity:1]retain];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object: nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object: nil];
		//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil];
		
	   }
    return self;
}


- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn
{
    QSObject *thisProcess;
	ProcessSerialNumber thisPSN;
	Boolean match;
	
    for(thisProcess in processes){
		NSDictionary *info=[thisProcess objectForType:QSProcessType];
		GetPSNForAppInfo(&thisPSN,info);
		SameProcess(&psn,&thisPSN,&match);
		if (match) return thisProcess;
	}
	return nil;
}

- (NSDictionary *)infoForPSN:(ProcessSerialNumber)processSerialNumber
{
    NSDictionary *dict = (NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber,kProcessDictionaryIncludeAllInformationMask);
    dict = [[[dict autorelease] mutableCopy] autorelease];

    [dict setValue:[dict objectForKey:@"CFBundleName"]
            forKey:@"NSApplicationName"];

    [dict setValue:[dict objectForKey:@"BundlePath"]
            forKey:@"NSApplicationPath"];

    [dict setValue:[dict objectForKey:@"CFBundleIdentifier"]
            forKey:@"NSApplicationBundleIdentifier"];

    [dict setValue:[dict objectForKey:@"pid"]
            forKey:@"NSApplicationProcessIdentifier"];

    [dict setValue:[NSNumber numberWithLong:processSerialNumber.highLongOfPSN]
            forKey:@"NSApplicationProcessSerialNumberHigh"];

    [dict setValue:[NSNumber numberWithLong:processSerialNumber.lowLongOfPSN]
            forKey:@"NSApplicationProcessSerialNumberLow"];
  
	return dict;
}


- (BOOL)handleProcessEvent:(NSEvent *)theEvent
{
	ProcessSerialNumber psn;
	psn.highLongOfPSN=[theEvent data1];
	psn.lowLongOfPSN=[theEvent data2];
	
	NSDictionary *processInfo = [self infoForPSN:psn];
 
  switch ([theEvent subtype]){
		case NSProcessDidLaunchSubType:
			if (![[NSUserDefaults standardUserDefaults]boolForKey:kQSShowBackgroundProcesses]) return YES;
      BOOL background=[[processInfo objectForKey:@"LSUIElement"]boolValue]||[[processInfo objectForKey:@"LSBackgroundOnly"]boolValue];
			if (!background) return YES;
				[self addProcessWithDict: processInfo];
			break;
		case NSProcessDidTerminateSubType:
			[self removeProcessWithPSN:psn];
			break;
		case NSFrontProcessSwitched:
			[[NSNotificationCenter defaultCenter] postNotificationName:QSActiveApplicationChangedNotification object: processInfo];
			[self appChanged:nil];
			break;
    default:
			break;
	}
	return YES;
}

- (void)appChanged:(NSNotification *)aNotification
{
	NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
	NSDictionary *newApp=[workspace activeApplication];
	if ([[NSUserDefaults standardUserDefaults]boolForKey:@"Hide Other Apps When Switching"]) {
		if (!(GetCurrentKeyModifiers() & shiftKey)) {
			[workspace hideOtherApplications:[NSArray arrayWithObject:newApp]];
		}
	}
	[self setPreviousApplication:currentApplication];
	[self setCurrentApplication:newApp];
}

- (void)processTerminated:(QSObject *)thisProcess
{
	[[thisProcess dataDictionary]removeObjectForKey:QSProcessType];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectModifiedNotification object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
	[processes removeObject:thisProcess];
}

- (void)removeProcessWithPSN:(ProcessSerialNumber)psn{
	QSObject *thisProcess=[self processObjectWithPSN:psn];

	[self processTerminated:thisProcess];
}

- (QSObject *)processObjectWithDict:(NSDictionary *)dict
{
	ProcessSerialNumber psn;
    if (noErr==GetPSNForAppInfo(&psn,dict)) {
		return [self processObjectWithPSN:psn];
    }
	return nil;
}

- (void)appTerminated:(NSNotification *)notif
{
	[self processTerminated:[self processObjectWithDict:[notif userInfo]]];	
}

- (void)appLaunched:(NSNotification *)notif
{
    if (![processes count]) {
		[self reloadProcesses];
    } else {
		[self addProcessWithDict:[notif userInfo]];
    }
	[[NSNotificationCenter defaultCenter]
        postNotificationName:QSEventNotification
                      object:QSApplicationLaunchEvent
                    userInfo:[NSDictionary dictionaryWithObject:[self imbuedFileProcessForDict:[notif userInfo]]
                                                         forKey:@"object"]];
}

- (void)addObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger
{
	QSLog(@"Add %@",event);
}
- (void)removeObserverForEvent:(NSString *)event trigger:(NSDictionary *)trigger
{
	QSLog(@"Remove %@",event);
	
}

- (void)addProcessWithDict:(NSDictionary *)info
{
	if ([self processObjectWithDict:info]) return;

	QSObject *thisProcess=[self imbuedFileProcessForDict:info];

	[processes addObject:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSObjectModifiedNotification object:thisProcess];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
}

- (NSArray *)getAllProcesses
{
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses=[NDProcess everyProcess];
	NDProcess *thisProcess;
	pid_t pid=-1;

	for(thisProcess in newProcesses){
		newObject=nil;
        if ((newObject=[self imbuedFileProcessForDict:[thisProcess processInfo]])) {
			[objects addObject:newObject];
        } else {
			QSLog(@"ignoring process id %d",pid);
        }
	}
	return objects;
}

- (NSArray *)getVisibleProcesses
{
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses = [[NSWorkspace sharedWorkspace] runningApplications];
	for (NSRunningApplication *thisProcess in newProcesses) {
        //    NSApplicationPath (the full path to the application, as a string)
        //    NSApplicationName (the application's name, as a string)
        //    NSApplicationBundleIdentifier (the application's bundle identifier, as a string)
        //    NSApplicationProcessIdentifier (the application's process id, as an NSNumber)
        //    NSApplicationProcessSerialNumberHigh (the high long of the PSN, as an NSNumber)
        //    NSApplicationProcessSerialNumberLow (the low long of the PSN, as an NSNumber)
        NSMutableDictionary *appDict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSString *appPath = [[thisProcess bundleURL] path];
        [appDict setObject:appPath forKey:@"NSApplicationPath"];
        [appDict setObject:[thisProcess localizedName] forKey:@"NSApplicationName"];
        [appDict setObject:[thisProcess bundleIdentifier] forKey:@"NSApplicationBundleIdentifier"];
        [appDict setObject:[NSNumber numberWithInt:[thisProcess processIdentifier]] forKey:@"NSApplicationProcessIdentifier"];

        if ((newObject = [self imbuedFileProcessForDict:appDict])) {
			[objects addObject:newObject];
        }
	}
	return objects;
}

- (NSArray *)processesWithHiddenState:(BOOL)hidden
{
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	QSObject *newObject;
	NSArray *newProcesses=[NDProcess everyProcess];

    for (NDProcess *thisProcess in newProcesses) {
		newObject = nil;
		if (hidden && [thisProcess isVisible]) continue;
		else if ([thisProcess isBackground]) continue;
			
		if ((newObject=[self imbuedFileProcessForDict:[thisProcess processInfo]]))
			[objects addObject:newObject];
	}
	return objects;
}

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)appDict
{
    NSString *appPath = [appDict objectForKey:@"NSApplicationPath"];
    NSString *bundlePath=[appPath stringByDeletingLastPathComponent];
	QSObject *newObject = nil;
	if ([[bundlePath lastPathComponent]isEqualToString:@"MacOS"] || [[bundlePath lastPathComponent]isEqualToString:@"MacOSClassic"]) {
		bundlePath=[bundlePath stringByDeletingLastPathComponent];
		// ***warning   * check that this is the executable specified by the info.plist
		if ([[bundlePath lastPathComponent]isEqualToString:@"Contents"]){
			bundlePath=[bundlePath stringByDeletingLastPathComponent];
			newObject=[QSObject fileObjectWithPath:bundlePath];
		}
	}
    if (!newObject) {
		newObject=[QSObject fileObjectWithPath:appPath];
    }
	[newObject setObject:appDict forType:QSProcessType];
	return newObject;
}

- (void)reloadProcesses{ 
	//QSLog(@"Reloading Processes");
	if ([[NSUserDefaults standardUserDefaults]boolForKey:kQSShowBackgroundProcesses])
		[processes setArray:[self getAllProcesses]];
	else
		[processes setArray:[self getVisibleProcesses]];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessesChangedNotification object:nil];
	
	//[self invalidateSelf];
}


-(NSArray *)visibleProcesses{
	return [self allProcesses];
	
}
-(NSArray *)allProcesses{
	if (![processes count])
		[self reloadProcesses];
//	QSLog(@"proc %@",processes);
	return processes;   
}
- (NSDictionary *)previousApplication{
	return previousApplication;	
}

-(id)resolveProxyObject:(id)proxy{
	if ([[proxy identifier]isEqualToString:@"QSCurrentApplicationProxy"]){
		//	QSLog(@"return");
		return [self imbuedFileProcessForDict:[[NSWorkspace sharedWorkspace]activeApplication]];
	}else if ([[proxy identifier] isEqualToString:@"QSPreviousApplicationProxy"]){
		return [self imbuedFileProcessForDict:previousApplication];
	}else if ([[proxy identifier] isEqualToString:@"QSHiddenApplicationsProxy"]){
		return [QSCollection collectionWithArray:[self processesWithHiddenState:YES]];
	}else if ([[proxy identifier] isEqualToString:@"QSVisibleApplicationsProxy"]){
		return [QSCollection collectionWithArray:[self processesWithHiddenState:NO]];
	}
	return nil;
}

- (NSTimeInterval)cacheTimeForProxy:(id)proxy{
	return 0.0f;	
}






- (NSDictionary *)currentApplication {
    return [[currentApplication retain] autorelease]; 
}
- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication {
    if (currentApplication != newCurrentApplication) {
        [currentApplication release];
        currentApplication = [newCurrentApplication copy];
    }
}


- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication {
    if (previousApplication != newPreviousApplication) {
        [previousApplication release];
        previousApplication = [newPreviousApplication copy];
    }
}



- (void)dealloc {
    [self setCurrentApplication:nil];
    [self setPreviousApplication:nil];
    [super dealloc];
}


@end
