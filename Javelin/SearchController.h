//
//  SearchController.h
//  JavelinM
//
//  Created by harry on 20/10/2016.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface SearchController : NSWindowController
{
	IBOutlet NSTextField*	m_txString;
	IBOutlet NSButton*		m_btnNext;
	IBOutlet NSButton*		m_btnPrevious;
	IBOutlet NSButton*		m_btnClose;
	
	//PDFDocument*			m_document;
	//PDFSelection*			m_selection;
	PDFView*				m_pdfView;
}

- (IBAction)findNext: (id)sender;
- (IBAction)findPrevious: (id)sender;
- (IBAction)close: (id)sender;

//@property (readwrite,atomic) PDFDocument* pdfDocument;
//@property (readwrite,atomic) PDFSelection* pdfSelection;
@property (readwrite,atomic) PDFView* pdfView;

@end
