//
//  QSSocialDeliciousAgent.h
//  QSDeliciousPlugIn
//
//  Created by Makoto Yamashita on 2/9/11.
//  Copyright 2011 Makoto Yamashita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSSocialAgent.h"

@interface QSSocialDeliciousAgent : QSSocialAgent <NSXMLParserDelegate> {
	NSMutableArray *posts;
	NSMutableArray *dates;
}

@end
