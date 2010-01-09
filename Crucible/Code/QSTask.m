//
//  QSTask.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/29/05.

//  2010-01-09 Makoto Yamashita

#import "QSTask.h"
#import "QSTaskController.h"

static NSMutableDictionary *tasksDictionary;
@implementation QSTask
+ (void)initialize
{
	tasksDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet* resPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"indeterminateProgress"]
          ||[key isEqualToString:@"animateProgress"]) {
        resPaths = [resPaths setByAddingObject:@"progress"];
    }
    return resPaths;
}

+ (QSTask *)taskWithIdentifier:(NSString *)identifier
{
	QSTask *task=[tasksDictionary objectForKey:identifier];
	if (!task)
		task=[[[QSTask alloc]initWithIdentifier:identifier]autorelease];
	return task;
}

+ (QSTask *)findTaskWithIdentifier:(NSString *)identifier
{
	QSTask *task=[tasksDictionary objectForKey:identifier];
	return task;
}

- (NSString *)nameAndStatus { return [self name]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"[%@:%@:%@]",identifier,name,status];
}

- (id)initWithIdentifier:(NSString *)newIdentifier 
{
	self = [super init];
	if (self) {
		[self setIdentifier:newIdentifier];
	}
	return self;
}

- (void)release
{
	if ([self retainCount]==2 && identifier){
		[self setIdentifier:nil];
	}
	[super release];
}

- (void)dealloc
{
	[self setIdentifier:nil];
	[self setName:nil];
	[self setStatus:nil];
	[self setResult:nil];
	[self setCancelTarget:nil];
	[self setSubtasks:nil];
	[super dealloc];
}

- (void)cancel:(id)sender{
	if (cancelTarget){
		QSLog(@"Cancel Task: %@",self);
		
		[cancelTarget performSelector:cancelAction withObject:sender];	
	}
}

- (BOOL)isRunning { return running; }

- (void)startTask:(id)sender
{
	if (!running){
		running=YES;
		
		[QSTasks taskStarted:[[self retain]autorelease]];
	}
}

- (void)stopTask:(id)sender
{
	if (running){
		running=NO;
		[QSTasks taskStopped:self];
	}
}

// Bindings

- (BOOL)animateProgress { return progress<0; }

- (BOOL)indeterminateProgress{ return progress<0; }

- (BOOL)canBeCancelled{	return cancelAction != NULL;}

// Accessors

@synthesize identifier;
- (void)setIdentifier:(NSString *)value
{
    if (identifier != value) {
		NSString *oldIdentifier=identifier;
		[identifier autorelease];
		identifier = [value copy];
		
		if (tasksDictionary){
			if (value) [tasksDictionary setObject:self forKey:value];
			if (oldIdentifier) [tasksDictionary removeObjectForKey:oldIdentifier];
		}
    }
}

@synthesize icon;
- (NSImage *)icon
{
	if (!icon && delegate && [delegate respondsToSelector:@selector(iconForTask:)]){
		[self setIcon:[delegate iconForTask:self]];
	}
	if (!icon)return [NSImage imageNamed:@"NSApplicationIcon"];
	return [[icon retain] autorelease];
}

@synthesize name;
@synthesize status;
@synthesize progress;
@synthesize result;
@synthesize cancelAction;
@synthesize cancelTarget;
@synthesize showProgress;
@synthesize subtasks;
@synthesize delegate;

@end
