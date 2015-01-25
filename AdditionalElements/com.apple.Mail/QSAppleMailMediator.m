// Derived from Blacktree codebase
// Makoto Yamashita 2009-11-30

#import "QSAppleMailMediator.h"
#import "QSMailMediator.h"

#import <AddressBook/AddressBook.h>
#import <QSCrucible/QSCrucible.h>

@class QSCountBadgeImage;

@implementation QSAppleMailMediator

- (id)init
{
    if (self = [super init]) {
        NSString *oldScriptPath = [[NSBundle bundleForClass:[QSAppleMailMediator class]] pathForResource:@"Mail" ofType:@"scpt"];
        if (oldScriptPath) {
            [self setMailScript:[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:oldScriptPath] error:nil]];
        }
    }
    return self;
}

- (void) sendEmailTo:(NSArray *)addresses from:(NSString *)sender
			 subject:(NSString *)subject body:(NSString *)body
		 attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow
{
/*	NSString *accountFormatted;
    if (sender) {
		accountFormatted = sender;
	} else {
        NSArray *accounts = [self accountList:addresses];
        NSArray *account;
        for (NSArray *accountCand in accounts) {
            if (emailsShareDomain([addresses lastObject],
								  [accountCand objectAtIndex:0])) {
                account = accountCand;  
                break;
            }
        }
		if ([(NSString *)[account lastObject] length] > 0) {
			accountFormatted = [NSString stringWithFormat:@"%@ <%@>",
								[account lastObject],
								[account objectAtIndex:0]];
		} else {
			accountFormatted = [account objectAtIndex:0];
		}
    }
	[[QSReg getClassInstance:@"QSMailMediator"]
	    sendEmailWithScript:[self mailScript]
	                     to:addresses
	                   from:accountFormatted
	                subject:subject
	                   body:body
				attachments:pathArray
					sendNow:sendNow];
 */
}

- (NSArray *)accountList:(NSArray *)addresses
{
    ABAddressBook *AB = [ABAddressBook sharedAddressBook];
    NSMutableArray *queryRes = [NSMutableArray arrayWithCapacity:0];
    for (NSString* theAddr in addresses) {
        ABSearchElement *searchQuery = [ABPerson searchElementForProperty:kABEmailProperty
                                                                    label:nil
                                                                      key:nil
                                                                    value:theAddr
                                                               comparison:kABPrefixMatchCaseInsensitive];
        [queryRes addObjectsFromArray:[AB recordsMatchingSearchElement:searchQuery]];
    }
    
    return [NSArray array];
}

- (NSString *)scriptPath{
    return [[NSBundle bundleForClass:[QSAppleMailMediator class]]pathForResource:@"Mail" ofType:@"scpt"];
}

//-------------------------

- (void) superSendEmailTo:(NSArray *)addresses from:(NSString *)sender subject:(NSString *)subject body:(NSString *)body attachments:(NSArray *)pathArray sendNow:(BOOL)sendNow{
    
    if (!sender)sender=@""; 
    if (!addresses){ 
        NSRunAlertPanel(@"Invalid address",@"Missing email address", nil,nil,nil);
        
        // [self sendDirectEmailTo:address subject:subject body:body attachments:pathArray];
        return;
    }
    
    if (VERBOSE)NSLog(@"Sending Email:\r     To: %@\rSubject: %@\r   Body: %@\rAttachments: %@\r",[addresses componentsJoinedByString:@", "],subject,body,[pathArray componentsJoinedByString:@"\r"]);
    
    NSDictionary *errorDict=nil;
    
    //id message=
	[[self mailScript] executeSubroutine:(sendNow?@"send_mail":@"compose_mail")
							   arguments:[NSArray arrayWithObjects:subject,body,sender,addresses,(pathArray?pathArray:[NSArray array]),nil]
								   error:&errorDict];
    //  NSLog(@"%@",message);
    if (errorDict) 
        NSRunAlertPanel(@"An error occured while sending mail", [errorDict objectForKey:@"NSAppleScriptErrorMessage"], nil,nil,nil);
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped
{
	if (![object objectForType:QSProcessType]) return NO;
	
	int count=[[[self mailScript] executeSubroutine:@"unread_count"
																   arguments:nil
																	   error:nil]int32Value];
	//NSLog(@"count %d",count);
	NSImage *icon=[object icon];
	[icon setFlipped:flipped];
	NSImageRep *bestBadgeRep=[icon bestRepresentationForSize:rect.size];    
	[icon setSize:[bestBadgeRep size]];
	[icon drawInRect:rect fromRect:NSMakeRect(0,0,[bestBadgeRep size].width,[bestBadgeRep size].height) operation:NSCompositeSourceOver fraction:1.0];
	
	QSCountBadgeImage *countImage=[QSCountBadgeImage badgeForCount:count];
	
	[countImage drawBadgeForIconRect:rect];				
	
	return YES;	
}

@end
