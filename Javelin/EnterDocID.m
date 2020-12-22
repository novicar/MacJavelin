//
//  EnterDocID.m
//  JavelinM
//
//  Created by harry on 06/02/2015.
//
//

#import "EnterDocID.h"

@implementation OnlyIntegerValueFormatter

- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if([partialString length] == 0) {
        return YES;
    }

    NSScanner* scanner = [NSScanner scannerWithString:partialString];

    if(!([scanner scanInt:0] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }

    return YES;
}

@end

@interface EnterDocID ()

@end

@implementation EnterDocID

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) showPanel:(unsigned int)documentID
{
	[NSBundle loadNibNamed: @"EnterDocID" owner: self];
    [NSApp beginSheet: m_window
		   modalForWindow: nil
		modalDelegate: nil
	   didEndSelector: nil//@selector(authCodePanelDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];

	OnlyIntegerValueFormatter *formatter = [[OnlyIntegerValueFormatter alloc] init];
	[m_textID setFormatter:formatter];
	
	[NSApp runModalForWindow: m_window];
	/////////
	
	
	[NSApp endSheet: m_window returnCode:0];
    [m_window orderOut: self];
}

- (IBAction)ok:(id)sender
{
	//NSLog(@"OK: %@", [m_textID stringValue]);
//	_code = [_authCode stringValue];

	m_docID = [m_textID intValue];
	
	[NSApp endSheet:[sender window]
		 returnCode:[sender tag]];
	 [[sender window] orderOut: self];
}

- (IBAction)cancel:(id)sender
{
	//NSLog(@"Cancel");
	m_docID = 0;
	[NSApp endSheet:[sender window]
		 returnCode:[sender tag]];
	[[sender window] orderOut: self];
}

- (unsigned int)documentID
{
	return m_docID;
}
@end


