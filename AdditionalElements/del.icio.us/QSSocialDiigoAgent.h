//
//  QSSocialDiigoAgent.h
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSSocialAgent.h"

@interface QSSocialDiigoAgent : QSSocialAgent {

}
- (NSString*)convertDiigoDateRep:(NSString*)dateRep;
- (id)retrieveDiigoObject:(NSString*)apiURLStr;
- (NSString*)hashRep:(NSString*)inputStr;
- (id)cacheEntryForDiigoRecord:(NSDictionary*)diigoRep;
@end
