//
//  JavelinNotes.m
//  JavelinM
//
//  Created by Novica Radonic on 09/05/2017.
//
//

#import "JavelinNotes.h"
#import "JavelinPdfView.h"
#import "JavelinDocument.h"
#import "JAnnotations.h"
#import "JAnnotation.h"
#import "NoteViewProtocol.h"

@implementation JavelinNotes
//@synthesize PdfView=m_view;

-(id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if ( self )
    {
        //[self setDataSource:self];
        m_pdfView = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)mouseDown:(NSEvent *)theEvent 
{
    ///CODE YOU WANT EXECUTED WHEN MOUSE IS CLICKED
    if ( theEvent.clickCount == 2 )
    {
        NSPoint globalLocation = [theEvent locationInWindow];
        NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
        NSInteger clickedRow = [self rowAtPoint:localLocation];

        //NSLog(@"Mouse double-click occurred");
        if (m_pdfView != nil )
        {
            JAnnotation* ann = [self itemAtRow:clickedRow];
            [m_pdfView itemDoubleClicked:ann];
            //[m_delNoteView itemDoubleClicked:clickedRow];
        }
    }
    // call this to get the usual behaviour of your outline
    // view in addition to your custom code
    [super mouseDown:theEvent];
}

-(void)setNoteViewDelegate:(id)del
{
    m_pdfView = del;
}

- (NSMenu *)defaultMenu 
{
    if([self selectedRow] < 0) 
        return nil;

    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Model browser context menu"];
    [theMenu insertItemWithTitle:@"Delete note" action:@selector(deleteNote:) keyEquivalent:@"" atIndex:0];
	[theMenu insertItemWithTitle:@"Export all notes" action:@selector(exportAllNotes:) keyEquivalent:@"" atIndex:1];
    return theMenu;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent 
{
    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];
    m_selectedAnnotation = [self itemAtRow:clickedRow];
    
    return [self defaultMenu];  
}

-(void)deleteNote:(id)sender
{
    if (m_pdfView != nil )
    {
        [m_pdfView deleteNote:m_selectedAnnotation];
    }
}

-(void)exportAllNotes:(id)sender
{
	if ( m_pdfView != nil )
	{
		[m_pdfView exportAllNotes];
	}
}
@end
