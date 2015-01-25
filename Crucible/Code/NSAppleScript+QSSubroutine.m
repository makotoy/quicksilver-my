//
//  NSAppleScript+QSSubroutine.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.
//
//  Quicksilver Gamma project. Derived from Blacktree codebase
//  Makoto Yamashita 2015

#import "NSAppleScript+QSSubroutine.h"
#import "NSAppleEventDescriptor+QSTranslation.h"
#import <Carbon/Carbon.h>

@implementation NSAppleScript (QSSubroutine)

- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo
{
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* subroutineDescriptor;
    int pid = [[NSProcessInfo processInfo] processIdentifier];
  
    if (arguments && ![arguments isKindOfClass:[NSAppleEventDescriptor class]]) {
        arguments=[NSAppleEventDescriptor descriptorWithObjectAPPLE:arguments];
    }
    if (arguments && [arguments descriptorType]!=cAEList) {
        NSAppleEventDescriptor *argumentList=[NSAppleEventDescriptor listDescriptor];
        [argumentList insertDescriptor:arguments atIndex:[arguments numberOfItems]+1];
        arguments=argumentList;
    }
    targetAddress = [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)]autorelease];
    event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
    subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:name];
    [event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
    if (arguments) [event setParamDescriptor:arguments forKeyword:keyDirectObject];
    return [self executeAppleEvent:event error:errorInfo];
}

@end

