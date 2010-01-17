//
//  NSURL_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 7/13/04.

//  2010-01-16 Makoto Yamashita

#import <Cocoa/Cocoa.h>


@interface NSURL (Keychain)
- (NSString *)keychainPassword;
- (OSErr)addPasswordToKeychain;
- (NSURL *)URLByInjectingPasswordFromKeychain;
@end
