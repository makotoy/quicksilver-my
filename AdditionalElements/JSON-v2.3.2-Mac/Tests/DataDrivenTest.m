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


#import "DataDrivenTest.h"
#import <JSON/JSON.h>

@implementation DataDrivenTest

- (void)setUp {
    [super setUp];
    writer.sortKeys = YES;
    
    dir = @"Tests/Data";
    files = [[NSFileManager defaultManager] enumeratorAtPath:dir];
}

- (void)withSuffix:(NSString *)suffix {
	NSString *file;
    while ((file = [files nextObject])) {
        if (![[file pathExtension] isEqualToString:@"json"])
            continue;
        
        NSRange range = [file rangeOfString:@"fail"];
        if (range.location != NSNotFound)
            continue;
        
        NSString *jsonPath = [dir stringByAppendingPathComponent:file];        
        NSString *jsonText = [NSString stringWithContentsOfFile:jsonPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
        XCTAssertNotNil(jsonText, @"Could not load %@", jsonPath);
        
        id parsed;
        XCTAssertNoThrow(parsed = [parser objectWithString:jsonText]);
        XCTAssertNotNil(parsed);
        XCTAssertNil(parser.errorTrace, @"%@: %@", jsonPath, parser.errorTrace);
        
        NSString *written;
        XCTAssertNoThrow(written = [writer stringWithObject:parsed]);
        XCTAssertNotNil(written);
        XCTAssertNil(writer.errorTrace, @"%@: %@", jsonPath, writer.errorTrace);
        
        NSString *path = [jsonPath stringByAppendingPathExtension:suffix];
        NSString *text = [NSString stringWithContentsOfFile:path
												   encoding:NSUTF8StringEncoding
													  error:nil];
        XCTAssertNotNil(text, @"Could not load %@", path);
		
        // Chop off newline at end of string
        text = [text substringToIndex:[text length]-1];
        XCTAssertEqualObjects(written, text, @"at %@", jsonPath);
    }
	
}

- (void)testTerse {
	writer.humanReadable = NO;
    [self withSuffix:@"terse"];
}

- (void)testPretty {
	writer.humanReadable = YES;
    [self withSuffix:@"pretty"];
}

- (void)testFail {
    parser.maxDepth = 19;
    
    NSString *file;
    while ((file = [files nextObject])) {
        if (![file hasPrefix:@"fail"])
            continue;
        
        NSString *path = [dir stringByAppendingPathComponent:file];
        NSString *json = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];

        XCTAssertNil([parser objectWithString:json]);
        XCTAssertNotNil(parser.errorTrace);
    }
}

@end
