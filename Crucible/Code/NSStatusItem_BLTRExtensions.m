//
//  NSStatusItem_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 12/11/04.
//  2010-01-02 Makoto Yamashita

#import <objc/objc-runtime.h>

@implementation NSStatusItem (Priority)
- (int)priority
{
	int fPriority;
	object_getInstanceVariable(self, "_pPriority", (void*)&fPriority);
 	return fPriority;
}
@end
