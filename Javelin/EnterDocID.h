//
//  EnterDocID.h
//  JavelinM
//
//  Created by harry on 06/02/2015.
//
//

#import <Cocoa/Cocoa.h>
@interface OnlyIntegerValueFormatter : NSNumberFormatter

@end

@interface EnterDocID : NSWindowController
{
	IBOutlet NSTextField*	m_textID;
	IBOutlet NSWindow*		m_window;
	
	unsigned int			m_docID;
}

- (void) showPanel:(unsigned int)documentID;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

- (unsigned int)documentID;
@end
