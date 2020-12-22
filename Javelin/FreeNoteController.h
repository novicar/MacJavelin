//
//  FreeNoteController.h
//  JavelinM
//
//  Created by harry on 13/02/2015.
//
//

#import <Cocoa/Cocoa.h>

#import <Quartz/Quartz.h>
@class JAnnotation;
@class JavelinPdfView;

@interface FreeNoteController : NSWindowController <NSWindowDelegate>
{
	IBOutlet NSTextView*	m_text;
	IBOutlet NSButton*		m_btnOK;
	IBOutlet NSButton*		m_btnCancel;
	IBOutlet NSButton*		m_btnDelete;
	
	//PDFAnnotationFreeText*	m_annot;
    JAnnotation*            m_annot;
	JavelinPdfView*			m_view;
	
	NSRect					m_rectInitial;
	NSRect					m_rectCurrent;
	
	float					m_deltaX;
	float					m_deltaY;
	
	NSSize					m_aspect;
	
}

-(IBAction)onOK:(id)sender;
-(IBAction)onCancel:(id)sender;
-(IBAction)onDeleteNote: (id)sender;

-(void)noteDidResignMain:(id)sender;
-(void)noteDidResize:(id)sender;
-(void)doResize:(NSRect)rect;
-(void)open:(JAnnotation*)annot inRect:(NSRect)rect inView:(JavelinPdfView*)view;
@end
