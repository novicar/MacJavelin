//
//  Note.m
//  JavelinM
//
//  Created by harry on 30/01/2015.
//
//

#import "Note.h"

@implementation Note

- (void) showNote:(PDFAnnotationText*)annotation inWindow:(NSWindow*)window
{
	[NSBundle loadNibNamed:@"Note" owner:self];// topLevelObjects:nil];
	
	m_annotation = annotation;
	
	[text setFont:[NSFont userFontOfSize:18]];
	
	NSString* s = [annotation contents];
	if ( s == nil )
		[text setString:@""];
	else
		[text setString:s];
	
	//NSLog(@"IN --> %@", s);
	m_window = window;
	
	[[btnDelete cell] setBackgroundColor:[NSColor redColor]];
	
    [NSApp beginSheet: note
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (IBAction)deleteNote: (id)sender
{
}

- (IBAction)closeNote: (id)sender
{
    [NSApp endSheet:note];
}

- (IBAction)editNote: (id)sender
{
	if ( m_annotation != nil )
	{
		NSString* s = [text string];
		//NSLog(@"OUT --> %@", s);

		if ( s != nil )
		{
			[m_annotation setContents:s];
			if ( m_window != nil )
				[m_window setDocumentEdited:YES];
			
		}
		m_annotation = nil;

		[self closeNote:sender];
	}
	
//	[text setString:@""];
}
@end
