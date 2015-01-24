/*
 Copyright (C) 2007-2010 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ErrorTest.h"
#import <JSON/JSON.h>

#define assertErrorContains(e, s) \
    XCTAssertTrue([[e localizedDescription] hasPrefix:s], @"%@", [e userInfo])

#define assertUnderlyingErrorContains(e, s) \
    XCTAssertTrue([[[[e userInfo] objectForKey:NSUnderlyingErrorKey] localizedDescription] hasPrefix:s], @"%@", [e userInfo])

#define assertUnderlyingErrorContains2(e, s) \
    XCTAssertTrue([[[[[[e userInfo] objectForKey:NSUnderlyingErrorKey] userInfo] objectForKey:NSUnderlyingErrorKey] localizedDescription] hasPrefix:s], @"%@", [e userInfo])

@implementation ErrorTest

#pragma mark Generator

- (void)testUnsupportedObject
{
    NSError *error = nil;
    XCTAssertNil([writer stringWithObject:[NSData data] error:&error]);
    XCTAssertNotNil(error);
}

- (void)testNonStringDictionaryKey
{
    NSArray *keys = [NSArray arrayWithObjects:[NSNull null],
                     [NSNumber numberWithInt:1],
                     [NSArray array],
                     [NSDictionary dictionary],
                     nil];
    
    for (int i = 0; i < [keys count]; i++) {
        NSError *error = nil;
        NSDictionary *object = [NSDictionary dictionaryWithObject:@"1" forKey:[keys objectAtIndex:i]];
        XCTAssertNil([writer stringWithObject:object error:&error]);
        XCTAssertNotNil(error);
    }
}


- (void)testScalar
{    
    NSArray *fragments = [NSArray arrayWithObjects:@"foo", @"", [NSNull null], [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], nil];
    for (int i = 0; i < [fragments count]; i++) {
        NSString *fragment = [fragments objectAtIndex:i];
        
        // We don't check the convenience category here, like we do for parsing,
        // because the category is explicitly on the NSArray and NSDictionary objects.
        // XCTAssertNil([fragment JSONRepresentation]);
        
        NSError *error = nil;
        XCTAssertNil([writer stringWithObject:fragment error:&error], @"%@", fragment);
        assertErrorContains(error, @"Not valid type for JSON");
    }
}

- (void)testInfinity {
    NSArray *obj = [NSArray arrayWithObject:[NSNumber numberWithDouble:INFINITY]];
    NSError *error = nil;
    XCTAssertNil([writer stringWithObject:obj error:&error]);
    assertUnderlyingErrorContains(error, @"Infinity is not a valid number in JSON");
}

- (void)testNegativeInfinity {
    NSArray *obj = [NSArray arrayWithObject:[NSNumber numberWithDouble:-INFINITY]];
    NSError *error = nil;
    XCTAssertNil([writer stringWithObject:obj error:&error]);
    assertUnderlyingErrorContains(error, @"Infinity is not a valid number in JSON");
}

- (void)testNaN {
    NSArray *obj = [NSArray arrayWithObject:[NSDecimalNumber notANumber]];
    NSError *error = nil;
    XCTAssertNil([writer stringWithObject:obj error:&error]);
    assertUnderlyingErrorContains(error, @"NaN is not a valid number in JSON");
}

#pragma mark Scanner

- (void)testArray {
    NSError *error;

    XCTAssertNil([parser objectWithString:@"[1,,2]" error:&error]);
    assertErrorContains(error, @"Expected value");
    
    XCTAssertNil([parser objectWithString:@"[1,,]" error:&error]);
    assertErrorContains(error, @"Expected value");

    XCTAssertNil([parser objectWithString:@"[,1]" error:&error]);
    assertErrorContains(error, @"Expected value");


    XCTAssertNil([parser objectWithString:@"[1,]" error:&error]);
    assertErrorContains(error, @"Trailing comma disallowed");
    
    
    XCTAssertNil([parser objectWithString:@"[1" error:&error]);
    assertErrorContains(error, @"End of input while parsing array");
    
    XCTAssertNil([parser objectWithString:@"[[]" error:&error]);
    assertErrorContains(error, @"End of input while parsing array");

    // See if seemingly-valid arrays have nasty elements
    XCTAssertNil([parser objectWithString:@"[+1]" error:&error]);
    assertErrorContains(error, @"Expected value");
    assertUnderlyingErrorContains(error, @"Leading + disallowed");
}

- (void)testObject {
    NSError *error;

    XCTAssertNil([parser objectWithString:@"{1" error:&error]);
    assertErrorContains(error, @"Object key string expected");
        
    XCTAssertNil([parser objectWithString:@"{null" error:&error]);
    assertErrorContains(error, @"Object key string expected");
    
    XCTAssertNil([parser objectWithString:@"{\"a\":1,,}" error:&error]);
    assertErrorContains(error, @"Object key string expected");
    
    XCTAssertNil([parser objectWithString:@"{,\"a\":1}" error:&error]);
    assertErrorContains(error, @"Object key string expected");
    

    XCTAssertNil([parser objectWithString:@"{\"a\"" error:&error]);
    assertErrorContains(error, @"Expected ':'");
    

    XCTAssertNil([parser objectWithString:@"{\"a\":" error:&error]);
    assertErrorContains(error, @"Object value expected");
    
    XCTAssertNil([parser objectWithString:@"{\"a\":," error:&error]);
    assertErrorContains(error, @"Object value expected");
    
    
    XCTAssertNil([parser objectWithString:@"{\"a\":1,}" error:&error]);
    assertErrorContains(error, @"Trailing comma disallowed");
    
    
    XCTAssertNil([parser objectWithString:@"{" error:&error]);
    assertErrorContains(error, @"End of input while parsing object");
    
    XCTAssertNil([parser objectWithString:@"{\"a\":{}" error:&error]);
    assertErrorContains(error, @"End of input while parsing object");
}

- (void)testNumber {
    NSError *error;

    XCTAssertNil([parser objectWithString:@"[-" error:&error]);
    assertUnderlyingErrorContains(error, @"No digits after initial minus");
        
    XCTAssertNil([parser objectWithString:@"[+1" error:&error]);
    assertUnderlyingErrorContains(error, @"Leading + disallowed in number");

    XCTAssertNil([parser objectWithString:@"[01" error:&error]);
    assertUnderlyingErrorContains(error, @"Leading 0 disallowed in number");
    
    XCTAssertNil([parser objectWithString:@"[0." error:&error]);
    assertUnderlyingErrorContains(error, @"No digits after decimal point");
    
    
    XCTAssertNil([parser objectWithString:@"[1e" error:&error]);
    assertUnderlyingErrorContains(error, @"No digits after exponent");
    
    XCTAssertNil([parser objectWithString:@"[1e-" error:&error]);
    assertUnderlyingErrorContains(error, @"No digits after exponent");
    
    XCTAssertNil([parser objectWithString:@"[1e+" error:&error]);
    assertUnderlyingErrorContains(error, @"No digits after exponent");
}

- (void)testNull {
    NSError *error;
    
    XCTAssertNil([parser objectWithString:@"[nil" error:&error]);
    assertUnderlyingErrorContains(error, @"Expected 'null'");
}

- (void)testBool {
    NSError *error;
    
    XCTAssertNil([parser objectWithString:@"[truth" error:&error]);
    assertUnderlyingErrorContains(error, @"Expected 'true'");
    
    XCTAssertNil([parser objectWithString:@"[fake" error:&error]);
    assertUnderlyingErrorContains(error, @"Expected 'false'");
}    

- (void)testString {
    NSError *error;
    
    XCTAssertNil([parser objectWithString:@"" error:&error]);
    assertErrorContains(error, @"Unexpected end of string");

    XCTAssertNil([parser objectWithString:@"" error:&error]);
    assertErrorContains(error, @"Unexpected end of string");
    
    XCTAssertNil([parser objectWithString:@"[\"" error:&error]);
    assertUnderlyingErrorContains(error, @"Unescaped control character");
    
    XCTAssertNil([parser objectWithString:@"[\"foo" error:&error]);
    assertUnderlyingErrorContains(error, @"Unescaped control character");

    
    XCTAssertNil([parser objectWithString:@"[\"\\uD834foo\"" error:&error]);
    assertUnderlyingErrorContains(error, @"Broken unicode character");
    assertUnderlyingErrorContains2(error, @"Missing low character");
        
    XCTAssertNil([parser objectWithString:@"[\"\\uD834\\u001E\"" error:&error]);
    assertUnderlyingErrorContains(error, @"Broken unicode character");
    assertUnderlyingErrorContains2(error, @"Invalid low surrogate");
    
    XCTAssertNil([parser objectWithString:@"[\"\\uDD1Ef\"" error:&error]);
    assertUnderlyingErrorContains(error, @"Broken unicode character");
    assertUnderlyingErrorContains2(error, @"Invalid high character");

    
    for (unsigned short i = 0; i < 0x20; i++) {
        NSString *str = [NSString stringWithFormat:@"\"[%C\"", i];
        XCTAssertNil([parser objectWithString:str error:&error]);
        assertErrorContains(error, @"Unescaped control character");
    }
}

- (void)testObjectGarbage {
    NSError *error;

    XCTAssertNil([parser objectWithString:@"['1'" error:&error]);
    assertUnderlyingErrorContains(error, @"Unrecognised leading character");
    
    XCTAssertNil([parser objectWithString:@"['hello'" error:&error]);
    assertUnderlyingErrorContains(error, @"Unrecognised leading character");
    
    XCTAssertNil([parser objectWithString:@"[**" error:&error]);
    assertUnderlyingErrorContains(error, @"Unrecognised leading character");
    
    XCTAssertNil([parser objectWithString:nil error:&error]);
    assertErrorContains(error, @"Input was 'nil'");
}

@end
