
#import "QSPreferenceKeys.h"
#import "QSTaskController.h"
#import "QSTask.h"


QSTaskController *QSTasks;

@implementation QSTaskController 
+ (QSTaskController * )sharedInstance
{
    if (!QSTasks) QSTasks = [[[self class] allocWithZone:[self zone]] init];
    return QSTasks;
}

+ (void)showViewer
{
    [[NSClassFromString(@"QSTaskViewer") sharedInstance]
     performSelector:@selector(showWindow:)
     withObject:self];
}

+ (void)hideViewer
{
    [[NSClassFromString(@"QSTaskViewer") sharedInstance]
     performSelector:@selector(hideWindow:)
     withObject:self];
}

- (id)init {
	if ((self = [super init])) {
        tasks=[[NSMutableArray alloc]initWithCapacity:1];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]){
			[NSClassFromString(@"QSTaskViewer")  sharedInstance];
		}
    }
    return self;
}

- (void)taskStarted:(QSTask *)task{
	[self performSelectorOnMainThread:@selector(mainThreadTaskStarted:) withObject:[task retain] waitUntilDone:YES];
}

- (void)mainThreadTaskStarted:(QSTask *)task{
	[task autorelease];
	BOOL firstItem=![tasks count];
	if (![tasks containsObject:task]) [tasks addObject:task];
	
	if (firstItem) {
		[[NSNotificationCenter defaultCenter] postNotificationName:QSTasksStartedNotification object:nil];
	}
//FIXME: the task should be added to this notification!
	[[NSNotificationCenter defaultCenter] postNotificationName:QSTaskAddedNotification object:nil];
}

- (void)taskStopped:(QSTask *)task
{
	[self performSelectorOnMainThread:@selector(mainThreadTaskStopped:) withObject:[task retain] waitUntilDone:YES];
}

- (void)mainThreadTaskStopped:(QSTask *)task
{
	[task autorelease];
	if (task) [tasks removeObject:task];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTaskRemovedNotification object:nil];
	
	if (![tasks count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:QSTasksEndedNotification object:nil];	
	}
}

- (NSMutableArray *)tasks { return tasks; }

// old support methods
-(id)taskWithIdentifier:(NSString *)taskKey
{
	QSTask *task = [QSTask taskWithIdentifier:taskKey];
	[task startTask:nil];
	return task;
}
-(void) updateTask:(NSString *)taskKey status:(NSString *)status progress:(float)progress
{
	QSTask *task = [self taskWithIdentifier:taskKey];
	[task setStatus:status];
	[task setProgress:progress];	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSTaskChangedNotification object:task];
}

-(void) removeTask:(NSString *)string
{
	[[QSTask findTaskWithIdentifier:string] stopTask:nil];
}

@end
