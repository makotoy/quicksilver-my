//
//  QSUpdateController.m
//  Quicksilver
//
//  Created by Alcor on 7/22/04.

//  2010-01-09 Makoto Yamashita

#import <QSCrucible/QSPlugInManager.h>
#import <QSCrucible/QSURLDownloadWrapper.h>

#import "QSApp.h"

#import "QSUpdateController.h"

#import <SystemConfiguration/SystemConfiguration.h>

NSString *QSGetPrimaryMACAddress();
UInt64 QSGetPrimaryMACAddressInt();
@implementation QSUpdateController
+ (id)sharedInstance
{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (void)forceStartupCheck
{
	QSLog(@"Updated: Forcing Plug-in Check");
	doStartupCheck = YES;
}

- (void)setUpdateTimer
{
	// ***warning   * fix me
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	if (DEVELOPMENTVERSION ? ![defaults boolForKey:@"QSPreventAutomaticUpdate"] : [defaults boolForKey:kCheckForUpdates]) {
		NSDate *lastCheck = [defaults objectForKey:kLastUpdateCheck];
		int frequency = [defaults integerForKey:kCheckForUpdateFrequency];
		
		int versionType = [defaults integerForKey:@"QSUpdateReleaseLevel"];
		
		if ((versionType>0 || PRERELEASEVERSION) && frequency>1) frequency = 1;
		
		BOOL shouldRepeat = (frequency>0);
		NSTimeInterval checkInterval = frequency*24*60*60;
		NSDate *nextCheck = [[NSDate alloc] initWithTimeInterval:checkInterval sinceDate:lastCheck];
		
		if (updateTimer) {
			[updateTimer invalidate];
			[updateTimer release];
		}
		updateTimer = [[NSTimer scheduledTimerWithTimeInterval:checkInterval  target:self selector:@selector(threadedCheckForUpdate:) userInfo:nil repeats:shouldRepeat] retain];
		
		[updateTimer setFireDate:doStartupCheck?[NSDate dateWithTimeIntervalSinceNow:33.333f] :nextCheck];
		
		if (VERBOSE) QSLog(@"Next Version Check at : %@", [[updateTimer fireDate] description]);
		
	}
}

- (void)handleURL:(NSURL *)url
{
	QSLog(@"url %@", url);
	[self threadedRequestedCheckForUpdate:nil];
}

- (IBAction)threadedCheckForUpdate:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(checkForUpdate:)
                             toTarget:self
                           withObject:nil];
}

- (IBAction)threadedRequestedCheckForUpdate:(id)sender {
	[NSThread detachNewThreadSelector:@selector(checkForUpdate:)
                             toTarget:self
                           withObject:(mOptionKeyIsDown ? @"Force" : @"Requested")];
}

- (BOOL)networkIsReachable
{
	SCNetworkConnectionFlags reachabilityStatus;
    SCNetworkReachabilityRef target;
    Boolean success;
    target = SCNetworkReachabilityCreateWithName(NULL, [kDownloadUpdateURL cStringUsingEncoding:NSASCIIStringEncoding]);
    success = SCNetworkReachabilityGetFlags(target, &reachabilityStatus);
    CFRelease(target);
	return success && (reachabilityStatus & kSCNetworkFlagsReachable);
}

- (IBAction)checkForUpdate:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[QSTaskController sharedInstance] updateTask:@"Check for Update" status:@"Check for Update" progress:-1];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults]; 	
	
	BOOL quiet = !sender || sender == self || [sender isKindOfClass:[NSTimer class]];
	BOOL success = [self networkIsReachable];
	if ( !success ) {
		if ( VERBOSE ) QSLog(@"Blacktree unreacheable");
		
		[[QSTaskController sharedInstance] removeTask:@"Check for Update"];
		if (quiet) {
			return;
		} else {
			int result = NSRunInformationalAlertPanel(@"Connection Error", @"Your internet connection does not appear to be active.", @"Cancel", @"Check Anyway", nil);
			if (result == NSAlertDefaultReturn) return;
		} 	
	}	
    if ( VERBOSE ) QSLog(@"Blacktree reacheable");
	NSString *thisVersionString = (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
	BOOL forceUpdate = [sender isEqual:@"Force"];
	if (forceUpdate) QSLog(@"Forcing Update");
	int versionType = [defaults integerForKey:@"QSNewUpdateReleaseLevel"];
	
	NSString *versionURL = nil;
	if (versionType == 2)
		versionURL = kCurrentDevVersionURL;
	else if (versionType == 1 || PRERELEASEVERSION)
		versionURL = kCurrentPreVersionURL;
	else if (versionType == 0)
		versionURL = kCurrentVersionURL;
	
	
	if (VERBOSE) QSLog(@"Version URL, %@", versionURL);
	BOOL newVersionAvailable = NO;
	//int newPlugInsAvailable = 0;
	

	
	versionURL = [NSString stringWithFormat:@"%@&current = %@", versionURL, thisVersionString];
  	
  //	QSLog(@"%@ %qu", uniqueID, QSGetPrimaryMACAddressInt() );
	
	NSString *testVersionString = nil;
	if (success) {
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:versionURL]
																cachePolicy:NSURLRequestUseProtocolCachePolicy
															timeoutInterval:20.0];
		
		NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
		testVersionString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	}
	
	[defaults setObject:[NSDate date] forKey:kLastUpdateCheck];  
	if ([testVersionString length] && [testVersionString length] <10) {
		if (VERBOSE) QSLog(@"Current Version:%d Installed Version:%d", [testVersionString hexIntValue] , [thisVersionString hexIntValue]);
		newVersionAvailable = [testVersionString hexIntValue] >[thisVersionString hexIntValue]; 	
		if (newVersionAvailable)
			newVersion = [testVersionString retain];
	} else {
		QSLog(@"Unable to check for new version.");
		if (!quiet)
			NSRunInformationalAlertPanel(@"Connection Error", @"Unable to check for updates.", @"OK", nil, nil);
		return;
	}
	
	
	NSString *altURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSUpdateSource"];
	if (altURL || forceUpdate)
		newVersionAvailable = YES;
	
	if (newVersionAvailable) {
		//[NSApp activateIgnoringOtherApps:YES];
		if (defaultBool(@"QSDownloadUpdatesInBackground") ) {
			[self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
		} else {
			int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"New Version", nil] ,
													   @"A new version of Quicksilver is available; would you like to download it now? (%@) ", @"Get New Version", @"Cancel", nil, newVersion); //, @"More Info");
			if (selection == 1) {
				[self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
			} else if (selection == -1) {   //Go to web site
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDownloadUpdateURL]];
			}
		}
		
	} else {
		BOOL updated = [[QSPlugInManager sharedInstance] checkForPlugInUpdates];
		if (!updated) {				
			QSLog(@"Quicksilver is up to date.");
			//  QSLog(@"sender: %@", sender);
			if (!quiet) NSRunInformationalAlertPanel(@"No Updates Available", [NSString stringWithFormat:@"You already have the latest version of Quicksilver (v%@) and all installed plug-ins", thisVersionString] , @"OK", nil, nil);
		}
	}
	
	[[QSTaskController sharedInstance] removeTask:@"Check for Update"];
	//   [self setUpdateTimer];
	[pool release];
}

- (void)installAppUpdate {
	if (updateTask) return;
	
	NSString *fileURL = @"http://download.blacktree.com/download.php?id = com.blacktree.Quicksilver&type = dmg&new = yes";
							 //header("Location: http://download.blacktree.com/download.php?versionlevel = dev&new = yes&id = com.blacktree.Quicksilver&type = dmg");
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults]; 	
	
	
	//	BOOL devUpdate = PRERELEASEVERSION || [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateFindDevVersions"];
	
	
	int versionType = [defaults integerForKey:@"QSUpdateReleaseLevel"];
	
	//NSString *versionURL = nil;
	if (versionType == 2)
		fileURL = [fileURL stringByAppendingString:@"&dev = 1"];
	else if (versionType == 1 || PRERELEASEVERSION)
		fileURL = [fileURL stringByAppendingString:@"&pre = 1"];
	
	//	if (fDEV)
	//		fileURL = @"http://localhost/QS.2FEE.dmg";
	NSString *altURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSUpdateSource"];
	if (altURL)
		fileURL = altURL;
	if (VERBOSE) QSLog(@"Downloading update from  %@", fileURL);
	if (1) {
		NSURL *url = [NSURL URLWithString:fileURL];
		NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
												  cachePolicy:NSURLRequestUseProtocolCachePolicy
											  timeoutInterval:20.0];
		
		// QSLog(@"app %@", theRequest);
		// create the connection with the request
		// and start loading the data
		NSURLDownload *theDownload = [[QSURLDownload alloc] initWithRequest:theRequest
																 delegate:self];
		if (theDownload) {
			updateTask = [[QSTask taskWithIdentifier:@"QSAppUpdateInstalling"] retain];
			[updateTask setName:@"Downloading Update"];
			[updateTask setProgress:-1];

		[updateTask setCancelAction:@selector(cancelUpdate:)];
			[updateTask setCancelTarget:self];
			
			//			[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Downloading Update" progress:-1];
			[QSTaskController showViewer];
			[updateTask startTask:nil];
			// set the destination file now
			NSString *destination = NSTemporaryDirectory();
			destination = [destination stringByAppendingPathComponent:[NSString uniqueString]];
			destination = [destination stringByAppendingPathExtension:@"qspkg"];
			[theDownload setDestination:destination allowOverwrite:YES];
			[self setAppDownload:theDownload];
		} 
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:fileURL]];
	}
	
}
- (NSURLDownload *)appDownload { return [[appDownload retain] autorelease];  }

- (void)setAppDownload:(NSURLDownload *)anAppDownload {
    [appDownload autorelease];
    appDownload = [anAppDownload retain];
}




//- (NSDictionary *)downloadInfoForDownload:(NSURLDownload *)download {
//	//QSLog(@"url %@ %@", [appDownload objectForKey:@"download"] , download);
//	if ([appDownload isEqual:download]) return appDownload;
//	
//	NSEnumerator *e = [[self downloadsQueue] objectEnumerator];
//	
//	NSMutableDictionary *info; 	
//	while((info = [e nextObject])) {
//		if ([[info objectForKey:@"download"] isEqual:download]) break;
//	}
//	return info;
//}
- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	QSLog(@"Download Failed");
	//	[[QSTaskController sharedInstance] removeTask:@"QSAppUpdateInstalling"]; 	
				[updateTask stopTask:nil];
				[updateTask release];
				updateTask = nil;
				NSRunInformationalAlertPanel(@"Download Failed", @"An error occured while updating: %@", @"OK", nil, nil, [error localizedDescription] );
				[self setAppDownload:nil];
				[download release];
}

- (void)downloadDidFinish:(QSURLDownload *)download {
	[download release];
	
	
	
	BOOL plugInUpdates = [[QSPlugInManager sharedInstance] updatePlugInsForNewVersion:newVersion];
	
	if (plugInUpdates) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(finishAppInstall)
													name:QSPlugInUpdatesFinishedNotification
												  object:nil]; 	
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(finishAppInstall)
													name:QSPlugInUpdatesFailedNotification
												  object:nil]; 	
	} else {
		QSLog(@"Plug-ins don't need update");
		[self finishAppInstall];
	}
}

- (void)download:(QSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	//[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status: progress:-1];
				[updateTask setStatus:
					[NSString stringWithFormat:@"%.0fk of %.0fk", (double) [download currentContentLength] /1024, (double)[download expectedContentLength] /1024]];
	QSLog([NSString stringWithFormat:@" %f  - %f of %f", [(QSURLDownload *)download progress] , [download currentContentLength] /1024, [download expectedContentLength] /1024]);
	[updateTask setProgress:[(QSURLDownload *)download progress]];

}

- (void)cancelUpdate:(QSTask *)task {
	shouldCancel = YES;
	[[self appDownload] cancel];
	[self setAppDownload:nil];
	[updateTask stopTask:nil];
	[updateTask release];
	updateTask = nil;
}

- (void)finishAppInstall {
	NSString *path = [(QSURLDownload *)[self appDownload] destination];
	
	//[self installAppFromCompressedFile:path];
	[updateTask setStatus:@"Download Complete"];
	[updateTask setProgress:1.0];
	//	[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Download Complete" progress:-1];
	[self installAppFromDiskImage:path];
	[updateTask stopTask:nil];
	[updateTask release];
				updateTask = nil;
				
}
- (NSArray *)installAppFromCompressedFile:(NSString *)path {
	int selection = defaultBool(@"QSUpdateWithoutAsking"); 	
	if (!selection)
		selection = NSRunInformationalAlertPanel(@"Download Successful", @"A new version of Quicksilver has been downloaded. This version must be relaunched after it is installed.", @"Install and Relaunch", @"Cancel Update", nil);
	if (selection == 1) {
		NSFileManager *manager = [NSFileManager defaultManager];
		//	NSString *destination = psMainPlugInsLocation;
		NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
		[manager createDirectoryAtPath:tempDirectory
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:NULL];
		
		NSArray *extracted = [self extractFilesFromQSPkg:path toPath:tempDirectory];
		if ([extracted count] != 1) {
			QSLog(@"App Update Error");
			return nil;
		}
		
		NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
		if (newAppVersionPath)
			[NSApp relaunchAfterMovingFromPath:newAppVersionPath];
	} else {
		[updateTask stopTask:nil];
		[updateTask release];
		updateTask = nil;
	}
	return nil;
}

- (NSArray *)installAppFromDiskImage:(NSString *)path
{
	int selection = defaultBool(@"QSUpdateWithoutAsking"); 	
	if (!selection)
		selection = NSRunInformationalAlertPanel(@"Download Successful", @"A new version of Quicksilver has been downloaded. This version must be relaunched after it is installed.", @"Install and Relaunch", @"Cancel Update", nil);
	if (selection == 1) {
		NSFileManager *manager = [NSFileManager defaultManager];
		
		NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
		[manager createDirectoryAtPath:tempDirectory
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:NULL];
		
		[updateTask setProgress:-1.0];
		[updateTask setName:@"Installing Update"];
		[updateTask setStatus:@"Verifying Data"];
		NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
											  arguments:[NSArray arrayWithObjects:@"attach", path, @"-nobrowse", @"-mountpoint", tempDirectory, nil]];
		
		[task waitUntilExit]; 	
		
		NSArray *extracted = [[manager contentsOfDirectoryAtPath:tempDirectory
                                                           error:NULL]
                                 pathsMatchingExtensions:[NSArray arrayWithObject:@"app"]];
		if ([extracted count] != 1) {
			QSLog(@"App Update Error");
			return nil;
		}		
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWasMoved:)
                                                     name:QSApplicationWillRelaunchNotification
                                                   object:self];
		NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
		if (newAppVersionPath) {
			[updateTask setStatus:@"Copying Application"];
			[NSApp replaceWithUpdateFromPath:newAppVersionPath];
			[updateTask setStatus:@"Cleaning Up"];
			task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
										  arguments:[NSArray arrayWithObjects:@"detach", tempDirectory, nil]];
			
			[task waitUntilExit]; 	
			[[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:NULL]; 	
			
			[tempPath release];
			tempPath = nil;
			
			
			[updateTask stopTask:nil];
			[updateTask release];
			updateTask = nil;
			
			//	[[QSTaskController sharedInstance] removeTask:@"QSAppUpdateInstalling"]; 	
			[QSTaskController hideViewer];
			if (defaultBool(@"QSQuitAfterUpdate")) {
				[NSApp terminate:nil];
			} else {
				[NSApp relaunch:self];
            }
		} else {
			[updateTask stopTask:nil];
			[updateTask release];
			updateTask = nil;
			
		}
	} 	
	return nil;
}

- (void)applicationWasMoved:(NSNotification *)notif {
	QSLog(@"notif %@ %@", notif, tempPath);
}

- (void)finishInstallAndRelaunch { }

- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory
{
	if (!path) return nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ditto"];
	
	[task setArguments:[NSArray arrayWithObjects:@"-x", @"-rsrc", path, tempDirectory, nil]];
	[task launch];
	[task waitUntilExit];
	int status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:NULL];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:NULL];
	} else {
		return nil;
	}	
}



@end



