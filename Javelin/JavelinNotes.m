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

/*
- (void)rightMouseDown:(NSEvent *)event
{
    [super rightMouseDown:event];
    
   NSLog(@"mamama");
    
    NSPoint globalLocation = [event locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];
    JAnnotation* ann = nil;

    if (m_pdfView != nil )
        ann = [self itemAtRow:clickedRow];

    if ( ann != nil )
        NSLog(@"nanan");
    
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
}*/

-(void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    ///CODE YOU WANT EXECUTED WHEN MOUSE IS CLICKED
    //NSLog(@"mkonji");
    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];
    JAnnotation* ann = nil;
    
    if (m_pdfView != nil )
        ann = [self itemAtRow:clickedRow];

    if ( ann == nil )
        return;

    if ( theEvent.clickCount == 2 )
        [m_pdfView itemDoubleClicked:ann];
    
    
    // call this to get the usual behaviour of your outline
    // view in addition to your custom code
    //[super mouseDown:theEvent];
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
    [theMenu insertItemWithTitle:@"Edit note" action:@selector(editNote:) keyEquivalent:@"" atIndex:1];
	[theMenu insertItemWithTitle:@"Export all notes" action:@selector(exportAllNotes:) keyEquivalent:@"" atIndex:2];
    
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
    if ( [m_selectedAnnotation isKindOfClass:[JAnnotation class]] )
    {
        
        if (m_pdfView != nil )
        {
            [m_pdfView deleteNote:m_selectedAnnotation];
        }
    }
}

-(void)editNote:(id)sender
{
    if ( [m_selectedAnnotation isKindOfClass:[JAnnotation class]] )
    {
        if (m_pdfView != nil )
        {
            //JAnnotation* ann = [self itemAtRow:clickedRow];
            [m_pdfView itemDoubleClicked:m_selectedAnnotation];
        }
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
