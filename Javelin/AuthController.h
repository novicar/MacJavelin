//
//  AuthController.h
//  Javelin
//
//  Created by harry on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AuthController : NSWindowController {
@private
	IBOutlet NSPanel				*_authCodePanel;				//authorisation code panel
	IBOutlet NSButton				*_pasteAC;					//paste authorisation code
	IBOutlet NSButton				*_loadAC;					//load auhtorisation code
	IBOutlet NSTextField			*_authCode;					//auth. code text field
	IBOutlet NSButton				*_acOK;						//auth.code OK button
	IBOutlet NSButton				*_acCancel;					//auth.code cancel button
	IBOutlet NSTextField			*_acLabel;					//AC label
	IBOutlet NSTextField			*_lblID;
	
	BOOL							m_bOK;
	NSString						*_code;
	NSString						*_docInfo;
	unsigned int					_docID;
}

//Auth code panel
- (IBAction) doLoadAC: (id) sender;
- (IBAction) doPasteAC: (id) sender;
//- (int) showAuthPanel;
- (void)showAuthPanel1: (NSWindow *)window;
- (void) authCodePanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
//- (IBAction)authCodeEnd:(id)sender;
- (IBAction)acceptAC:(id)sender;
- (IBAction)cancelAC:(id)sender;
- (NSString*)getCode;
- (BOOL)isOK;
- (void) setDocInfo:(NSString*)sDocInfo docID:(unsigned int)nDocID;
- (IBAction)endSheet: (id)sender;

- (BOOL)populateFromFile:(NSURL*)url;

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;
//- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;

@end
