//
//  QSAppleMailPlugIn_Source.h
//  QSAppleMailPlugIn
//
//  Created by Nicholas Jitkoff on 9/28/04.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30


#import "QSAppleMailPlugIn_Source.h"
#import <QSCrucible/QSCrucible.h>

#define kQSAppleMailMailboxType @"qs.mail.mailbox"
#define kQSAppleMailMessageType @"qs.mail.message"
#define MAIL_BID @"com.apple.mail"

@interface QSAppleMailPlugIn_Source : NSObject
{
}
- (NSArray *)allMailboxes;
@end

