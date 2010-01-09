//
//  QSPlugInManager.h
//  Quicksilver
//
//  Created by Alcor on 2/7/05.
//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import <Cocoa/Cocoa.h>
#define QSPlugInListingDownloadCompleteNotification @"QSPlugInListingDownloadComplete"
#define QSPlugInInfoLoadedNotification @"QSPlugInInfoLoaded"
#define QSPlugInInfoFailedNotification @"QSPlugInInfoFailed"

@class QSPlugIn;
@interface QSPlugInManager : NSObject {
	BOOL startupLoadComplete;
	
	NSMutableDictionary 			*localPlugIns;  	// Most recent version of every plugin on this machine. Includes restricted.
	NSMutableDictionary 			*knownPlugIns;  	// Local plugins + visible web plugins. Includes restricted.
	NSMutableDictionary				*loadedPlugIns; 	// All plugins that have been loaded
	
	NSMutableArray 					*oldPlugIns; 		// Plugins with newer versions overriding, these are not included in local plugins
	NSMutableDictionary 			*dependingPlugIns; 	// Dictionary of dependencies -> array of waiting identifiers
	
	NSMutableData *receivedData;
	NSMutableDictionary *plugInWebData;
	NSDate 				*plugInWebDownloadDate;
	
	BOOL showNotifications;
	BOOL updatingPlugIns;
	BOOL warnedOfRelaunch;
	
	NSMutableArray *updatedPlugIns;
	int downloadsCount;
	NSMutableArray *downloadsQueue;
	NSURLDownload *currentDownload;
	NSString *installStatus;
	float installProgress;
	BOOL isInstalling;
	BOOL supressRelaunchMessage;
}

+ (id)sharedInstance;

- (QSPlugIn *)plugInWithID:(NSString *)identifier;
- (BOOL)plugInIsMostRecent:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles;
- (BOOL)plugInMeetsRequirements:(QSPlugIn *)plugIn;
- (BOOL)plugInMeetsDependencies:(QSPlugIn *)plugIn;
- (void)downloadWebPlugInInfoFromDate:(NSDate *)date forUpdateVersion:(NSString *)version synchronously:(BOOL)synchro;
- (NSDictionary *)loadedPlugIns;
- (NSDictionary *)oldPlugIns;

- (BOOL)startupLoadComplete;

- (void)suggestOldPlugInRemoval;
- (BOOL)liveLoadPlugIn:(QSPlugIn *)plugin;
- (NSArray *)knownPlugInsWithWebInfo ;

- (QSPlugIn *)plugInBundleWasInstalled:(NSBundle *)bundle;
- (void)deletePlugIns:(NSArray *)deletePlugIns fromWindow:(NSWindow *)window;
- (void)checkForUnmetDependencies;

- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs;
- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs version:(NSString *)version;
- (void)loadNewWebData:(NSData *)data;
- (BOOL)checkForPlugInUpdates;
- (BOOL)checkForPlugInUpdatesForVersion:(NSString *)version;

@property (retain) NSMutableDictionary *localPlugIns;
@property (retain) NSMutableDictionary *knownPlugIns;
@property (retain) NSMutableDictionary *loadedPlugIns;
@property (copy) NSString *installStatus;
@property (assign) float installProgress;
@property (assign) BOOL isInstalling;
@property (retain) NSURLDownload* currentDownload;
@property (assign) BOOL showNotifications;

- (void)updateDownloadProgressInfo;
- (NSString *)urlStringForPlugIn:(NSString *)ident version:(NSString *)version;
- (BOOL)supressRelaunchMessage;
- (void)setSupressRelaunchMessage:(BOOL)flag;
- (NSArray *)downloadsQueue;
- (NSString *)installPlugInFromFile:(NSString *)path;
- (void)downloadWebPlugInInfo;
- (void)downloadWebPlugInInfoIgnoringDate;
- (BOOL)updatePlugInsForNewVersion:(NSString *)version;
- (float)downloadProgress;
- (NSArray *)updatedPlugIns;
- (BOOL)handleInstallURL:(NSURL *)url;
- (BOOL)installPlugInsFromFiles:(NSArray *)fileList;

- (NSURLDownload *)currentDownload;
- (void)setCurrentDownload:(NSURLDownload *)newCurrentDownload;
- (void)cancelPlugInInstall;

- (BOOL)deletePlugin:(QSPlugIn*)bundle;
@end