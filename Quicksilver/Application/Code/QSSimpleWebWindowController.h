//
//  QSSimpleWebWindow.h
//  Quicksilver
//
//  Created by Alcor on 5/27/05.

//  2010-01-16 Makoto Yamashita

#import <Cocoa/Cocoa.h>


@interface QSSimpleWebWindowController : NSWindowController <NSToolbarDelegate> {

}
- (void)openURL:(NSURL *)url;
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL;
@end
