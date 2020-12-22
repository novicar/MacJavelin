//
//  AuthController.m
//  Javelin
//
//  Created by harry on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AuthController.h"
#import "General.h"


@implementation AuthController

- (void) awakeFromNib
{
	//[NSBundle loadNibNamed:@"AuthCode" owner:nil];
}

- (id) init
{
    self = [super initWithWindowNibName:@"AuthCode"];
    if (self) {
        // Initialization code here.
		m_bOK = NO;
		_code = nil;
    }
    
    return self;
}
/*
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindowNibName:@"AuthCode"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
*/
/*
- (void)dealloc
{
    [super dealloc];
}
*/
- (void)windowDidLoad
{
    [super windowDidLoad];
	
	//NSLog(@"AuthCode Nib file loaded!");
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction) doLoadAC: (id) sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	[panel setCanCreateDirectories:NO];
	[panel setTitle:@"Open authorisation code from file"];
	[panel setMessage:@"Open authorisation code."];
	
	// Display the panel attached to the document's window.
	@try{
		[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
		{
			if (result == NSFileHandlingPanelOKButton) 
			{
				//NSArray* urls = [panel URLs];
				NSURL* surl = nil;
				surl = [panel URL];
				[self populateFromFile:surl];
			}
		}];
	}
	@catch (NSException* exception) {
		[General displayAlert:[exception description] message:[exception reason]];
	}
	//[panel release];
/*	@try
	{
		NSInteger result = [panel runModal];
		NSURL *url = nil;
		if (result == NSFileHandlingPanelOKButton)
		{
			url = [panel URL];

			[NSApp endSheet:panel];
			panel = nil;

			[self populateFromFile:url];
		}
		
	}
	@catch (NSException* ex) {
		[General displayAlert:[ex description] message:[ex reason]];
	}
	@finally {
		if ( panel != nil)
			[NSApp endSheet:panel];
	}*/
}

- (BOOL)populateFromFile:(NSURL *)url
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( [fm isReadableFileAtPath:[url path]] == YES )
	{
		NSDictionary *attrs = [fm attributesOfItemAtPath:[url path] error:NULL];
		unsigned long long size = [attrs fileSize];
		if ( size < 5 || size > 25 )
		{
			[General displayAlert:@"Invalid authorisation code" 
						  message:@"File does not contain Javelin authorisation code!"];
			return NO;
		}

		@try {
			NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
			if ( content == nil )
			{
				[General displayAlert:@"Invalid authorisation code" 
							  message:@"File does not contain Javelin authorisation code!"];
				return NO;
			}
			//NSLog( @"%@", content );
			if ( [content length] > 20 )
				[_authCode setStringValue:[content substringToIndex:20]];
			else
				[_authCode setStringValue:content];
			
			return YES;
		}
		@catch (NSException *exception) {
			[General displayAlert:[exception description] message:[exception reason]];
			return NO;
		}
		@finally {
		}
	}
	else
	{
		[General displayAlert:@"File error" 
					  message:@"Unable to open file!"];
	}
	
	return NO;
}

- (IBAction) doPasteAC: (id) sender
{    
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
	
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSString *s = [objectsToPaste objectAtIndex:0];
        [_authCode setStringValue:s];
    }
}
/*
-(int) showAuthPanel
{
	[NSApp beginSheet: _authCodePanel 
	   modalForWindow: [NSApp mainWindow] 
		modalDelegate: self 
	   didEndSelector: @selector(authCodePanelDidEnd: returnCode: contextInfo:) 
		  contextInfo: NULL];

	[NSApp runModalForWindow:_authCodePanel];
	return 1;
}
*/
- (void)showAuthPanel1: (NSWindow *)window
// User has asked to see the dialog. Display it.
{
	static BOOL loaded = NO;
	
    //if (!loaded)
        loaded = [NSBundle loadNibNamed: @"AuthCode" owner: self];
	
    [NSApp beginSheet: _authCodePanel
	   modalForWindow: nil
		modalDelegate: nil
	   didEndSelector: nil//@selector(authCodePanelDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
	if ( _acLabel != nil )
	{
		[_acLabel setStringValue:_docInfo];
		[_lblID setStringValue:[NSString stringWithFormat:@"DocID:%u", _docID]];
	}

    [NSApp runModalForWindow: _authCodePanel];
	
	NSInteger mmm = 0;
    // Dialog is up here.
    [NSApp endSheet: _authCodePanel returnCode:mmm];
    [_authCodePanel orderOut: self];
}

- (IBAction)acceptAC:(id)sender
{
	m_bOK = YES;
		
	_code = [_authCode stringValue];
//    [NSApp stopModalWithCode:1];
	[NSApp endSheet:[sender window]
		 returnCode:[sender tag]];
	 [[sender window] orderOut: self];
}

- (IBAction)cancelAC:(id)sender
{
	m_bOK = NO;
	[NSApp endSheet:[sender window]
		 returnCode:[sender tag]];
	[[sender window] orderOut: self];
}

- (NSString*)getCode
{
	return _code;
}

- (BOOL) isOK
{
	return m_bOK;
}

- (void) setDocInfo:(NSString *)sDocInfo docID:(unsigned int)nDocID
{
	//[_docInfo release];
	
	if ( [sDocInfo length] == 0 )
		_docInfo = @"file.pdf";
	else
		_docInfo = [NSString stringWithString:sDocInfo];
	
	_docID = nDocID;
}

- (void) authCodePanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
	// Close.
	//[_authCodePanel close];

	
/*	// Make sure page number entered is valid.
	if ((returnCode < 1) || (returnCode > [[_pdfView document] pageCount]))
	{
		// Zero may indicate user canceled, don't beep in that case.
		if (returnCode != 0)
			NSBeep();
		
		return;
	}
	
	// Go to that page.
	[_pdfView goToPage: [[_pdfView document] pageAtIndex: returnCode - 1]];
*/
}

- (IBAction)endSheet: (id)sender
{
	if ( [sender tag] == 2 )//OK button
	{
		m_bOK = YES;
		_code = [_authCode stringValue];
	}
	else
	{
		m_bOK = NO;
	}

	[NSApp endSheet: [sender window]  returnCode: [sender tag]];
	
	[[sender window] orderOut: self];
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    // Allow changes only for uncommitted text
	return YES;
}
/*
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    BOOL retval = NO;
    // When return is entered, record and color the newly committed text
    if (@selector(insertNewline:) == commandSelector) {
        unsigned textLength = [[textView string] length];
        if (textLength > committedLength) {
            [textView setSelectedRange:NSMakeRange(textLength, 0)];
            [textView insertText:@"\n"];
            [textView setTextColor:[NSColor redColor] range:NSMakeRange(committedLength, textLength - committedLength)];
            textLength++;
            committedLength = textLength;
        }
        retval = YES;
    }
    return retval;
}*/
@end
