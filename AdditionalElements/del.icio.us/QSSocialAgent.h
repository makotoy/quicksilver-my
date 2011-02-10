//
//  QSSocialAgent.h
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSSocialAgent : NSObject {

}
- (id)getRecentDateForUser:(NSString*)user password:(NSString*)password;
- (id)tryAddNewBookmarks:(NSMutableArray*)bookmarks forUser:(NSString*)user password:(NSString*)password;

@end
