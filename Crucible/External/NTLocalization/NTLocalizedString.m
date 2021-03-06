// NTLocalizedString.m
// Derived from Blacktree codebase.
// 2009-11-29 Makoto Yamashita.

#import "NTLocalizedString.h"
#import "NTViewLocalizer.h"

//#import <OmniFoundation/OmniFoundation.h>

@implementation NTLocalizedString

+ (NSString*)localize:(NSString*)str;
{
    return [self localize:str table:nil];
}

+ (NSString*)localize:(NSString*)str table:(NSString*)table;
{
    // if table is nil, use the default
    if (!table)
        table = @"default";
    
    // FIXME: I'm not sure this is used right now, and it looks broken to me...
    return NSLocalizedStringFromTableInBundle(str, table, [NSBundle mainBundle], @"");
}

@end