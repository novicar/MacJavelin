//
//  JavelinPdfView.h
//  Javelin
//
//  Created by harry on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "DocInfo.h"
#import "PDFView+rightMouseDown.h"
//#import "AnnotationPanel.h"
//#import "JavelinDocument.h"
#import "NoteViewProtocol.h"

@class DocumentRecord;
@class JavelinDocument;
@class Watermark;
@class Note;
@class JAnnotation;

@interface JavelinPdfView : PDFView <NoteViewProtocol>{
@private
	JAnnotation		*_activeAnnotation;
	PDFPage				*_activePage;
    NSRect				_wasBounds;
	NSPoint				_mouseDownLoc;
	NSPoint				_clickDelta;
	BOOL				_dragging;
	BOOL				_resizing;
	BOOL				_mouseDownInAnnotation;
	JavelinDocument		*_javelinDocument;
	
	Watermark			*_watermark;
	
	NSMenu*				m_selectionMenu;
	NSMenu*				m_normalMenu;
	NSMenu*				m_deleteMenu;
	NSMenu*				m_deleteAndEditMenu;
	PDFAnnotation*		m_selectedAnnotationNative;
    JAnnotation*        m_selectedAnnotation;
	NSMutableArray*		m_selectedAnnotations;
	NSPoint				m_ptAnnotation;
	Note*				m_note;
	float				m_fDPI;
	
	id					delegate;
    id                  m_delNoteView;
	
	int					m_annotationType;
	
	NSMutableDictionary<NSString *,id> *m_defaultPrintDict;
    JAnnotation*        _myActiveAnnotation;
    //NSFont*             m_fontAnnotation;
    //NSMutableDictionary* m_annotations; moved to JavelinDocument
    NSDictionary*       m_annotAttributes;
    NSCursor*           m_currentCursor;
}

-(void)setDelegate:(id)del;
-(void)setNoteViewDelegate:(id)del;

- (void) transformContextForPage: (PDFPage *) page;
//- (void) setWatermark:(NSString*)sText type:(int)nType;
/*- (void) setWatermark:(const unsigned char*)szWMText 
				 type:(int)nWMType 
		   forDocName:(const unsigned char*)szDocName 
				   ID:(unsigned int)docID
			 authCode:(NSString*)authCode;
*/
- (void) setWatermark:(PDOCEX_INFO)pDocInfo
			 authCode:(NSString*)authCode;

- (void) delete: (id) sender;
- (int) printJvlnDocument: (id) sender;
- (void) printDrmx:(DocumentRecord *)docRec;
- (void) printPanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (void) printPage:(NSImage*)image withPrintInfo:(NSPrintInfo*)pi;
- (void) doPrint;
- (void)printPDF:(NSURL *)fileURL;
- (void)printPDFFromData:(NSData*)data printInfo:(NSPrintInfo*)printInfo page:(PDFPage*)page;

- (PDFAnnotationLink *) activeAnnotation;
- (void) setActiveAnnotation: (PDFAnnotationLink *) newLink;
- (NSSize) defaultNewLinkSize;
- (NSRect) resizeThumbForRect: (NSRect) rect rotation: (int) rotation;
- (BOOL) mouseDownDrag: (NSEvent *) theEvent;

- (void) setJavelinDocument: (JavelinDocument*)pDoc;
- (JavelinDocument*) javelinDocument;

- (BOOL) checkPrinterName:(NSString*)sPrinterName1;

- (void) createMenus;
- (void) hightlightSel:(id)sender;
- (void) strikeoutSel:(id)sender;
- (void) underlineSel:(id)sender;
- (void) markup:(PDFSelection*)selMain withType:(PDFMarkupType)type;

- (void) deleteAnnotation:(id)sender;
- (void) editMyNote:(id)sender;
- (void) addNote:(id)sender;
- (void) selectAnnotation:(PDFAnnotation*)annot clickNo:(int)nClicks;
- (void) annotationChanged: (id) sender;
- (void) removeAuthorisation: (id)sender;
- (void) annotationChanged1;
-(int)getPageNumber:(PDFPage*)page;
-(void) drawNote: (CGContextRef) context inRect:(CGRect) rect withColor:(CGColorRef) color text:(NSString*) sText withOffset:(CGPoint) ptOffset;

-(float) getDPI;
-(CGPoint)getOffset:(PDFPage*)pdfPage;
//- (void)displayAlert:(NSString*)sTitle message:(NSString*)sMessage;


@end


