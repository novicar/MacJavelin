//
//  Note.h
//  JavelinM
//
//  Created by harry on 30/01/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

//#define NOTE_WIDTH			24
//#define NOTE_HEIGHT			24
#define FREE_NOTE_HEIGHT	100
#define FREE_NOTE_WIDTH		200

#define NOTE_RED			0.9f
#define NOTE_GREEN			1.0f
#define NOTE_BLUE			0.6f

@interface Note : NSWindow
{
	PDFAnnotationText*	m_annotation;
	NSWindow*			m_window;
	//PDFPage*			m_page;
	
	IBOutlet		NSWindow		*note;
	IBOutlet		NSTextView		*text;
	
	IBOutlet		NSButton		*btnDelete;
}

- (void) showNote:(PDFAnnotationText*)annotation inWindow:(NSWindow*)window;

- (IBAction)closeNote: (id)sender;
- (IBAction)editNote: (id)sender;
- (IBAction)deleteNote: (id)sender;
@end
