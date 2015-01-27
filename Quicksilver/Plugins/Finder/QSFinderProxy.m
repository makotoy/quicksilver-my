/* QSFinderProxy.m
 * QuickSilver Gamma project
 * Derived from Blacktree codebase
 * Makoto Yamashita 2015
 */

#import "QSFinderProxy.h"


@implementation QSFinderProxy
+ (id)sharedInstance
{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (id) init
{
    if ((self = [super init])) {
        NSDictionary *errorDict;
        NSString *path=[[NSBundle bundleForClass:[self class]]pathForResource:@"Finder" ofType:@"scpt"];
        [self setFinderScript:[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                                     error:&errorDict]];
    }
    return self;
}

- (NSImage *)icon
{
    return [[NSWorkspace sharedWorkspace]iconForFile:@"/System/Library/CoreServices/Finder.app"];   
}

- (BOOL)revealFile:(NSString *)file
{
	//  NSDictionary *errorDict=nil;
	//  NSArray *arguments=[NSArray arrayWithObject:[NSArray arrayWithObject:file]];
	//  NSAppleEventDescriptor *desc=[[self finderScript] executeSubroutine:@"reveal" arguments:[NSAppleEventDescriptor descriptorWithObject:arguments] error:&errorDict];
	//  if (errorDict){
	//      NSLog(@"Execute Error: %@",errorDict);
	[[NSWorkspace sharedWorkspace] selectFile:file inFileViewerRootedAtPath:@""];
	//  }
    return YES;
}

- (NSArray *)selection
{
    NSDictionary *errorDict = nil;
    NSAppleEventDescriptor *desc = [[self finderScript] executeSubroutine:@"get_selection" arguments:nil error:&errorDict];
    if (errorDict) {
        NSLog(@"Finder module get_selection script execution Error: %@",errorDict);
        return [NSArray array];
    }
    NSMutableArray *files=[NSMutableArray arrayWithCapacity:[desc numberOfItems]];
    int i;
    for (i = 0; i < [desc numberOfItems]; i++) {
        [files addObject:[[desc descriptorAtIndex:i+1] stringValue]];
    }
    return files;
}

- (NSArray *)copyFiles:(NSArray *)files toFolder:(NSString *)destination
{
    return [self moveFiles:files toFolder:destination shouldCopy:YES];
}

- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination
{
    return [self moveFiles:files toFolder:destination shouldCopy:NO];
}

- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination shouldCopy:(BOOL)copy
{
    NSDictionary *errorDict=nil;
    NSAppleEventDescriptor *filePathsDesc = [NSAppleEventDescriptor listDescriptor];
    int i = 0;
    for (NSString *thePath in files) {
        [filePathsDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:thePath] atIndex:++i];
    }
    NSAppleEventDescriptor *argsDesc = [NSAppleEventDescriptor listDescriptor];
    [argsDesc insertDescriptor:filePathsDesc atIndex:1];
    [argsDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:destination] atIndex:2];
    NSAppleEventDescriptor *desc = [[self finderScript] executeSubroutine:(copy?@"copy_items":@"move_items")
                                                                arguments:argsDesc error:&errorDict];
    if (!errorDict) {
        int j = 0;
        NSAppleEventDescriptor *theDesc;
        NSMutableArray *resArray = [NSMutableArray arrayWithCapacity:0];
        while ((theDesc = [desc descriptorAtIndex:++j])) {
            [resArray addObject:[theDesc stringValue]];
        }
        return resArray;
    } else {
        NSLog(@"Finder module move file script execution error: %@", errorDict);
        return nil;
    }
}

- (NSArray *)getInfoForFiles:(NSArray *)files
{
    NSDictionary *errorDict=nil;

    [[self finderScript] executeSubroutine:@"get_info" arguments:[NSArray arrayWithObject:files] error:&errorDict];
    if (errorDict) {
		NSLog(@"Execute Error: %@",errorDict);
    }
	return nil;
}

- (BOOL)openFile:(NSString *)file
{
    return [[NSWorkspace sharedWorkspace] openFile:file];    
}

- (NSArray *)deleteFiles:(NSArray *)files
{
    // unimplemented
    return nil;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
	NSArray *newChildren = [QSObject fileObjectsWithPathArray:[self selection]];
	[object setChildren:newChildren];
	return YES;   	
}

@synthesize finderScript;

-(id)resolveProxyObject:(id)proxy
{
	return [QSObject fileObjectWithArray:[self selection]];
}

-(NSArray *)typesForProxyObject:(id)proxy
{
	return [NSArray arrayWithObject:QSFilePathType];
}


- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
	// Trash Object
	NSMutableArray *array=[NSMutableArray array];
	[array addObject:[QSAction actionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     self,          kActionProvider,
                                                     @"openTrash:", kActionSelector,
                                                     nil]
										 identifier:@"FinderOpenTrashAction"
                                             bundle:[NSBundle bundleForClass:[self class]]]];
	[array addObject:[QSAction actionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     self,          kActionProvider,
                                                     @"emptyTrash:",kActionSelector,
                                                     nil]
										 identifier:@"FinderEmptyTrashAction"
                                             bundle:[NSBundle bundleForClass:[self class]]]];

    return array;
}

@end
