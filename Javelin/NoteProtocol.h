//
//  NoteProtocol.h
//  JavelinM
//
//  Created by harry on 30/01/2015.
//
//

#import <Foundation/Foundation.h>
//@class PDFAnnotationText;
@class JAnnotation;

@protocol NoteProtocol <NSObject>
//-(void)editNote:(PDFAnnotationText*)annot inWindow:(NSWindow*)window;
//-(void)editFreeNote:(PDFAnnotationFreeText*)annot inWindow:(NSWindow*)window viewRect:(NSRect)rectView pdfView:(PDFView*)view;
-(void)editNote:(JAnnotation*)annot inWindow:(NSWindow*)window;
-(void)editFreeNote:(JAnnotation*)annot inWindow:(NSWindow*)window viewRect:(NSRect)rectView pdfView:(PDFView*)view;

-(void)closeNoteWindow;
-(void)noteChanged;
@end
