/*
 *  Derived from Blacktree, Inc. codebase
 *  2010-01-10 Makoto Yamashita
 */

#import <CoreFoundation/CoreFoundation.h>

#import "QSWebSearchController.h"

@implementation QSWebSearchController
+ (id)sharedInstance
{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;  
}

- (id)init
{
    self = [super init];
    if (self) {
		[[self window] setLevel:NSFloatingWindowLevel];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window]setHidesOnDeactivate:NO];
}

- (void)searchURL:(NSURL *)searchURL
{
    [self setWebSearch:searchURL];
    [self showSearchView:self];
	[[self window] makeKeyAndOrderFront:self];
}

- (NSString *)resolvedURL:(NSURL *)searchURL forString:(NSString *)string encoding:(CFStringEncoding)encoding
{
    NSString *query =[searchURL absoluteString];
    NSString *searchTerm =[string URLDecoding];
	
    searchTerm = [searchTerm stringByReplacing:@"+" with:@"/+/"];        
    searchTerm = [searchTerm stringByReplacing:@" " with:@"+"];
	if (encoding) {
    	searchTerm = [searchTerm URLEncodingWithEncoding:encoding];
	} else {
		searchTerm = [searchTerm URLEncoding];
	}
	searchTerm= [searchTerm stringByReplacing:@"/+/" with:@"%2B"];  
    
    query=[query stringByReplacing:QUERY_KEY with:searchTerm];
	return query;
}

- (void)searchURL:(NSURL *)searchURL forString:(NSString *)string encoding:(CFStringEncoding)encoding
{   
    NSPasteboard *findPboard=[NSPasteboard pasteboardWithName:NSFindPboard];
    [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [findPboard setString:string forType:NSStringPboardType];
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
	
	NSString *query=[self resolvedURL:searchURL forString:string encoding:encoding];
	
	   if ([[searchURL scheme]isEqualToString:@"qssp-http"]){
		   //  query=[query stringByReplacing:OLD_QUERY_KEY with:searchTerm]; // allow old query for now
		   [self openPOSTURL:[NSURL URLWithString:[query stringByReplacing:@"qssp-http" with:@"http"]]];  
		   return;
	   } else if ([[searchURL scheme]isEqualToString:@"http-post"]){
		   [self openPOSTURL:[NSURL URLWithString:[query stringByReplacing:@"http-post" with:@"http"]]];  
		   return;
	   } else if ([[searchURL scheme]isEqualToString:@"qss-http"]){
		   query=[query stringByReplacing:@"qss-http" with:@"http"];  
		   NSURL *queryURL=[NSURL URLWithString:query];
		   [workspace openURL:queryURL];
	   }else{
		   NSURL *queryURL=[NSURL URLWithString:query];
		   [workspace openURL:queryURL];
	   }
}

- (void)searchURL:(NSURL *)searchURL forString:(NSString *)string
{
	[self searchURL:(NSURL *)searchURL
          forString:(NSString *)string
           encoding:kCFStringEncodingASCII];   
}

- (void)openPOSTURL:(NSURL *)searchURL
{
    NSMutableString *form=[NSMutableString stringWithCapacity:100];
    
    [form appendString:@"<html><head><title>Quicksilver Search Submitter</title></head><body onLoad=\"document.qsform.submit()\">"];
    [form appendFormat:@"<form name=\"qsform\" action=\"%@\" method=\"POST\">",
     [[[searchURL absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0]];

    for (NSString* component in [[searchURL query]componentsSeparatedByString:@"&"]) {
        NSArray *nameAndValue=[component componentsSeparatedByString:@"="];
        [form appendFormat:@"<input type=hidden name=\"%@\" value=\"%@\">",
            [[[nameAndValue objectAtIndex:0]URLDecoding]stringByReplacing:@"+" with:@" "],
            [[[nameAndValue objectAtIndex:1]URLDecoding]stringByReplacing:@"+" with:@" "]];
    }
    [form appendString:@"</body></html>"];
    NSString *postFile=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"QSPOST-%@.html",[NSString uniqueString]]]; 
	// ***warning   * delete these files
    [form writeToFile:postFile atomically:NO encoding:NSASCIIStringEncoding error:NULL];
    [[NSWorkspace sharedWorkspace]openFile:postFile];
}

- (IBAction)submitWebSearch:(id)sender
{
    if ([[webSearchField stringValue]length]){
		[self searchURL:webSearch forString:[webSearchField stringValue]];
		[self setWebSearch:nil];
		[[self window] orderOut:self];
    }
}

- (IBAction) showSearchView:sender
{
    NSPasteboard *findPboard=[NSPasteboard pasteboardWithName:NSFindPboard];
    NSString *webSearchString=[findPboard stringForType:NSStringPboardType];
    if (webSearchString) [webSearchField setStringValue:webSearchString];
    [[self window] orderFront:self];
    
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[self window] orderOut:self];
}

@synthesize webSearch;

@end
