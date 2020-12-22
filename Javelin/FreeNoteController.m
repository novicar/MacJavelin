//
//  FreeNoteController.m
//  JavelinM
//
//  Created by harry on 13/02/2015.
//
//

#import "FreeNoteController.h"
#import "Note.h"
#import "JAnnotation.h"
#import "JavelinPdfView.h"

@interface FreeNoteController ()

@end

@implementation FreeNoteController

- (void)windowDidLoad {
    [super windowDidLoad];
	m_annot = nil;
	m_view = nil;
	
    [[[self window]  contentView] setAutoresizesSubviews:YES];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteDidResignMain:) name:NSWindowDidResignMainNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteDidResize:) name:NSWindowDidResizeNotification object:[self window]];
	
	[[self window] makeFirstResponder:m_text];
	[[self window] setDelegate:self];
	
	//[m_btnDelete setBordered:NO];
	//[[m_btnDelete cell] setBackgroundColor:[NSColor redColor]];
	
	/*NSColor *color = [NSColor colorWithRed:1.0 green:0.7 blue:0.7 alpha:1.0];
	NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[m_btnDelete attributedTitle]];
	NSRange titleRange = NSMakeRange(0, [colorTitle length]);
	[colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
	[m_btnDelete setAttributedTitle:colorTitle];*/
}

-(void)noteDidResignMain:(id)sender
{
	//NSLog(@"-->>Resign main");
}

-(void)noteDidResize:(id)sender
{
	//NSLog(@"Resize %@", NSStringFromClass([sender class]));
	[self doResize:[[self window] frame]];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	//NSLog(@"size: %@", NSStringFromSize(frameSize));
	m_rectCurrent.size.width = frameSize.width;
	m_rectCurrent.size.height= frameSize.height;
	
	return frameSize;
}

- (void)windowDidMove:(NSNotification *)notification
{
	NSWindow* draggedWindow = [notification object];
	m_deltaX = m_rectInitial.origin.x - [draggedWindow frame].origin.x;
	m_deltaY = m_rectInitial.origin.y - [draggedWindow frame].origin.y;
	//NSLog(@"moved %@ deltaX=%f deltaY=%f", NSStringFromRect([draggedWindow frame]), m_deltaX, m_deltaY);
	
	m_rectCurrent = [draggedWindow frame];
}

-(IBAction)onDeleteNote: (id)sender
{
	if ( m_annot != nil )
	{
		//PDFPage* page = [m_annot page];
		//[page removeAnnotation:m_annot];
		[m_view deleteAnnotation:self];
	}
	
	[self close];
}

-(IBAction)onOK:(id)sender
{
	//NSRect rect = [[self window] frame];
	//NSLog(@"Orig: %@", NSStringFromRect(m_rectInitial));
	//NSLog(@"Curr: %@", NSStringFromRect(m_rectCurrent));
	
	//float fDeltaX = m_rectInitial.origin.x - m_rectCurrent.origin.x;
	//float fDeltaY = m_rectInitial.origin.y - m_rectCurrent.origin.y;
	
	if ( m_annot != nil )
	{
		//NSRect rect = [m_annot bounds];
		NSString* ss = [m_text string];
		
		PDFPage* page = [m_annot page];
		NSRect rPage = [page boundsForBox:kPDFDisplayBoxCropBox];
		
/*		//[self convertRect:[annot bounds] fromPage:[self currentPage]]
		NSRect rectView = m_rectCurrent;//[[self window] frame];
		rectView.origin.x += m_deltaX;
		rectView.origin.y += m_deltaY;
		
		NSRect r1 = [m_view convertRect:rectView toPage:page];
		
		NSLog(@"Converted: %@", NSStringFromRect(r1));
*/

		NSRect rWindow = [m_view convertRect:m_rectCurrent toPage:page];
		//NSPoint pt = [m_view convertPoint:NSMakePoint(m_deltaX, m_deltaY) toPage:page];
		
		m_deltaY /= m_aspect.height;
		m_deltaX /= m_aspect.width;
		
		NSRect rAnnot = [m_annot boundary];
		rAnnot.origin.x -= m_deltaX;
		rAnnot.origin.y -= m_deltaY;
		rAnnot.size.height = rWindow.size.height;
		rAnnot.size.width  = rWindow.size.width;
		
		//rAnnot.origin.x /= m_aspect.width;
		//rAnnot.origin.y /= m_aspect.height;
		//rAnnot.size.width /= m_aspect.width;
		//rAnnot.size.height/= m_aspect.height;
		
		if ( rAnnot.origin.x < 0 ) rAnnot.origin.x = 0;
		if ( rAnnot.origin.y < 0 ) rAnnot.origin.y = 0;
		if ( rAnnot.size.height < 0 ) rAnnot.size.height = 100;
		if ( rAnnot.size.width < 0 ) rAnnot.size.width = 100;
//		if ( rAnnot.size.height > rPage.size.height ) rAnnot.size.height = 100;
//		if ( rAnnot.size.width > rPage.size.width) rAnnot.size.width = 100;
		
		/*PDFAnnotationFreeText* aa = [[PDFAnnotationFreeText alloc] initWithBounds:rAnnot];
		[aa setColor:[NSColor colorWithRed:NOTE_RED green:NOTE_GREEN blue:NOTE_BLUE alpha:0.5f]];
		[aa setContents:ss];
		       
        
		[page removeAnnotation:m_annot];
		[page addAnnotation:aa];*/
        
        [m_annot setText:ss];
        
		if ( m_view != nil )
		{
			[m_view annotationsChangedOnPage:page];
			[[m_view window] setDocumentEdited:YES];
			[m_view setNeedsLayout:YES];
			[m_view setNeedsDisplay:YES];
		}
		m_annot = nil;
	}
	[self close];
}

-(IBAction)onCancel:(id)sender
{
	if ( m_annot != nil && m_annot.newNote )
	{
		[m_view deleteAnnotation:self];
	}
	m_annot = nil;
	m_view = nil;
	[self close];
}

-(void)doResize:(NSRect)rect
{
	NSWindow* ww = [self window];
	//[ww setContentSize:rect.size];
	[ww setFrame:rect display:YES];
	
/*	NSRect r1 = rect;
	
	r1.origin.x =3;
	r1.origin.y =3;
	r1.size.width = 50;
	r1.size.height = 15;
	
	[m_btnOK setFrame:r1];
	
	r1.origin.x = 60;
	r1.origin.y = 3;
	r1.size.width = 100;
	r1.size.height = 15;
	
	[m_btnCancel setFrame:r1];

	r1.origin.x = 3;
	r1.origin.y = 30;
	r1.size.height = rect.size.height-45;
	r1.size.width = rect.size.width - 10;

	NSLog(@"rect %@", NSStringFromRect(r1));
	[m_text setFrame:r1];
*/	
	//NSLog(@"Main: %d",[ww canBecomeMainWindow]);
	[ww makeKeyAndOrderFront:ww];
	//[ww makeFirstResponder:m_text];
	//[ww makeMainWindow];

}

-(void)open:(JAnnotation*)annot inRect:(NSRect)rect inView:(JavelinPdfView*)view
{
	m_annot = annot;
	m_view = view;
	
	[m_text setFont:[NSFont userFontOfSize:18]];
	
	[self doResize:rect];
	
	[m_text setString:[annot getContent]];
	
	m_rectInitial = rect;
	m_rectCurrent = rect;

	m_deltaY = m_deltaX = 0.0;
	
	PDFPage* page = [annot page];
	NSRect rectPage = [view convertRect:rect fromPage:page];
	
	m_aspect.height = rectPage.size.height / rect.size.height;
	m_aspect.width  = rectPage.size.width  / rect.size.width;
	
	//NSLog(@"Orig: %@", NSStringFromRect(m_rectInitial));
}

@end
