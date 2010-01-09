//
//  QSTask.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/29/05.

//  2010-01-09 Makoto Yamashita

#import <Cocoa/Cocoa.h>
#import "QSObject.h"

@class QSTask;

@interface NSObject (QSTaskDelegate)
- (NSImage *)iconForTask:(QSTask *)task;
@end

@interface QSTask : NSObject {
	NSString *identifier;
	NSString *name;
	NSString *status;
	float progress; //0 to 1, -1 is indeterminate
	QSObject *result;
	NSImage *icon;
	id delegate;
	
	SEL cancelAction;
	id cancelTarget;
	BOOL running;
	BOOL showProgress;
	NSArray *subtasks;
	QSTask *parentTask;
}
+ (QSTask *)taskWithIdentifier:(NSString *)identifier;
+ (QSTask *)findTaskWithIdentifier:(NSString *)identifier;
- (void)startTask:(id)sender;
- (void)stopTask:(id)sender;

- (IBAction)cancel:(id)sender;

@property (retain) NSString* identifier;
@property (copy) NSString* name;
@property (copy) NSString* status;
@property (assign) float progress;
@property (assign) BOOL showProgress;
@property (copy) QSObject* result;
@property (assign) SEL cancelAction;
@property (retain) id cancelTarget;
@property (retain) NSArray* subtasks;
@property (retain) NSImage* icon;
@property (retain) id delegate;

@end
