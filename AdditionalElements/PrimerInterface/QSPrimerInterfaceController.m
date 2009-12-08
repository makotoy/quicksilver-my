/*
 * Derived from Blacktree codebase.
 * 2009-12-08 Makoto Yamashita.
 */

#import "QSPrimerInterfaceController.h"

#define DIFF 84

NSRect alignRectInRect(NSRect innerRect,NSRect outerRect,int quadrant);

@implementation QSPrimerInterfaceController


- (id)init
{
    self = [super initWithWindowNibName:@"Primer"];
    return self;
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	// logRect([[self window]frame]);
	[[self window] addInternalWidgetsForStyleMask:NSUtilityWindowMask closeOnly:YES];
    [[self window] setLevel:NSModalPanelWindowLevel];
    [[self window] setFrameAutosaveName:@"PrimerInterfaceWindow"];
    
	//  [[self window]setFrame:constrainRectToRect([[self window]frame],[[[self window]screen]visibleFrame]) display:NO];
	//    [(QSWindow *)[self window]setHideOffset:NSMakePoint(0,-99)];
	//   [(QSWindow *)[self window]setShowOffset:NSMakePoint(0,99)];
    [[self window]setHasShadow:YES];
	
	QSWindow *window = (QSWindow*)[self window];
    [window setHideOffset:NSMakePoint(0,0)];
    [window setShowOffset:NSMakePoint(0,0)];
    
	[dSelector setResultsPadding:2];
	[aSelector setResultsPadding:2];
	[iSelector setResultsPadding:2];
	//	[window setFastShow:YES];
	[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect",@"transformFn",@"show",@"type",[NSNumber numberWithFloat:0.15],@"duration",nil]];
	//	[window setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:.25],@"duration",nil]];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExplodeEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:0.2],@"duration",nil]
					   forKey:kQSWindowExecEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"hide",@"type",[NSNumber numberWithFloat:0.15],@"duration",nil]
					   forKey:kQSWindowFadeEffect];
	
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:0.333],@"duration",nil,[NSNumber numberWithFloat:0.25],@"brightnessB",@"QSStandardBrightBlending",@"brightnessFn",nil]
					   forKey:kQSWindowCancelEffect];
	
	
	//  standardRect=[[self window]frame],[[NSScreen mainScreen]frame]);
	
	// [setHidden:![NSApp isUIElement]];
    
	
	// [[[self window] _borderView]_resetDragMargins];
	//  */
	//   [self contractWindow:self];
}

- (void)hideMainWindow:(id)sender
{
    [[self window] saveFrameUsingName:@"PrimerInterfaceWindow"];
    
    [super hideMainWindow:sender];
}

- (void)showMainWindow:(id)sender
{
	NSRect frame=[[self window]frame];
	frame=constrainRectToRect(frame,[[[self window] screen] frame]);
	[[self window] setFrame:frame display:YES];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSAlwaysCenterInterface"]) {
		NSRect frame=[[self window] frame];
		frame = centerRectInRect(frame,[[[self window] screen] frame]);
		[[self window]setFrame:frame display:YES];	
	}
	
	[super showMainWindow:sender];	
}

- (NSSize)maxIconSize
{
    return NSMakeSize(128,128);
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect
{
    return NSOffsetRect(NSInsetRect(rect,8,0),0,0);
}

- (void)hideIndirectSelector:(id)sender
{
	[indirectView setHidden:YES];	
    [self resetAdjustTimer];  
}

- (void)showIndirectSelector:(id)sender
{
	if ([indirectView isHidden]) {
		[(QSFadingView*)indirectView setOpacity:0.0];
		[indirectView setHidden:NO];
		[self resetAdjustTimer];
	}
}

- (void)expandWindow:(id)sender
{ 
    NSRect expandedRect=[[self window]frame];
	expandedRect.size.height+=DIFF;
    expandedRect.origin.y-=DIFF;
	constrainRectToRect(expandedRect,[[[self window]screen]frame]);
	if (!expanded) {
		[[self window]setFrame:expandedRect display:YES animate:YES];
	}
    [super expandWindow:sender];
	[(QSFadingView*)indirectView setOpacity:1.0];
}

- (void)contractWindow:(id)sender{
    NSRect contractedRect=[[self window] frame];
    contractedRect.size.height-=DIFF;
    contractedRect.origin.y+=DIFF;

    if (expanded) {
        [[self window]setFrame:contractedRect display:YES animate:YES];
    }
    [super contractWindow:sender];
}


- (void)searchObjectChanged:(NSNotification*)notif
{
	[super searchObjectChanged:notif];
	
	NSString *command = [[self currentCommand] description];
	if (!command) {
		command = @"Begin typing in the Subject field to search";
	}
	[commandView setStringValue:command];
	
	return;
}

-(void)updateDetailsString
{
	NSString *command=[[self currentCommand] description];
	[commandView setStringValue:(command ? command : @"")];
	QSSearchObjectView *firstResponder = (QSSearchObjectView*)[[self window] firstResponder];
	if ([firstResponder respondsToSelector:@selector(objectValue)]) {
		id object = [firstResponder objectValue];
		if ([object respondsToSelector:@selector(details)]) {
			NSString *string=[object details];
			if (string) {
				[commandView setStringValue:string];
				return;
			}
		}
	}
	[commandView setStringValue:[[self currentCommand]description]];
}

-(void)searchView:(QSSearchObjectView *)view changedString:(NSString *)string
{
	if (string) {
		if (view == dSelector) [dSearchText setStringValue:string];
		if (view == aSelector) [aSearchText setStringValue:string];
		if (view == iSelector) [iSearchText setStringValue:string];
	}
}

-(void)searchView:(QSSearchObjectView *)view changedResults:(NSArray *)array
{
	int count = [array count];
	NSString *string = ESS_phrase(count, (view == aSelector) ?  @"action" : @"item");
	if (string) {
		if (view == dSelector) [dSearchCount setStringValue:string];
		if (view == aSelector) [aSearchCount setStringValue:string];
		if (view == iSelector) [iSearchCount setStringValue:string];
	}
}

-(void)searchView:(QSSearchObjectView *)view resultsVisible:(BOOL)resultsVisible
{
	if (view == dSelector) [dSearchResultDisclosure setState:resultsVisible];
	if (view == aSelector) [aSearchResultDisclosure setState:resultsVisible];
	if (view == iSelector) [iSearchResultDisclosure setState:resultsVisible];
}

@end
















