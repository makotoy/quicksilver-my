//
//  QSDeliciousPlugIn_Source.h
//  QSDeliciousPlugIn
//
//  Created by Nicholas Jitkoff on 9/18/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//
//  Derived from Blacktree codebase
//  Makoto Yamashita 2009-11-30

#import "QSSocialAgent.h"

typedef enum _QSDeliciousPlugIn_Site {
    QSDeliciousPlugIn_Delicious,
    QSDeliciousPlugIn_Diigo
} QSDeliciousPlugIn_Site;

@interface QSDeliciousPlugIn_Source : QSObjectSource <QSSocialAgentDelegate> {
	NSMutableArray *tags;
    NSArray *agents;
	IBOutlet NSTextField *userField;
	IBOutlet NSTextField *passField;
}
+ (NSURL*)urlForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username;
+ (NSURL*)urlForSite:(QSDeliciousPlugIn_Site)site user:(NSString*)username password:(NSString*)password;
- (QSSocialAgent*)agentForSite:(QSDeliciousPlugIn_Site)site;
- (NSString *)passwordForSite:(QSDeliciousPlugIn_Site)site user:(NSString *)username;
- (void)refreshSource;
@end
