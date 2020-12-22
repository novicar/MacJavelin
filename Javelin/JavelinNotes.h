//
//  JavelinNotes.h
//  JavelinM
//
//  Created by Novica Radonic on 09/05/2017.
//
//

#import <Cocoa/Cocoa.h>

//@class JavelinPdfView;
@class JAnnotation;

@interface JavelinNotes : NSOutlineView //<NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    //JavelinPdfView*     __unsafe_unretained m_view;
    id  m_pdfView;
    JAnnotation* m_selectedAnnotation;
}

//@property (readwrite, assign) JavelinPdfView* PdfView;
-(void)setNoteViewDelegate:(id)del;
-(void)deleteNote:(id)sender;
-(void)exportAllNotes:(id)sender;
@end
