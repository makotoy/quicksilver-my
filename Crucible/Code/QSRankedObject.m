//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

#import "QSRankedObject.h" 

@implementation QSRankedObject

+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore {
    return [[[QSRankedObject alloc] initWithObject:newObject matchString:matchString order:newOrder score:newScore] autorelease];
}


- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore {
    self = [super init];
    if ( self ) {
        object = [newObject retain];
		order = newOrder;
        score = newScore;
        rankedString = [matchString retain];  
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    return [self initWithObject:[coder decodeObjectForKey:@"object"]
                    matchString:[coder decodeObjectForKey:@"string"]
                          order:[coder decodeIntForKey:@"order"]
                          score:[coder decodeFloatForKey:@"score"]];
    
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:object forKey:@"object"];
    [coder encodeObject:rankedString forKey:@"string"];
    [coder encodeInt:order forKey:@"order"];
    [coder encodeFloat:score forKey:@"score"];
}

- (void)dealloc {
    [object release];
	[rankedString release];
    [super dealloc];
}

- (NSComparisonResult) scoreCompare:(QSRankedObject *)compareObject {
    if( score != [compareObject score] ) {
        return ( score > [compareObject score] ? NSOrderedAscending : NSOrderedDescending );
	}
    return [self nameCompare:compareObject];
}

- (NSComparisonResult) nameCompare:(QSRankedObject *)compareObject {
    return [object nameCompare:compareObject->object];
}

- (NSComparisonResult) smartCompare:(QSRankedObject *)compareObject {
    if (score >= 1.0 || compareObject->score >= 1.0)
        return [self scoreCompare:compareObject];
    
    return [object nameCompare:compareObject->object];
}

- (BOOL)isEqual:(id)anObject {
    return [anObject isEqual:object];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) return YES;
    if ([object respondsToSelector:aSelector]) return YES;
    // QSLog(@"%@ does not respond to %@", object, NSStringFromSelector(aSelector) );
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	//  QSLog(@"forward %@", invocation);
    if ([object respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:object];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
    if (sig) return sig;
    return [object methodSignatureForSelector:sel];
}

- (NSString *)displayName {
	// if (rankedString) QSLog(@"rao %@", rankedString);
    if (rankedString) return rankedString;
    return [object displayName];
}
- (NSString *)description {return [NSString stringWithFormat:@"[%@ %f] ", object, score];}

- (BOOL)enabled {
	return [(QSBasicObject*)object enabled]; 	
}

@synthesize object;
@synthesize score;
@synthesize order;
@synthesize rankedString;

- (id)valueForKey:(NSString *)key {
	return [object valueForKey:key]; 	
}

- (void)setValue:(id)value forKey:(NSString *)key {
	[object setValue:value forKey:key];
}

- (NSMenu *)rankMenuWithTarget:(NSView *)target {
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"RankMenu"] autorelease];
	
    NSMenuItem *item;
	
	NSInteger myOrder = [self order];
	NSString *title = [NSString stringWithFormat:@"Score: %.0f", [self score] * 100];
	if (myOrder != NSNotFound)
		title = [NSString stringWithFormat:@"Rank: %d, %@", myOrder+1, title];
	
	item = [menu addItemWithTitle:title action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	
	if (myOrder != 0) {
		item = [menu addItemWithTitle:@"Make Default" action:@selector(defineMnemonicImmediately:) keyEquivalent:@""];
		[item setTarget:target];
	} else {
		item = [menu addItemWithTitle:@"Remove Default" action:@selector(removeMnemonic:) keyEquivalent:@""];
		[item setTarget:target];
	}

	item = [menu addItemWithTitle:@"Decrease Score" action:@selector(clearMnemonics:) keyEquivalent:@""];
	[item setTarget:target];
	
	return menu;
}
@end
