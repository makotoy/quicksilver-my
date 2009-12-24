/*
 * Derived from Blacktree, Inc. codebase
 * Makoto Yamashita 2009-12-24
 */

#import <Foundation/Foundation.h>
#import "QSObject.h"

@class QSBasicObject;

@protocol QSObjectHandler_Dragging
- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>)drag ontoObject:(QSBasicObject *)destObject withObject:(QSBasicObject *)srcObject;
- (NSString *)actionForDragMask:(NSDragOperation)mask ontoObject:(QSBasicObject *)destObject withObject:(QSBasicObject *)srcObject;
@end

@interface QSObject (Dragging)
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
- (NSString *)actionForDragOperation:(NSDragOperation)operation withObject:(QSBasicObject *)object;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender withObject:(QSBasicObject *)object;
@end
