/*
 * Derived from Blacktree, Inc. codebase
 * 2010-01-09 Makoto Yamashita
 */

#import <Foundation/Foundation.h>
/*
@interface QSHotKeyControl : NSTextField {
	@private
	unsigned short		keyCode;
	unichar				character;
	unsigned long		modifierFlags;
}
@end
*/
@interface QSHotKeyField : NSTextField {
	IBOutlet NSButton *setButton;
	@private
	NSDictionary *hotKey;
}
- (IBAction)set:(id)sender;
- (NSDictionary *)hotKey;
- (void)setHotKey:(NSDictionary *)newHotKey;

- (void)updateStringForHotKey;
- (void)absorbEvents;
@end

@interface QSHotKeyCell : NSTextFieldCell {
}
@end

@interface QSHotKeyFormatter : NSFormatter
@end

@interface QSHotKeyFieldEditor : NSTextView {
    NSNumber *mVirtualKey;
    unsigned int mModifiers;
 
    BOOL mOperationModeEnabled;
    unsigned int mSavedHotKeyOperatingMode;
    BOOL validCombo;
	
	unichar				character;
	unsigned long		modifierFlags;
	id					oldWindowDelegate;
	BOOL				oldWindowDelegateHandledEvents;
	NSButton *			cancelButton;
	NSString *			defaultString;
}
+ (id)sharedInstance;
- (void)_disableHotKeyOperationMode;
- (void)_restoreHotKeyOperationMode;
- (void)_windowDidBecomeKeyNotification:(id)fp8;
- (void)_windowDidResignKeyNotification:(id)fp8;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)keyDown:(NSEvent *)theEvent;
- (BOOL)performKeyEquivalent:(id)fp8;
@end
