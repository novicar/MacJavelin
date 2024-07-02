//
//  JavelinPdfView.m
//  Javelin
//
//  Created by harry on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JavelinPdfView.h"
#import "JavelinController.h"
#import "JavelinDocument.h"
#import "DocumentDB.h"
#import "DocumentRecord.h"
#import "DrumlinPrintPanel.h"
#import "Watermark.h"
#import "JavelinPrintView.h"
#import "Log.h"
#import "General.h"
//#import "AnnotationPanel.h"
#import "Note.h"
#include "NoteProtocol.h"
#include "JAnnotation.h"
#include "JAnnotations.h"
#include "JavelinApplication.h"
#include "ActivityManager.h"

//un-comment if you want to debug by printing to PDF file
//#define DEBUG_PRINT	1
#define NOTE_WIDTH  (80)
#define NOTE_HEIGHT (30)
#define NOTE_FONT_SIZE (10)

@implementation JavelinPdfView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		_javelinDocument = nil;
		_watermark = nil;
		m_selectedAnnotations = nil;
		delegate = nil;
		
		m_defaultPrintDict = nil;
		
		/// Make a copy of the default paragraph style
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		/// Set line break mode
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;//NSLineBreakByTruncatingTail;
		/// Set text alignment
		paragraphStyle.alignment = NSTextAlignmentCenter;
		
        m_annotAttributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:NOTE_FONT_SIZE],
							   NSParagraphStyleAttributeName: paragraphStyle };
		
		m_fDPI = [self getDPI];
		//[self setMenu:nil];
	}
    
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if ( self )
	{
		_javelinDocument = nil;
		_watermark = nil;
		m_selectedAnnotations = nil;
		delegate = nil;
		m_defaultPrintDict = nil;
		/// Make a copy of the default paragraph style
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		/// Set line break mode
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;//NSLineBreakByTruncatingTail;
		/// Set text alignment
		paragraphStyle.alignment = NSTextAlignmentCenter;
		
        m_annotAttributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:NOTE_FONT_SIZE],
							   NSParagraphStyleAttributeName: paragraphStyle };
		
		m_fDPI = [self getDPI];
		//[self setMenu:nil];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if ( self )
	{
		_javelinDocument = nil;
		_watermark = nil;
		m_selectedAnnotations = nil;
		[self setMenu:nil];
		[self.window setMenu:nil];
		[self createMenus];
		delegate = nil;
		m_defaultPrintDict = nil;
		[[self window] setInitialFirstResponder:self];
		// Bring up annotation panel.
		//m_annotationPanel = [AnnotationPanel sharedAnnotationPanel];
		//[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(annotationChanged:)
		//	name: AnnotationPanelAnnotationDidChangeNotification object: m_annotationPanel];
		/// Make a copy of the default paragraph style
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		/// Set line break mode
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;//NSLineBreakByTruncatingTail;
		/// Set text alignment
		paragraphStyle.alignment = NSTextAlignmentCenter;
		
        m_annotAttributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:NOTE_FONT_SIZE],
							   NSParagraphStyleAttributeName: paragraphStyle };
		
		m_fDPI = [self getDPI];
	}
	return self;
}

-(float) getDPI
{
	NSScreen *screen = [NSScreen mainScreen];
	NSDictionary *description = [screen deviceDescription];
	NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
	CGSize displayPhysicalSize = CGDisplayScreenSize(
				[[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);

	float fDPI = (displayPixelSize.width / (float)displayPhysicalSize.width) * 25.4f; 
	//NSLog(@"DPI is %0.2f", fDPI );

	return fDPI;
}

-(void)hightlightSel:(id)sender
{
	PDFSelection* selMain = [self currentSelection];
	[self markup:selMain withType:kPDFMarkupTypeHighlight];
	
/*	if ( selMain != nil )
	{
		NSArray* lines = [selMain selectionsByLine];
		for( int i=0; i<[lines count]; i++ )
		{
			PDFSelection* sel = (PDFSelection*)[lines objectAtIndex:i];
			NSRect rect = [sel boundsForPage:[self currentPage] ];
			PDFAnnotationMarkup* ann = [[PDFAnnotationMarkup alloc] initWithBounds:rect];
			
			PDFPage* page = [self currentPage];
			//NSArray* pp = [page annotations];
			[page addAnnotation:ann];
		}
	}*/
}

- (void) strikeoutSel:(id)sender
{
	PDFSelection* selMain = [self currentSelection];
	[self markup:selMain withType:kPDFMarkupTypeStrikeOut];
}

- (void) underlineSel:(id)sender
{
	PDFSelection* selMain = [self currentSelection];
	[self markup:selMain withType:kPDFMarkupTypeUnderline];
}

#define FBOX(x) [NSNumber numberWithFloat:x]

- (void) markup:(PDFSelection*)selMain withType:(PDFMarkupType)type
{
	if ( selMain != nil )
	{
		NSArray* lines = [selMain selectionsByLine];
		for( int i=0; i<[lines count]; i++ )
		{
            PDFSelection* sel = (PDFSelection*)[lines objectAtIndex:i];
			long nRotation = [[self currentPage] rotation];
			NSRect rectOrig = [sel boundsForPage:[self currentPage] ];
			//PDFAnnotationMarkup* ann = [[PDFAnnotationMarkup alloc] initWithBounds:rect];
            CGRect crOrig = CGRectMake( rectOrig.origin.x, rectOrig.origin.y, rectOrig.size.width, rectOrig.size.height );
            PDFPage* page = [self currentPage];
			NSRect pageSize = [page boundsForBox:kPDFDisplayBoxMediaBox];
            
			NSRect rect = rectOrig;//[self convertRect:rectOrig toPage:page];
			if ( nRotation == 90 )
			{
				//page.
				rect.origin.x = rectOrig.origin.y;
				rect.origin.y = pageSize.size.width - rectOrig.origin.x - rectOrig.size.width;
				rect.size.width = rectOrig.size.height;
				rect.size.height = rectOrig.size.width;
			}
			
            int nPage = (int)CGPDFPageGetPageNumber([page pageRef]);
            JAnnotation* annNew = nil;
            
            if ( type == kPDFMarkupTypeStrikeOut)
                annNew = [[JAnnotation alloc] initWithType:rect type:ANNOTATION_STRIKEOUT];
            else if ( type == kPDFMarkupTypeUnderline )
                annNew = [[JAnnotation alloc] initWithType:rect type:ANNOTATION_UNDERLINE];
            else
                annNew = [[JAnnotation alloc] initWithType:rect type:ANNOTATION_HIGHLIGHT];
            
            [annNew setPage:page number:nPage];
            
            [[_javelinDocument annotations] addHighlight:annNew toPage:nPage];
            
			[[self window] setDocumentEdited: YES];
			[[self currentPage] setDisplaysAnnotations:YES];
			[self setNeedsDisplay:YES];
            
            [delegate noteChanged];
		}
		
	}
}

- (void) addNote:(id)sender
{
    int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
    NSRect rect = NSMakeRect(m_ptAnnotation.x, m_ptAnnotation.y-NOTE_HEIGHT, NOTE_WIDTH, NOTE_HEIGHT);
    JAnnotation* annNew = nil;
    
	CGPoint ptOffset = [self getOffset:[self currentPage]];
	if ( ptOffset.x != 0 )
	{
		rect.origin.x -= ptOffset.x;
		rect.origin.y += ptOffset.y;
	}
	
	//NSLog(@"Note added: %@", NSStringFromRect(rect));
	
    annNew = [[JAnnotation alloc] initWithType:rect type:ANNOTATION_NOTE];
    [annNew setPage:[self currentPage] number:nPage];
	[annNew setNewNote:YES];
	
    [[_javelinDocument annotations] addHighlight:annNew toPage:nPage];
    
    [[self window] setDocumentEdited: YES];
    [[self currentPage] setDisplaysAnnotations:YES];
    [self setNeedsDisplay:YES];
    
    m_annotationType = ANNOTATION_NOTE;
	m_selectedAnnotation = annNew;
	
	//NSLog(@"NewAnnot: %@", NSStringFromRect(annNew.boundary));
				//[delegate editNote:annot inWindow:[self window]];
    [delegate editFreeNote:annNew inWindow:[self window] viewRect:[self convertRect:[annNew boundary] fromPage:[self currentPage]] pdfView:self];
}

- (void) addNoteTEST:(id)sender
{
    int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
    NSRect rect = NSMakeRect(m_ptAnnotation.x, m_ptAnnotation.y-NOTE_HEIGHT, NOTE_WIDTH, NOTE_HEIGHT);
	NSRect rectOnPage = [self convertRect:rect toPage:[self currentPage]];
	
	JAnnotation* annNew = nil;
    
    annNew = [[JAnnotation alloc] initWithType:rectOnPage type:ANNOTATION_NOTE];
    [annNew setPage:[self currentPage] number:nPage];

    [[_javelinDocument annotations] addHighlight:annNew toPage:nPage];
    
    [[self window] setDocumentEdited: YES];
    [[self currentPage] setDisplaysAnnotations:YES];
    [self setNeedsDisplay:YES];
    
    m_annotationType = ANNOTATION_NOTE;
	//NSLog(@"NewAnnot: %@", NSStringFromRect(annNew.boundary));
				//[delegate editNote:annot inWindow:[self window]];
    [delegate editFreeNote:annNew inWindow:[self window] viewRect:[self convertRect:[annNew boundary] fromPage:[self currentPage]] pdfView:self];
}

- (void) removeAuthorisation: (id)sender
{
	JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
	
	if ( pApp != nil )
	{
		[pApp removeCurrentDocumentAuthorization];
		//[[self window] performClose:nil];
	}
}

- (void) addFreeNote:(id)sender
{
/*	PDFAnnotationFreeText * ann = [[PDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(m_ptAnnotation.x, m_ptAnnotation.y, FREE_NOTE_WIDTH, FREE_NOTE_HEIGHT)];
	[ann setContents:@""];
	[ann setColor:[NSColor colorWithRed:NOTE_RED green:NOTE_GREEN blue:NOTE_BLUE alpha:0.5f]];
	[[self currentPage] addAnnotation:ann];
	
	[self setNeedsDisplay:YES];
	[[self currentPage] setDisplaysAnnotations:YES];
	
	[self selectAnnotation:ann clickNo:2];*/
    [self addNote:sender];
}

- (void) editMyNote:(id)sender
{
	[self editNote:m_selectedAnnotation];
}

- (void) deleteAnnotation:(id)sender
{
    if ( m_selectedAnnotationNative != nil )
    {
        [[m_selectedAnnotationNative page] removeAnnotation: m_selectedAnnotationNative];
        m_selectedAnnotationNative = nil;
        [delegate noteChanged];
        return;
    }
    
	if ( m_selectedAnnotation != nil )
	{
		//[[m_selectedAnnotation page] removeAnnotation: m_selectedAnnotation];
        int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
        [[_javelinDocument annotations] removeAnnotation:m_selectedAnnotation fromPage:nPage];
		
		// Lazy, redraw entire view.
		[self setNeedsDisplay: YES];
		[[self window] setDocumentEdited: YES];
        [delegate noteChanged];
	}
	
	m_selectedAnnotation = nil;
	
	if ( m_selectedAnnotations != nil )
	{
        int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
		NSArray* anns = (NSArray*)[[_javelinDocument annotations] highlightsForPage:nPage];
        
		for( int i=(int)(m_selectedAnnotations.count-1); anns != nil && i>=0; i-- )
		{
			//NSNumber* pp = [m_selectedAnnotations objectAtIndex:i];
		
			JAnnotation* ann = [m_selectedAnnotations objectAtIndex:i];
			//[[self currentPage] removeAnnotation:ann];
            [[_javelinDocument annotations] removeAnnotation:ann fromPage:nPage];
		
		}
		
		//[m_selectedAnnotations removeAllObjects];
		m_selectedAnnotations = nil;
		
		[[self window] setDocumentEdited: YES];
		[[self currentPage] setDisplaysAnnotations:YES];
		[self setNeedsDisplay:YES];
        [delegate noteChanged];
	}
}

- (void) createMenus
{
	m_selectionMenu = [[NSMenu alloc] initWithTitle:@"Selection"];
	NSMenuItem *sMenuItem = [[NSMenuItem alloc] initWithTitle: @"Highlight" action:@selector(hightlightSel:) keyEquivalent:@""];
	[m_selectionMenu addItem:sMenuItem];

	NSMenuItem *s1MenuItem = [[NSMenuItem alloc] initWithTitle: @"Strikeout" action:@selector(strikeoutSel:) keyEquivalent:@""];
	[m_selectionMenu addItem:s1MenuItem];

	NSMenuItem *s2MenuItem = [[NSMenuItem alloc] initWithTitle: @"Underline" action:@selector(underlineSel:) keyEquivalent:@""];
	[m_selectionMenu addItem:s2MenuItem];


	m_normalMenu = [[NSMenu alloc] initWithTitle:@"Menu"];
	//NSMenuItem *nMenuItem = [[NSMenuItem alloc] initWithTitle: @"New Anchored Note" action:@selector(addNote:) keyEquivalent:@""];
	//[m_normalMenu addItem:nMenuItem];
	NSMenuItem *freeMenuItem = [[NSMenuItem alloc] initWithTitle: @"New Note" action:@selector(addFreeNote:) keyEquivalent:@""];
	[m_normalMenu addItem:freeMenuItem];

	m_deleteMenu = [[NSMenu alloc] initWithTitle:@"Delete"];
	NSMenuItem *delMenuItem = [[NSMenuItem alloc] initWithTitle: @"Delete mark-up" action:@selector(deleteAnnotation:) keyEquivalent:@""];

	[m_deleteMenu addItem:delMenuItem];

	m_deleteAndEditMenu = [[NSMenu alloc] initWithTitle:@"Delete or Edit"];
	NSMenuItem *delMenuItem1 = [[NSMenuItem alloc] initWithTitle: @"Delete note" action:@selector(deleteAnnotation:) keyEquivalent:@""];
	NSMenuItem *editMenutItem = [[NSMenuItem alloc] initWithTitle: @"Edit note" action:@selector(editMyNote:) keyEquivalent:@""];
	[m_deleteAndEditMenu addItem:delMenuItem1];
	[m_deleteAndEditMenu addItem:editMenutItem];
}

+ (NSMenu *)defaultMenu{
	//NSLog(@"DEFAULT MENU");
	return nil;
}

/*- (NSView*)hitTest:(NSPoint)aPoint
{
	NSLog(@"x=%f y=%f\n", aPoint.x, aPoint.y);
    return [super hitTest:aPoint];
}*/
/*
- (void)dealloc
{
	//NSLog( @"DDD=%@", [self retainCount] );
	if ( _watermark != nil )
		[_watermark release];
	
	[super dealloc];
}
*/

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	//NSLog(@"Menu for event");
	return nil;
}

static NSRect RectPlusScale (NSRect aRect, float scale);

- (void) setWatermark:(PDOCEX_INFO)pDocInfo
			 authCode:(NSString*)authCode
{
	//if ( _watermark != nil ) [_watermark release];
	
	_watermark = [[Watermark alloc] init];
//	[_watermark retain];//remember to release in dealloc!
	
	[_watermark setWatermark:pDocInfo authCode:authCode];
}

/*- (void) setWatermark:(const unsigned char*)szWMText 
				 type:(int)nWMType 
		   forDocName:(const unsigned char*)szDocName 
				ID:(unsigned int)docID
			 authCode:(NSString*)authCode
{
	if ( _watermark != nil ) [_watermark release];
	
	_watermark = [[Watermark alloc] init];
	[_watermark retain];//remember to release in dealloc!
	
	[_watermark setWatermark:szWMText ofType:nWMType forDocument:szDocName DocID:docID authCode:authCode];
}*/
/*
- (void) setWatermark:(NSString*)sText type:(int)nType
{
	if ( _cell != nil ) [_cell release];
	
	_cell = [[NSCell alloc] initTextCell:sText];
	NSFont *font = [NSFont fontWithName:@"Times" size:32];
	[_cell setFont:font];
	_watermarkType = nType;
	[_cell setBordered:YES];
	
	_wm = [[NSMutableAttributedString alloc] initWithString:sText];
	NSDictionary *attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	[_wm setAttributes:attr range:NSMakeRange(0, [sText length])];
}
*/

/*
- (BOOL)acceptsFirstResponder
{
	return YES;
}
*/
- (void) setJavelinDocument: (JavelinDocument*)pDoc
{
	_javelinDocument = pDoc;
	
	if ( pDoc != nil && pDoc.docInfo != nil )
	{
		NSMenuItem *removeAuth = [[NSMenuItem alloc] initWithTitle: @"Remove Authorization" action:@selector(removeAuthorisation:) keyEquivalent:@""];
		[m_normalMenu addItem:removeAuth];
	}
}

- (JavelinDocument*) javelinDocument
{
	return _javelinDocument;
}

void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color)
{
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

//void drawNote(CGContextRef context, CGRect rect, CGColorRef color, NSString* sText)
-(void) drawNote: (CGContextRef) context inRect:(CGRect) rect withColor:(CGColorRef) color text:(NSString*) sText withOffset:(CGPoint) ptOffset
{
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    
    //NSLog(@"DrawAnnot: %@ -> %@", NSStringFromRect(rect), sText);
    
    rect.size.width = ceil(rect.size.width);
    rect.size.height = ceil(rect.size.height);
    
    CGContextSetFillColorWithColor(context, color);
    CGContextSetStrokeColorWithColor(context, CGColorCreateGenericRGB(.6, .6, .2, .5) );
    CGContextFillRect(context, rect);
    CGContextStrokeRect(context, rect);
    CGContextRestoreGState(context);
    
    [sText drawInRect:rect withAttributes:m_annotAttributes];
}

-(CGPoint)getOffset:(PDFPage*)pdfPage
{
	struct CGPDFPage* pp = pdfPage.pageRef;
	CGRect rrCrop = CGPDFPageGetBoxRect(pp, kCGPDFCropBox);
    CGRect rrMedia = CGPDFPageGetBoxRect(pp, kCGPDFMediaBox);

	CGPoint ptOffset;
	ptOffset.x = rrCrop.origin.x;
	ptOffset.y = rrMedia.size.height - rrCrop.size.height - rrCrop.origin.y;

	//NSLog(@"Off X:%f Y:%f", ptOffset.x, ptOffset.y );
	return ptOffset;
}

/*2013-11-29*/
- (void) drawPage: (PDFPage *) pdfPage
{
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
    
    struct CGPDFPage* pp = pdfPage.pageRef;
    int nPage = (int)CGPDFPageGetPageNumber(pp);
	CGRect rrCrop = CGPDFPageGetBoxRect(pp, kCGPDFCropBox);
	
	CGPoint ptOffset = [self getOffset:pdfPage];
	
	if ( _watermark != nil && [_watermark isScreen])
	{
		NSRect myRect = [pdfPage boundsForBox:[self displayBox]]; 
		[_watermark drawAt:NSMakePoint(5, 5) rect:myRect]; //TOP
	}
    
    //if ( m_annotations != nil )
    {
        //NSNumber* key = [NSNumber numberWithInteger:nPage];
        //NSMutableArray* ans = (NSMutableArray*)[[_javelinDocument annotations] objectForKey:key];
        NSArray* ans = [[_javelinDocument annotations] highlightsForPage:nPage];
        if ( ans != nil )
        {
//            NSString* s = nil;
            CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
            //NSLog(@"Annotations %lu", (unsigned long)[ans count]);
            for( int i=0; i<[ans count]; i++)
            {
                JAnnotation* an = [ans objectAtIndex:i];
                //s = [an type];
                //if ( [s isEqualToString:@"Highlight"] )
                {
                    NSRect rect = [self convertRect:[an boundary] toView:self];
					
                    //NSLog(@"%d annotation: %@", i, NSStringFromRect(rect));
                    if ( an.type == ANNOTATION_HIGHLIGHT )
                    {
						rect.origin.x -= rrCrop.origin.x;
						rect.origin.y -= rrCrop.origin.y;

						CGContextSetRGBFillColor(myContext, 1.0, 0.0, 0.0, 0.2);
                        CGContextSetRGBStrokeColor(myContext, 1.0, 0.0, 0.0, 0.2);
                        CGContextFillRect(myContext, rect);
                    }
                    else if ( an.type == ANNOTATION_UNDERLINE )
                    {
						rect.origin.x -= rrCrop.origin.x;
						rect.origin.y -= rrCrop.origin.y;

                        draw1PxStroke(myContext, CGPointMake(rect.origin.x, rect.origin.y), CGPointMake(rect.origin.x+rect.size.width, rect.origin.y), CGColorCreateGenericRGB(0, 0, 0, 1));
                    }
                    else if ( an.type == ANNOTATION_NOTE )
                    {
                        /*CGSize size = [[an text] sizeWithAttributes:m_annotAttributes];
						size.width += 5;
						size.height += 5;
                        
                        if ( size.width > 400 )
                        {
                            size.width = 400;
                            size.height *= 2;
                        }*/
                        
                        CGRect rect1 = [[an text] boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX)
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:m_annotAttributes
                                                                  context:nil];
                        rect1.origin.x = rect.origin.x;
                        rect1.origin.y = rect.origin.y;
                        
						//CGRect rect1 = {rect.origin.x, rect.origin.y, (size.width>0)?size.width:NOTE_WIDTH, (size.height>0)?size.height:NOTE_HEIGHT };

                        NSRect rect2 = [self convertRect:rect1 fromView:self];
                        [an setBoundary:rect2];

                        [self drawNote:myContext inRect:rect1 withColor:CGColorCreateGenericRGB(1.0, 1.0, 0, .8) text:[an text] withOffset:ptOffset];//rrCrop.origin];
                    }
                    else
                    {
                        //strike out
						rect.origin.x -= rrCrop.origin.x;
						rect.origin.y -= rrCrop.origin.y;

                        CGFloat y = rect.origin.y + rect.size.height/2;
                        draw1PxStroke(myContext, CGPointMake(rect.origin.x, y), CGPointMake(rect.origin.x+rect.size.width, y), CGColorCreateGenericRGB(0, 0, 0, 1));
                    }
                    
                    //[an setColor:[NSColor colorWithWhite:0 alpha:0]];
                }
            }

        }
    }

}

- (void)printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate
{
	[super printWithInfo:printInfo autoRotate:doRotate];
	
	if ( _watermark != nil && [_watermark isPrint])
	{
		//id ooo = printInfo.imageRepresentation;
//		PDFPage* page = printInfo._activePage;
//		NSRect myRect = [page boundsForBox:[self displayBox]];
		NSRect myRect = NSMakeRect(0, 0, 300, 400);
		//[_watermark printAt:NSMakePoint(5, 5) rect:myRect]; //TOP
		
		// Create text attributes
		NSDictionary *textAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:18.0]};

		// Create string drawing context
		NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
		drawingContext.minimumScaleFactor = 0.5; // Half the font size

		CGRect drawRect = CGRectMake(0.0, 0.0, 300.0, 400.0);
		NSString* s = @"KAKAKAKKA";
		[s drawWithRect:drawRect
             options:NSStringDrawingUsesLineFragmentOrigin
          attributes:textAttributes
             context:drawingContext];
		//[_watermark drawFixedAt:NSMakePoint(10, 10) rect:myRect]; //BOTTOM
	}
	
	
}

- (void)printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate pageScaling:(PDFPrintScalingMode)scale
{
	[super printWithInfo:printInfo autoRotate:doRotate pageScaling:scale];
	
	
}
/*
- (void)drawPage:(PDFPage *)page toContext:(CGContextRef)context
{
	[super drawPage:page toContext:context];
	
	//NSRect windowFrame = [[self window] frame];
	//NSRect cv =[[[self window] contentView] frame];
	

}
*/

- (void)drawPagePost:(PDFPage *)page
{
	[super drawPagePost:page];
}

/*
- (void)drawRect:(NSRect)rect
{
	NSRect windowFrame = [[self window] frame];
	NSRect cv =[[[self window] contentView] frame];
	
	NSString* s = @"Test line";
	
	[s drawAtPoint:NSMakePoint(10, 10) withAttributes:nil];
}
*/
// ---------------------------------------------------------------------------------------------- transformContextForPage

- (void) transformContextForPage: (PDFPage *) page
{
	NSAffineTransform	*transform;
	NSRect				boxRect;
	
	boxRect = [page boundsForBox: [self displayBox]];
	
	transform = [NSAffineTransform transform];
	[transform translateXBy: -boxRect.origin.x yBy: -boxRect.origin.y];
	[transform concat];
}

#pragma mark -------- event overrides
// ------------------------------------------------------------------------------------------- setCursorForAreaOfInterest

- (void) setCursorForAreaOfInterest: (PDFAreaOfInterest) area
{
	NSPoint		viewMouse;
	BOOL		overDocument;
	
	// Get mouse in document view coordinates.
	viewMouse = [[self documentView] convertPoint: [[NSApp currentEvent] locationInWindow] fromView: NULL];
	overDocument = [[self documentView] mouse: viewMouse inRect: [[self documentView] visibleRect]];
	if (overDocument == NO)
	{
		[[NSCursor arrowCursor] set];
		return;
	}
	
	[super setCursorForAreaOfInterest: area];
}

- (void) annotationChanged: (id) sender
{
	//NSLog(@"Annotation changed: %@", [_activeAnnotation contents]);
	[self setNeedsDisplay:YES];
	[[self currentPage] setDisplaysAnnotations:YES];
}

-(void)editNote:(JAnnotation*)annot
{
    [self goToPage: [[self document] pageAtIndex: [annot pageNumber]-1]];
    if ( annot.type == ANNOTATION_NOTE )
    {
        m_annotationType = ANNOTATION_NOTE;
        [delegate editFreeNote:annot inWindow:[self window] viewRect:[self convertRect:[annot boundary] fromPage:[self currentPage]] pdfView:self];
    }
}
//-(void)selectAnnotation:(PDFAnnotation*)annot clickNo:(int)nClicks
-(void)selectAnnotation:(JAnnotation*)annot clickNo:(int)nClicks
{
	_activeAnnotation = annot;
	m_annotationType = ANNOTATION_ERROR;
	
	if ( annot != nil && nClicks == 2 )
	{
		if ( delegate != nil )
		{
            m_annotationType = ANNOTATION_NOTE;
            //[delegate editNote:annot inWindow:[self window]];
            [delegate editFreeNote:annot inWindow:[self window] viewRect:[self convertRect:[annot boundary] fromPage:[self currentPage]] pdfView:self];
		}
		
	}
	else
	{
		m_annotationType = ANNOTATION_NOTE;
	}
}

- (void)annotPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    [NSApp endSheet:sheet];
}

// ------------------------------------------------------------------------------------------------------------ mouseDown

-(int)getPageNumber:(PDFPage*)page
{
    int nPage = (int)CGPDFPageGetPageNumber([page pageRef]);
    return nPage;
}
- (void) mouseMoved: (NSEvent *) theEvent
{
    NSPoint mouseDownLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
    PDFPage* activePage = [self pageForPoint: mouseDownLoc nearest: YES];//[self currentPage]
    NSPoint pagePoint = [self convertPoint: mouseDownLoc toPage: activePage];
    int nPage = [self getPageNumber:activePage];
    //NSLog(@"Mouse down");
    JAnnotation* ann = [[_javelinDocument annotations] getAnnotationAtPoint:pagePoint onPage:nPage];
    
    if ( ann != nil )
    {
        [[NSCursor openHandCursor] set];
        return;
    }
    
    [super mouseMoved:theEvent];
}
- (void) mouseDown: (NSEvent *) theEvent
{
    //[super mouseDown: theEvent];
	PDFPage			*activePage;
	JAnnotation	*newActiveAnnotation = NULL;
	NSArray			*annotations;
	int				numAnnotations, i;
	NSPoint			pagePoint;
	
	if ( self.inFullScreenMode )
	{
		[self goToPreviousPage:self];
		[super mouseDown: theEvent];
		return;
	}
	_mouseDownInAnnotation = NO;
	
	//delete note window (if opened)
	if ( delegate != nil )
		[delegate closeNoteWindow];
	// Mouse in display view coordinates.
	_mouseDownLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
	
	// Page we're on.
	activePage = [self pageForPoint: _mouseDownLoc nearest: YES];
	
	// Get mouse in "page space".
	pagePoint = [self convertPoint: _mouseDownLoc toPage: activePage];
    int nPage = [self getPageNumber:activePage];
    //NSLog(@"Mouse down");
    JAnnotation* ann = [[_javelinDocument annotations] getAnnotationAtPoint:pagePoint onPage:nPage];
	// Hit test for annotation.
    if ( ann != nil )
    {
        _mouseDownInAnnotation = YES;
        _myActiveAnnotation = ann;
        newActiveAnnotation = ann;
        _clickDelta.x = pagePoint.x - ann.boundary.origin.x;
        _clickDelta.y = pagePoint.y - ann.boundary.origin.y;
        m_annotationType = ann.type;
        //NSLog(@"Mouse down in ANNOT");
        
        NSCursor.closedHandCursor.set;
    }
    else
    {
		//check with offset
		CGPoint ptOffset = [self getOffset:[self currentPage]];
		if ( ptOffset.x != 0 || ptOffset.y != 0 )
		{
			pagePoint.x -= ptOffset.x;
			pagePoint.y -= (ptOffset.y + NOTE_HEIGHT/2);
			ann = [[_javelinDocument annotations] getAnnotationAtPoint:pagePoint onPage:nPage];
			if ( ann != nil )
			{
				_mouseDownInAnnotation = YES;
				_myActiveAnnotation = ann;
				newActiveAnnotation = ann;
				_clickDelta.x = pagePoint.x - ann.boundary.origin.x;
				_clickDelta.y = pagePoint.y - ann.boundary.origin.y;
			}
		}
		
        [super mouseDown:theEvent];
        return;
    }
	/*
	// Hit-test for resize box.
	//NSLog(@"Pt: %@", NSStringFromPoint(pagePoint));
	NSRect rectAnnot = [newActiveAnnotation bounds];
	_wasBounds = rectAnnot;
	//NSLog(@"An: %@", NSStringFromRect(rectAnnot));
	NSRect rect1 = [self resizeThumbForRect:rectAnnot rotation: (int)[[newActiveAnnotation page] rotation]];
	_resizing = NSPointInRect(pagePoint, rect1 );
	//NSLog(@"Rc: %@ [%d]", NSStringFromRect(rect1), _resizing);
	*/
	
	_resizing = NO;
	
	// Select annotation.
	//[self selectAnnotation:newActiveAnnotation clickNo:(int)[theEvent clickCount]];
}

// --------------------------------------------------------------------------------------------------------- mouseDragged

- (void) mouseDragged: (NSEvent *) theEvent
{
	// Defer to super for locked PDF.
//	if ([[self document] isLocked])
//	{
//		[super mouseDown: theEvent];
//		return;
//	}
	_dragging = YES;
	
	// Handle link-edit mode.
	if (_mouseDownInAnnotation && (m_annotationType == ANNOTATION_FREE_NOTE || m_annotationType == ANNOTATION_NOTE) )
	{
		NSRect		newBounds;
		NSRect		currentBounds;
		NSRect		dirtyRect;
		NSPoint		mouseLoc;
		NSPoint		endPt;
		
		// Where is annotation now?
		currentBounds = [_activeAnnotation boundary];
		
		// Mouse in display view coordinates.
		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
		
		// Convert end point to page space.
        endPt = [self convertPoint: mouseLoc toPage:[self currentPage]]; //[_activeAnnotation page]];
		
		if (_resizing)
		{
			NSPoint		startPoint;
			
			// Convert start point to page space.
            startPoint = [self convertPoint: _mouseDownLoc toPage:[self currentPage]];// [_activeAnnotation page]];
			
			// Resize the annotation.
			switch ([[self currentPage] rotation])//[[_activeAnnotation page] rotation])
			{
				case 0:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
				
				case 90:
				newBounds.origin.x = _wasBounds.origin.x;
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width + (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 180:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y;
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height + (endPt.y - startPoint.y);
				break;
				
				case 270:
				newBounds.origin.x = _wasBounds.origin.x + (endPt.x - startPoint.x);
				newBounds.origin.y = _wasBounds.origin.y + (endPt.y - startPoint.y);
				newBounds.size.width = _wasBounds.size.width - (endPt.x - startPoint.x);
				newBounds.size.height = _wasBounds.size.height - (endPt.y - startPoint.y);
				break;
			}
			
			// Keep integer.
			newBounds = NSIntegralRect(newBounds);
		}
		else
		{
			// Move annotation.
			// Hit test, is mouse still within page bounds?
			if (NSPointInRect([self convertPoint: mouseLoc toPage: [self currentPage]],//[_activeAnnotation page]],
                        [[self currentPage] boundsForBox:[self displayBox]]))
					//[[_activeAnnotation page] boundsForBox: [self displayBox]]))
			{
				// Calculate new bounds for annotation.
				newBounds = currentBounds;
				float fX = roundf(endPt.x - _clickDelta.x);
				float fY = roundf(endPt.y - _clickDelta.y);
				
				if ( fX < 0 )
					fX = 0;
				if ( fY < 0 )
					fY = 0;

				newBounds.origin.x = fX;
				newBounds.origin.y = fY;
                [[self window] setDocumentEdited: YES];
                //NSLog(@"in %@", NSStringFromRect(newBounds));
			}
			else
			{
				// Snap back to initial location.
				newBounds = currentBounds;
				//NSLog(@"out %@", NSStringFromRect(newBounds));
			}
		}
		
		// Change annotation's location.
		/*if ( [[_activeAnnotation type] isEqualToString:@"Text"] )
		{

		}
		else if ( [[_activeAnnotation type] isEqualToString:@"FreeText"] )
		{
			NSString* s = [_activeAnnotation contents];
			NSColor* col = [_activeAnnotation color];
			
			PDFPage* page = [_activeAnnotation page];
			[page removeAnnotation:_activeAnnotation];
			
			PDFAnnotationFreeText* aa = [[PDFAnnotationFreeText alloc] initWithBounds:newBounds];
			[aa setColor:col];
			[aa setContents:s];
		
			[page addAnnotation:aa];
		}
		else*/
		{
			CGPoint ptOffset = [self getOffset:[self currentPage]];
			if ( ptOffset.x != 0 || ptOffset.y != 0 )
			{
				float fX = newBounds.origin.x - ptOffset.x;
				float fY = newBounds.origin.y - ptOffset.y;
				
				if ( fX > 0 && fY > 0 )
				{
					newBounds.origin.x -= ptOffset.x;
					newBounds.origin.y -= ptOffset.y;
				}
			}
            NSRect rPage = [[self currentPage] boundsForBox:[self displayBox]];//[[_activeAnnotation page] boundsForBox: [self displayBox]];
			
			if ( newBounds.origin.x > rPage.size.width )
				newBounds.origin.x = rPage.size.width;
			
			if ( newBounds.origin.y > rPage.size.height )
				newBounds.origin.y = rPage.size.height;
			
			//if ( CGRectIntersectsRect(rPage, newBounds) )
			//NSLog(@"page %@", NSStringFromRect(rPage));
			//NSLog(@"ann  %@", NSStringFromRect(newBounds));
			
			[_myActiveAnnotation setBoundary: newBounds];
		}
		
		// Call our method to handle updating annotation geometry.
		[self annotationChanged1];
		
		// Force redraw.
		dirtyRect = NSUnionRect(currentBounds, newBounds);
		[self setNeedsDisplayInRect: 
				RectPlusScale([self convertRect: dirtyRect fromPage: [self currentPage]], [self scaleFactor])];
	}
	else
	{
		[super mouseDragged: theEvent];
	}
}

// -------------------------------------------------------------------------------------------------------------- mouseUp

- (void) mouseUp: (NSEvent *) theEvent
{
    if ( _dragging == YES )
        NSCursor.openHandCursor.set;
    
	_dragging = NO;
	[super mouseUp: theEvent];	// Handle link-edit mode.
    int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
    
    if ( theEvent.clickCount == 2 )
    {
		NSPoint ptMouse = _mouseDownLoc;
		
        NSPoint point = [self convertPoint: _mouseDownLoc toPage:[self currentPage]];
		CGPoint ptOffset = [self getOffset:[self currentPage]];
		//point.x -= ptOffset.x;
		//point.y -= ptOffset.y;
		
		JAnnotation* ann = [[_javelinDocument annotations] getAnnotationAtPoint:point onPage:nPage];
		[ann setNewNote:NO];
		if ( ann.type == ANNOTATION_NOTE )
		{
			m_selectedAnnotation = ann;
			[self editNote:ann];
			return;
		}
		else
		{
			//try with the offset
			if ( ptOffset.x != 0 || ptOffset.y != 0 )
			{
				point.x -= ptOffset.x;
				point.y -= (ptOffset.y + NOTE_HEIGHT/2);
				ann = [[_javelinDocument annotations] getAnnotationAtPoint:point onPage:nPage];
				[ann setNewNote:NO];
				if ( ann.type == ANNOTATION_NOTE )
				{
					//m_selectedAnnotation = ann;
					[self editNote:ann];
					return;
				}
			}
		}
		return;
    }
	if ( _mouseDownLoc.x != 0 || _mouseDownLoc.y != 0 )
	{
		PDFSelection* sel = [self currentSelection];
		
		NSPoint ptUp = [self convertPoint: [theEvent locationInWindow] fromView: NULL];
		float fDistX = fabsf( ptUp.x - _mouseDownLoc.x);
		float fDistY = fabsf( ptUp.y - _mouseDownLoc.y);
		
		//NSLog(@"MouseUP %@ -> %@", NSStringFromPoint(_mouseDownLoc), NSStringFromPoint(ptUp));
		
		if ( sel != nil && (fDistX > 4 || fDistY > 4) )
		{
			[m_selectionMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
		}
		
		_mouseDownLoc = NSMakePoint(0, 0);
	}
	
/*	if (_mouseDownInAnnotation)
	{
		_mouseDownInAnnotation = NO;
	}
	else
	{
		[super mouseUp: theEvent];
	}*/
}
/*
- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	PDFPage  *mouseDownPage = [self pageForPoint:loc nearest:NO];
	NSPoint loc1 = [self convertPoint: loc toPage:mouseDownPage];
	m_selectedAnnotation = nil;
	m_selectedAnnotations = nil;

	if ( self.inFullScreenMode )
	{
		[self goToNextPage:self];
		[super rightMouseDown: theEvent];
		return;
	}

	//check if there is a selection
	PDFSelection* sel = [self currentSelection];
	if ( sel != nil )
	{
		//YES - we've got a test selection
		NSRect rect = [sel boundsForPage:[self currentPage] ];
		CGRect rectSel = NSRectToCGRect(rect);
		rectSel = CGRectInset(rectSel, -2, -2);
		
		//NSLog(@"Sel: %@", NSStringFromRect(rect));
		//NSLog(@"Pnt: %@", NSStringFromPoint(loc1));
		
		if ( NSPointInRect(loc1, rect) )
		{
			m_selectedAnnotations = [[NSMutableArray alloc] init];
			
			NSArray* ans = [[self currentPage] annotations];
			if ( ans != nil )
			{
				for( int i=0; i<ans.count; i++ )
				{
					PDFAnnotation* an = [ans objectAtIndex:i];
					CGRect rectAnn = NSRectToCGRect([an bounds]);
					
					if ( CGRectContainsRect(rectSel, rectAnn) )
					{
						//NSLog(@"SELECTED ANN: %@ %d", an, i);
						[m_selectedAnnotations addObject:[NSNumber numberWithInt:i]];
					}
					else
					{
						//NSLog(@"NOT-SELECTED: %@ %d", an, i);
					}
				}
			}
			
			if ( m_selectedAnnotations.count == 0 )
			{
				//no annotations in selection
				m_selectedAnnotations = nil;
				//ask user to add one is click is inside the selection
				if ( NSPointInRect(loc1, rect) )
				{
					[m_selectionMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
				}
				else
				{
					//no - click is outside selection
					m_ptAnnotation = loc1;
					[m_normalMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
				}

			}
			else
			{
				[m_deleteMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
			}
		}
		
		return;
	}

	//NO selection - try to see if we hit a single annotation
	//any annotation at this point
	PDFAnnotation* ann = [[self currentPage] annotationAtPoint:loc1];
	if ( ann )
	{
		//annotation right-clicked
		//offer to delete
		m_selectedAnnotation = ann;
		//NSLog(@"ANN1: %@", m_selectedAnnotation);
		//NSLog(@"CNT1: %lu",(unsigned long)[[[self currentPage] annotations] count]);

		[m_deleteMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
	}
	else
	{
		PDFSelection* sel = [self currentSelection];
		if ( sel != nil )
		{
			NSRect rect = [sel boundsForPage:[self currentPage] ];

			if ( NSPointInRect(loc1, rect) )
			{
				[m_selectionMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
				return;
			}
		}
		m_ptAnnotation = loc1;
		[[self window] makeFirstResponder:self];
		[m_normalMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
	}
}*/

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:self];
	
    PDFPage  *mouseDownPage = [self pageForPoint:loc nearest:NO];
	NSPoint loc1 = [self convertPoint: loc toPage:mouseDownPage];
    int nPage = (int)CGPDFPageGetPageNumber([[self currentPage] pageRef]);
    
    m_selectedAnnotation = nil;
    m_selectedAnnotations = nil;
    
	//NSLog(@"loc1:%f:%f", loc1.x, loc1.y);
	
    if ( self.inFullScreenMode )
    {
        [self goToNextPage:self];
        [super rightMouseDown: theEvent];
        return;
    }

    //check for PDF native annotation
    PDFAnnotation* annNative = [[self currentPage] annotationAtPoint:loc1];
    if ( annNative != nil )
    {
        //annotation right-clicked
        //offer to delete
        m_selectedAnnotationNative = annNative;
        [m_deleteMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
    }
    
    //check if there is a selection
    PDFSelection* sel = [self currentSelection];
    if ( sel != nil )
    {
        //YES - we've got a test selection
        NSRect rect = [sel boundsForPage:[self currentPage] ];
        CGRect rectSel = NSRectToCGRect(rect);
        rectSel = CGRectInset(rectSel, -2, -2);
        
        //NSLog(@"Sel: %@", NSStringFromRect(rect));
        //NSLog(@"Pnt: %@", NSStringFromPoint(loc1));
        
        if ( NSPointInRect(loc1, rect) )
        {
            m_selectedAnnotations = [[NSMutableArray alloc] init];
            
            NSArray* ans = [[_javelinDocument annotations] highlightsForPage:nPage];
            if ( ans != nil )
            {
                for( int i=0; i<ans.count; i++ )
                {
                    JAnnotation* an = [ans objectAtIndex:i];
                    CGRect rectAnn = NSRectToCGRect([an boundary]);
                    
                    if ( CGRectContainsRect(rectSel, rectAnn) )
                    {
                        //NSLog(@"SELECTED ANN: %@ %d", an, i);
                        [m_selectedAnnotations addObject:an];
                    }
                    else
                    {
                        //NSLog(@"NOT-SELECTED: %@ %d", an, i);
                    }
                }
            }
            
            if ( m_selectedAnnotations.count == 0 )
            {
                //no annotations in selection
                m_selectedAnnotations = nil;
                //ask user to add one is click is inside the selection
                if ( NSPointInRect(loc1, rect) )
                {
                    [m_selectionMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
                }
                else
                {
                    //no - click is outside selection
                    m_ptAnnotation = loc1;
                    [m_normalMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
                }
                
            }
            else
            {
                [m_deleteMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
            }
        }
        
        return;
    }

    //NO selection - try to see if we hit a single annotation
    //any annotation at this point
/*	if ( nRotation == 90 )
	{
		//page.
		rect.origin.x = rectOrig.origin.y;
		rect.origin.y = pageSize.size.width - rectOrig.origin.x - rectOrig.size.width;
		rect.size.width = rectOrig.size.height;
		rect.size.height = rectOrig.size.width;
	}*/
	long lRotation = [mouseDownPage rotation];
	if ( lRotation == 90 )
	{
		//page is rotated - convert coordinates
		NSRect pageSize = [mouseDownPage boundsForBox:kPDFDisplayBoxMediaBox];
		float fOldX = loc1.x;
/*		NSArray* ans = [[_javelinDocument annotations] highlightsForPage:nPage];
		for( int i=0; i<[ans count]; i++)
		{
			JAnnotation* an = [ans objectAtIndex:i];
			CGRect rectAnn = NSRectToCGRect([an boundary]);
			NSLog(@"%d -> %@", i, NSStringFromRect(rectAnn));
		}*/
		loc1.x = loc1.y;
		loc1.y = pageSize.size.width - fOldX;
		//NSLog(@"loc2:%f:%f", loc1.x, loc1.y);
	}

	/*CGPoint ptOffset = [self getOffset:[self currentPage]];
	if ( ptOffset.x != 0 || ptOffset.y != 0 )
	{
		loc1.x -= ptOffset.x;
		loc1.y -= ptOffset.y;
	}*/
	
	/*CGPoint ptOffset = [self getOffset:[self currentPage]];
	loc1.x += ptOffset.x;
	loc1.y += ptOffset.y;*/
	
    JAnnotation* ann = [[_javelinDocument annotations] getAnnotationAtPoint:loc1 onPage:nPage];
    if ( ann != nil )
    {
        m_selectedAnnotation = ann;
		if ( ann.type == ANNOTATION_NOTE )
		{
            //NSLog(@"rightmouse");
            [[self window] makeFirstResponder:self];
			[m_deleteAndEditMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
		}
		else
		{
        	[m_deleteMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
		}
    }
    else
    {
        PDFSelection* sel = [self currentSelection];
        if ( sel != nil )
        {
            NSRect rect = [sel boundsForPage:[self currentPage] ];
            
            if ( NSPointInRect(loc1, rect) )
            {
                [m_selectionMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
                return;
            }
        }
		
		//before assuming there is nothing under the mouse-click, try to use page offset
		CGPoint ptOffset = [self getOffset:[self currentPage]];
		loc1.x -= ptOffset.x;
		loc1.y -= (ptOffset.y + NOTE_HEIGHT/2);
		ann = [[_javelinDocument annotations] getAnnotationAtPoint:loc1 onPage:nPage];
		if ( ann != nil && ann.type == ANNOTATION_NOTE )
		{
			m_selectedAnnotation = ann;
            //NSLog(@"mkonji");
			[m_deleteAndEditMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
		}
		else
		{
            //NSLog(@"aaaaa");
			m_ptAnnotation = loc1;
			[[self window] makeFirstResponder:self];
			[m_normalMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
		}
    }
}

- (void) annotationChanged1
{
	NSRect		bounds;
	
	// NOP.
	if (_activeAnnotation == NULL)
		return;
	
	[[self window] setDocumentEdited: YES];
	
	// Get bounds.
	bounds = [_myActiveAnnotation boundary];
	
	// Handle line start and end points.
/*	if ([_activeAnnotation isKindOfClass: [PDFAnnotationLine class]])
	{
		PDFBorder	*border = [_activeAnnotation border];
		float		inset = 1.0;
		
		if (border)
			inset = ceilf([border lineWidth] * 2.2);
		[(PDFAnnotationLine *)_activeAnnotation setStartPoint: NSMakePoint(inset, inset)];
		[(PDFAnnotationLine *)_activeAnnotation setEndPoint: NSMakePoint(bounds.size.width - inset, bounds.size.height - inset)];
	}
	else if ([_activeAnnotation isKindOfClass: [PDFAnnotationMarkup class]])
	{
		[(PDFAnnotationMarkup *)_activeAnnotation setQuadrilateralPoints: [NSArray arrayWithObjects: 
				[NSValue valueWithPoint: NSMakePoint(0.0, bounds.size.height)], 
				[NSValue valueWithPoint: NSMakePoint(bounds.size.width, bounds.size.height)], 
				[NSValue valueWithPoint: NSMakePoint(0.0, 0.0)], 
				[NSValue valueWithPoint: NSMakePoint(bounds.size.width, 0.0)], 
				NULL]];
	}*/
}


// -------------------------------------------------------------------------------------------------------------- keyDown

- (void) keyDown: (NSEvent *) theEvent
{
/*	JavelinDocument* jd = [self javelinDocument];
	if ( jd != nil && [jd docInfo] != NULL )
	{
		//We have a protected document
		//check screen-shot keys
		NSLog(@"flg:%d %@",
			  (unsigned int)theEvent.modifierFlags,
			  theEvent.characters);
	}*/
	
	if ( [self displayMode] == kPDFDisplayTwoUp || [self displayMode] == kPDFDisplayTwoUpContinuous )
	{
		UINT nCode = [theEvent keyCode];
		
		if ( ( 0x7E == nCode ) )//Up Arrow
		{
			[self goToPreviousPage:nil];
			return;
		}
		else if ( (0x7D) ) //down arrow
		{
			[self goToNextPage:nil];
			return;
		}
	}

	unichar			oneChar;
//	unsigned int	theModifiers;
//	BOOL			noModifier;
	
	// Get the character from the keyDown event.
	oneChar = [[theEvent charactersIgnoringModifiers] characterAtIndex: 0];
//	theModifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
//	noModifier = ((theModifiers & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)) == 0);
	
	// Delete?
	if ((oneChar == NSDeleteCharacter) || (oneChar == NSDeleteFunctionKey))
		[self delete: self];
	else
		[super keyDown: theEvent];
}

- (void) keyUp:(NSEvent *)theEvent
{
	[super keyUp:theEvent];
}

// --------------------------------------------------------------------------------------------------------------- delete

- (void) delete: (id) sender
{
	if (_activeAnnotation != NULL)
	{
		PDFAnnotationLink	*wasAnnotation;
		
		wasAnnotation = _activeAnnotation;
		[self setActiveAnnotation: NULL];
		[[wasAnnotation page] removeAnnotation: wasAnnotation];
		
		// Set edited flag.
		[[self window] setDocumentEdited: YES];
	}
}

#pragma mark -------- menu actions
// -------------------------------------------------------------------------------------------------------- printDocument

- (int) printJvlnDocument: (id) sender
{
//	[[Log getLog] addLine:@"JavelinPdfView::printJvlnDocument"];
	JavelinDocument* jd = [self javelinDocument];
	
	if ( m_defaultPrintDict == nil )
	{
		//save original print info for later restoration
		m_defaultPrintDict = [[NSPrintInfo sharedPrintInfo] dictionary];
	}
/*	else
	{
		//restore original print info
		NSPrintInfo* pi = [[NSPrintInfo alloc] initWithDictionary:m_defaultPrintDict];
		[NSPrintInfo setSharedPrintInfo:pi];
	}*/
	
	if ( jd != nil && [jd docInfo] != NULL )
	{
		//PDOCEX_INFO pd = [jd docInfo];
		
		if ( [jd docInfo]->dwPagesToPrint != 0xffffffff || [jd docInfo]->dwPrintingCount != 0xffffffff || _watermark != nil)
		{
			DocumentRecord *dr = [DocumentDB getDocument:[jd docInfo]->dwDocID];
			if ( dr == nil )
			{
				//document should have counters in DocumentDB!
				[General displayAlert:@"Unable to print document!" 
						   message:@"Problem with counters in internal database."];
				
				return [jd docInfo]->dwDocID;//return documentID in case of error
			}
			
			int nPrintCountSaved = [dr printCount];
			int nPrintPages = [dr pagesCount];
			BOOL bOK = YES;
			
			if ( nPrintCountSaved != 0xffffffff )
			{
				if ( nPrintCountSaved -- <= 0 )
				{
					bOK = NO;
				}
			}

			if ( nPrintPages != 0xffffffff )
			{
				if ( nPrintPages -- <= 0 )
				{
					bOK = NO;
				}
			}
			
			if ( bOK == NO )
			{
				NSAlert *theAlert = [NSAlert alertWithMessageText:@"Unable to print document because printing has been disabled or printing counters have expired!"
													defaultButton:@"OK" 
												  alternateButton:@"Cancel"
													  otherButton:nil
										informativeTextWithFormat:@"Do you want to re-authorise document? If yes, you'll have to re-open the document."];
				[theAlert setAlertStyle:NSWarningAlertStyle];
				NSInteger res = [theAlert runModal];
				if ( res  == NSAlertDefaultReturn )
				{
					return [jd docInfo]->dwDocID;//return documentID in case of error
				}
				else
				{
					return 0;//OK
				}
			}
			
			//We have a protected DRMX file.
			//Pay special attention to the security!!!
			[self printDrmx:dr];
			
			return 0;//OK
		}
	}

	//This is a plain PDF or DRMX without defined printing counters or watermark
	//let PDFView handle the printing for this document.
	NSPrintInfo* pi = [NSPrintInfo sharedPrintInfo];
	[super printWithInfo:pi  autoRotate: YES];
	
	return 0;
}

- (void) printDrmx: (DocumentRecord*)docRec
{
//	[[Log getLog] addLine:@"JavelinPdfView::printDrmx"];
	NSPrintInfo* pi = [NSPrintInfo sharedPrintInfo];//[[NSPrintInfo alloc] initWithDictionary:m_defaultPrintDict];//[NSPrintInfo sharedPrintInfo];
	//NSArray *pArgs = [[NSArray alloc] initWithObjects:pi, docRec, nil];
	//[NSArray arrayWithObjects:pi, docRec, nil];
	//[pArgs retain];
	
	DrumlinPrintPanel* pp = [[DrumlinPrintPanel alloc] init];
	[pp beginSheetWithPrintInfo:(NSPrintInfo *)pi 
				 modalForWindow:[self window] 
					   delegate:self 
				 didEndSelector:@selector(printPanelDidEnd: returnCode: contextInfo:) 
					contextInfo:nil];//pArgs];
}

//found on: http://www.danandcheryl.com/2010/05/how-to-print-a-pdf-file-using-cocoa
- (void)printPDF:(NSURL *)fileURL
{

    // Create the print settings.
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];//[[NSPrintInfo alloc] initWithDictionary:m_defaultPrintDict];//[NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin:0.0];
    [printInfo setBottomMargin:0.0];
    [printInfo setLeftMargin:0.0];
    [printInfo setRightMargin:0.0];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination:NSFitPagination];

    // Create the document reference.
    PDFDocument *pdfDocument = nil;
	
	if ( fileURL != nil )
		pdfDocument = [[PDFDocument alloc] initWithURL:fileURL];
	else
		pdfDocument = [[self document] copy];
	
    // Invoke private method.
    // NOTE: Use NSInvocation because one argument is a BOOL type. Alternately, you could declare the method in a category and just call it.
    BOOL autoRotate = YES;
    NSMethodSignature *signature = [PDFDocument instanceMethodSignatureForSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)];
    [invocation setArgument:&printInfo atIndex:2];
    [invocation setArgument:&autoRotate atIndex:3];
    [invocation invokeWithTarget:pdfDocument];

    // Grab the returned print operation.
    NSPrintOperation *op = nil;
    [invocation getReturnValue:&op];
	
    // Run the print operation without showing any dialogs.
    [op setShowsPrintPanel:NO];
    [op setShowsProgressPanel:NO];
    [op runOperation];
}

NSPrintOperation* op = nil;
- (void)printPDFFromData:(NSData*)data printInfo:(NSPrintInfo*)printInfo page:(PDFPage*)page
{

    // Create the print settings.
//    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin:0.0];
    [printInfo setBottomMargin:0.0];
    [printInfo setLeftMargin:0.0];
    [printInfo setRightMargin:0.0];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination:NSFitPagination];

    // Create the document reference.
    PDFDocument *pdfDocument = nil;
	
	pdfDocument = [[PDFDocument alloc] initWithData:data];

    // Invoke private method.
    // NOTE: Use NSInvocation because one argument is a BOOL type. Alternately, you could declare the method in a category and just call it.
    BOOL autoRotate = YES;
    NSMethodSignature *signature = [PDFDocument instanceMethodSignatureForSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)];
    [invocation setArgument:&printInfo atIndex:2];
    [invocation setArgument:&autoRotate atIndex:3];
    [invocation invokeWithTarget:pdfDocument];

    // Grab the returned print operation.
    //NSPrintOperation *op = nil;
    [invocation getReturnValue:&op];
	
    // Run the print operation without showing any dialogs.
    [op setShowsPrintPanel:NO];
    [op setShowsProgressPanel:NO];
    if ( YES == [op runOperation] )
	{
/*		//watermark?
		if ( _watermark != nil && [_watermark isPrint])
		{
			NSRect myRect = [page boundsForBox:[self displayBox]];
			[_watermark printAt:NSMakePoint(5, 5) rect:myRect];
		}*/
	}
}

#define kMimeType @"application/pdf"
#define kPaperType @"A4"

//http://stackoverflow.com/questions/4881635/printing-without-an-nsview
- (void)printData:(NSData *)incomingPrintData {
    CFArrayRef printerList; //will soon be an array of PMPrinter objects
    PMServerCreatePrinterList(kPMServerLocal, &printerList);
	
	NSPrintInfo* pi = [NSPrintInfo sharedPrintInfo];
	
	if ( pi == nil )
	{
		[[Log getLog] addLine:@"Unable to get print info"];
		[General displayAlert:@"Unable to print document!" message:@"Unable to get print info"];
		return;
	}
	[pi setTopMargin:0.0];
	[pi setLeftMargin:0.0];
	[pi setBottomMargin:0.0];
	[pi setRightMargin:0.0];
	[pi setHorizontalPagination:NSFitPagination];
    [pi setVerticalPagination:NSFitPagination];
	
	PMPrintSettings settings = [pi PMPrintSettings];
	PMPrintSession session = [pi PMPrintSession];
	PMPrinter currentPrinter = NULL;
    // Get the current printer from the session.
    PMSessionGetCurrentPrinter(session, &currentPrinter);

    //iterate over printerList and determine which one you want, assign to myPrinter
	//OSStatus status = PMServerLaunchPrinterBrowser ( kPMServerLocal, nil );
	//if (status == noErr)
	//	return;
	
	//currentPrinter = (PMPrinter)status;
	
    PMPrintSession printSession;
    PMPrintSettings printSettings;
    PMCreateSession(&printSession);
    PMCreatePrintSettings(&printSettings);
    PMSessionDefaultPrintSettings(printSession, printSettings);

    CFArrayRef paperList;
    PMPrinterGetPaperList(currentPrinter, &paperList);
	PMPaper theChosenPaper = (__bridge PMPaper)[(__bridge NSArray *)paperList objectAtIndex: 0];
    //iterate over paperList and to set usingPaper to the paper desired
    PMPageFormat pageFormat;
    PMCreatePageFormatWithPMPaper(&pageFormat, theChosenPaper);

    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)incomingPrintData);
    PMPrinterPrintWithProvider(currentPrinter, printSettings, pageFormat, (CFStringRef)kMimeType, dataProvider);
}

- (void) printPanelDidEnd: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
	[[Log getLog] addLine:@"JavelinPdfView::printPanelDidEnd"];

	if ( returnCode != NSOKButton )
	{
		[[Log getLog] addLine:@"JavelinPdfView::printPanelDidEnd => Cancelled"];
		return;
	}
	else
	{
		[self doPrint];
	}
}

- (void)doPrint
{
	[[Log getLog] addLine:@"Printing..."];
	NSPrintInfo* pi = [NSPrintInfo sharedPrintInfo];
	
	if ( pi == nil )
	{
		[[Log getLog] addLine:@"Unable to get print info"];
		[General displayAlert:@"Unable to print document!" message:@"Unable to get print info"];
		return;
	}
	
	PMPrintSettings settings = [pi PMPrintSettings];
	PMPrintSession session = [pi PMPrintSession];
	PMPrinter currentPrinter = NULL;
    // Get the current printer from the session.
    PMSessionGetCurrentPrinter(session, &currentPrinter);
	
	[[Log getLog] addLine:@"PrintInfo OK"];
	
	JavelinDocument* jd = [self javelinDocument];
	if ( jd == nil )
	{
		[[Log getLog] addLine:@"Document error"];
		[General displayAlert:@"Unable to print document!" message:@"Document error"];
		return;
	}
	
	long lPageCount = jd.pdfDocument.pageCount;
	[[Log getLog] addLine:@"JavelinDocument OK"];
	
	if ( [jd docInfo] == nil )
	{
		[[Log getLog] addLine:@"Unable to get document information"];
		[General displayAlert:@"Unable to print document!" message:@"Unable to get document information"];
		return;
	}
	
	[[Log getLog] addLine:@"Document info OK"];

	DocumentRecord* docRec = [DocumentDB getDocument:[jd docInfo]->dwDocID];
	if ( docRec == nil )
	{
		[[Log getLog] addLine:@"Unable to get document record"];
		[General displayAlert:@"Unable to print document!" message:@"Unable to get document record"];
		return;
	}
	
	[[Log getLog] addLine:@"Document record OK"];
	
//		NSPrinter *pr   = [pi printer];
//		NSDictionary *d = [pi printSettings];
	//[docRec retain];
	//[pi retain];

	//check if the destination is a normal (hardware) printer
	NSDictionary *d = [pi printSettings];
	NSPrinter *pr = nil;
	if ( d == nil )
	{
		[[Log getLog] addLine:@"Unable to retrieve printer settings."];
		[General displayAlert:@"Unable to print document!" message:@"Unable to retrieve printer settings"];
		return;
	}
	else
	{
		[[Log getLog] addLine:@"PrintSettings dictionary OK - getting NSPrinter"];
		
		pr   = [pi printer];

		if ( pr == nil )
		{
			[[Log getLog] addLine:@"Unable to retrieve NSPrinter from the system."];
			[General displayAlert:@"Unable to print document!" message:@"Unable to retrieve printer from the system"];
			return;
		}
		[[Log getLog] addLine:@"NSPrinter OK"];
					
		[[Log getLog] addLine:[NSString stringWithFormat:@"Printer name: %@", [pr name]]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"Printer type: %@", [pr type]]];
	}
	
	NSNumber *val = [d objectForKey:@"com_apple_print_PrintSettings_PMDestinationType"];
	[[Log getLog] addLine:[NSString stringWithFormat:@"Printing to device of type:%@", val]];

/* 2013-12-19 PDF PRINTING*/
#ifndef DEBUG_PRINTx
	if ( val == nil || [val intValue] != kPMDestinationPrinter )
	{
		//2015-10-30 alternate method to get printing destination (from Apple's docs)
		PMPrintSession printSession = [pi PMPrintSession];
		PMPrintSettings printSettings = [pi PMPrintSettings];
		PMDestinationType printDestination = 0;
		OSStatus status = noErr;

		// Verify that the destination is the printer.
		status = PMSessionGetDestinationType(printSession, printSettings, &printDestination);

		if ((status != noErr) || (printDestination != kPMDestinationPrinter)) {
			[[Log getLog] addLine:@"Either got an error from PMSessionGetDestinationType or the print destination wasn't kPMDestinationPrinter"];

			[General displayAlert:@"Unable to print document!"
				   message:@"You can't use this printing device for printing a DRMX or DRMZ document"];

			return;
		}
	}
#endif
	BOOL isOK = [self checkPrinterName:[[pi printer] name]];
	
	if ( isOK == NO )
	{
		//try with printer type
		isOK = [self checkPrinterName:[[pi printer] type]];
		
		if ( isOK == NO )
		{
			[[Log getLog] addLine:@"JavelinPdfView::printPanelDidEnd => Wrong device"];
			[[Log getLog] addLine:[[pi printer] name]];
			//[docRec release];
			//[pi release];
			[General displayAlert:@"Unable to print document!"
					message:[NSString stringWithFormat:@"Document can't be printed to: %@", [[pi printer] name]]];
			return;
		}
	}

	[[Log getLog] addLine:[NSString stringWithFormat:@"Printing to device of type:%@", val]];

	if ( [docRec printCount] == 0 || [docRec pagesCount] == 0 )
	{
		[[Log getLog] addLine:@"JavelinPdfView::printPanelDidEnd => Unable to print, counters expired"];
		//[docRec release];
		//[pi release];
		[General displayAlert:@"Unable to print document!" 
				   message:@"Document can't be printed anymore. Counters expired."];
		return;

	}
	
	NSMutableDictionary *d1 = [pi dictionary];
	
//	NSNumber *rightMargin = [d1 objectForKey:@"NSRightMargin"];
//	NSNumber *leftMargin  = [d1 objectForKey:@"NSLeftMargin"];
//	NSNumber *topMargin   = [d1 objectForKey:@"NSTopMargin"];
//	NSNumber *bottomMargin= [d1 objectForKey:@"NSBottomMargin"];
	NSNumber *firstPage   = [d1 objectForKey:@"NSFirstPage"];
	NSNumber *lastPage    = [d1 objectForKey:@"NSLastPage"];
	NSValue  *pageSize	  = [d1 objectForKey:@"NSPaperSize"];
	NSNumber* copies	  = [d1 objectForKey:NSPrintCopies];

	NSRect rect1 = pi.imageablePageBounds;
//	rightMargin = [NSNumber numberWithShort:0];
//	[d1 setObject:[NSNumber numberWithShort:0] forKey:@"NSRightMargin"];
//	[d1 setObject:[NSNumber numberWithShort:0] forKey:@"NSLeftMargin"];
//	[d1 setObject:[NSNumber numberWithShort:0] forKey:@"NSTopMargin"];
//	[d1 setObject:[NSNumber numberWithShort:0] forKey:@"NSBottomMargin"];
	
	NSRect          frame;
	int nFirstPage = [firstPage intValue];
	int nLastPage  = [lastPage intValue];

	NSNumber *n = [NSNumber numberWithInt:1];
	[d1 setObject:n forKey:@"NSFirstPage"];
	[d1 setObject:n forKey:@"NSLastPage"];
	
	NSUInteger pageMax = [[self document] pageCount];
	//int nPagesCount = 0;
	if ( nLastPage > (int)pageMax ) nLastPage = (int)pageMax;
	//if ( nLastPage > 3000 ) nLastPage = (int)pageMax;
	int nPagesToPrint = (nLastPage - nFirstPage + 1) * copies.longValue;
	int nPagesCount = 0;
	
	if ( nPagesToPrint > 100 )
	{
		NSAlert *theAlert = [NSAlert alertWithMessageText:@"Please confirm"
											defaultButton:@"No" 
										  alternateButton:@"Yes"
											  otherButton:nil
								informativeTextWithFormat:[NSString stringWithFormat:@"Do you really want to print %d pages?", nPagesToPrint]];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		NSInteger res = [theAlert runModal];
		if ( res  == NSAlertDefaultReturn )
		{
			return;
		}
	}


	if ( [docRec pagesCount] != 0xffffffff )
	{
		int nAllowedPages = [docRec pagesCount];

		if ( nPagesToPrint > nAllowedPages )
		{
			if ( copies.longValue == 1 )
			{
				nLastPage = nFirstPage + nAllowedPages - 1;
			}
			else
			{
				NSString* sMsg = [NSString stringWithFormat:@"You can only print %d pages but you selected to print %d", nAllowedPages, nPagesToPrint];

				[General displayAlert:@"Unable to print document!" message:sMsg];
				return;

			}
		}
		
		nPagesCount = nAllowedPages - nPagesToPrint;
		[docRec setPagesCount:nPagesCount];
	}
	
	if ( [docRec printCount] != 0xffffffff )
	{
		[docRec setPrintCount:[docRec printCount]-1];
	}
	
	//save printing counters
	[DocumentDB saveDocRec:docRec];
	
	CGFloat fRightMargin = [pi rightMargin];
	CGFloat fLeftMargin = [pi leftMargin];
	CGFloat fTopMargin = [pi topMargin];
	CGFloat fBottomMargin = [pi bottomMargin];

	[pi setRightMargin:0.0];
	[pi setLeftMargin:0.0];
	[pi setTopMargin:0.0];
	[pi setBottomMargin:0.0];
	
	float boundsX = 0;
	float boundsY = 0;
	float boundsHeight = 850;
	float boundsWidth  = 550;

	if ( [pi orientation] == NSPaperOrientationLandscape )
	{
		//restore correct paper orientation
		[pi setOrientation:NSPaperOrientationPortrait];
	}
	
	NSSize size = [pi paperSize];
	boundsWidth = size.width;
	boundsHeight= size.height;
	
	NSRect frameRect;
	frameRect = NSMakeRect(0, 0, boundsWidth+fRightMargin+fLeftMargin, boundsHeight+fTopMargin+fBottomMargin);
	
	JavelinPrintView *view = [[JavelinPrintView alloc] initWithFrame:frameRect];
	//[view setDocument:_javelinDocument.pdfDocument];
	
//	NSPrintOperation *printOp =
//		[NSPrintOperation printOperationWithView:self printInfo:pi];
//	[[printOp setShowsPrintPanel:NO];

	/* IF YOU WANT TO NORMALLY PRINT PDF DOCUMENT - USE THIS CODE
	NSPrintOperation * printOp = [[jd pdfDocument] printOperationForPrintInfo:pi scalingMode:kPDFPrintPageScaleToFit autoRotate:YES];
	[printOp setShowsPrintPanel:NO];
	[printOp runOperation];
	return;
	*/
	if ( [_watermark isPrint] )
		[view setWatermark:_watermark];

	[[Log getLog] addLine:[NSString stringWithFormat:@"Printing from:%d to %d", nFirstPage, nLastPage ]];
	
	
	//[[Log getLog] addLine:[NSString stringWithFormat:@"Printer name: %@", [pr name]]];
	//[[Log getLog] addLine:[NSString stringWithFormat:@"Printer type: %@", [pr type]]];
	NSString* sDesc = [NSString stringWithFormat:@"Printing %@ [%d] on %@ [%@]", 
					   [[jd DocumentURL] lastPathComponent], 
					   [jd documentID], [pr name], [pr type] ];
	NSString* sText = [NSString stringWithFormat:@"Page count: %d", nLastPage-nFirstPage+1];
	
	[ActivityManager addActivityWithDocID:[jd docInfo]->dwDocID 
							   activityID:142 
							  description:sDesc 
									 text:sText 
									error:nil];
	for( int nPage=nFirstPage; nPage<=nLastPage; nPage++ )
	{
		PMPrinterState printerState;
		OSStatus status = PMPrinterGetState(currentPrinter, &printerState);
		
		if (status != 0 )
		{
			[[Log getLog] addLine:[NSString stringWithFormat:@"ERROR: Unable to retrieve queue status (error:%d page:%d)", status, nPage ]];
			continue;
		}
		
		if (printerState == kPMPrinterStopped)
		{
			[[Log getLog] addLine:@"ERROR: Printer queue paused or not acccessible"];
			continue;
		}
// Commented out on 2023-06-22
//		else if (printerState == kPMPrinterProcessing)
//		{
//			[[Log getLog] addLine:[NSString stringWithFormat:@"ERROR: Printer queue is busy. Skipping page:%d", nPage]];
//			continue;
//		}
// END
		
/*		CFURLRef urlref;
		status = PMPrinterCopyDeviceURI(currentPrinter, &urlref);

		if (status != 0 )
		{
			CFRelease(urlref);
			[[Log getLog] addLine:[NSString stringWithFormat:@"ERROR: Unable to retrieve printer status (error:%d page:%d)", status, nPage ]];
			continue;
		}
		
		CFRelease(urlref);*/
		
/*		CFStringRef hostName;
		status = PMPrinterCopyHostName(currentPrinter, &hostName);
		CFRange range;
		range.location=0;
		range.length = CFStringGetLength(hostName);
		CFStringDelete(hostName, range);
*/		
		PDFPage *page = [[[self document] pageAtIndex:nPage-1] copy];
		int nRotation = [page rotation];
		BOOL bLandscape = NO;
		NSRect pageRect = [page boundsForBox:kPDFDisplayBoxCropBox];
		
		if ( nRotation == 90 )
			bLandscape = YES;
		
		if ( pageRect.size.width > pageRect.size.height )
		{
			//[page setRotation:90];
			bLandscape = YES;
		}
		NSData *pData = [page dataRepresentation];

		//2016-10-16
		//[self printPDFFromData:pData printInfo:pi page:page];
		/////////////////
		
		NSPDFImageRep *pRep = [NSPDFImageRep imageRepWithData:pData];
		
		NSRect imageRect = [pRep bounds];

		NSImage *pdfImage = [[NSImage alloc] init];
		
		NSSize paperSize = size;//[pi paperSize];
		
/*		if ( bLandscape && paperSize.width < paperSize.height )
		{
			CGFloat f = paperSize.height;
			paperSize.height = paperSize.width;
			paperSize.width = f;
		}*/

		//NSSize imageSize = paperSize;
		
		[pdfImage addRepresentation: pRep];
		
		//imageRect.size.width =imageRect.size.width-fLeftMargin;//-fRightMargin+1;
		//imageRect.size.height = imageRect.size.height-fTopMargin;//-fBottomMargin+1;
		
		NSRect rrr = NSMakeRect(0, 0, paperSize.width, paperSize.height);
		
		//NSRect rrr = imageRect;
		if ( bLandscape )
		{
			CGFloat f = rrr.size.height;
			rrr.size.height = rrr.size.width;
			rrr.size.width = f;
		}
		
		[view setFrame:rrr];//imageRect];
		//[self printPage:pdfImage withPrintInfo:pi];
		[view setImage:pdfImage];
		
		
		[view setImageScaling:NSImageScaleAxesIndependently];//NSImageScaleAxesIndependently];//NSImageScaleNone];//NSScaleToFit]

		[[Log getLog] addLine:[NSString stringWithFormat:@"Printing page:%d", nPage ]];
		
		if ( [_watermark printToPage:nPage] )
			[_watermark allowPrint:YES];
		else
			[_watermark allowPrint:NO];

		//if ( bLandscape )
		//	[pi setOrientation:NSPaperOrientationLandscape];
		//else
			[pi setOrientation:NSPaperOrientationPortrait];
		
		[pi setVerticallyCentered:YES];
		[pi setHorizontallyCentered:YES];
	    [pi setTopMargin:0.0];
		[pi setBottomMargin:0.0];
		[pi setLeftMargin:0.0];
		[pi setRightMargin:0.0];
		[pi setHorizontalPagination:NSFitPagination];
		[pi setVerticalPagination:NSFitPagination];
		[pi setOrientation:(bLandscape?NSPaperOrientationLandscape:NSPaperOrientationPortrait)];
//[info setHorizontalPagination:NSClipPagination];
//[info setVerticalPagination:NSClipPagination];
		NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:view printInfo:pi];
		[printOp setShowsPrintPanel:NO];
		[printOp setPrintInfo:pi];
		[printOp runOperation];
		
		page = nil;
		pdfImage = nil;
		//[pRep release];
	}

	[[Log getLog] addLine:@"Printing ended!"];

}

- (BOOL) checkPrinterName:(NSString*)sPrinterName1
{
#ifdef DEBUG_PRINT
	return YES;
#else
	//check for "HP " (upper case!)
	if ( [sPrinterName1 rangeOfString:@"HP "].location != NSNotFound ) return YES;
	
	NSString* sPrinterName = [sPrinterName1 lowercaseString];
	
	if ( [sPrinterName rangeOfString:@"agfa"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"alps"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"apollo"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"apple"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"aps-ps"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"ast"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"at&t"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"brother"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"bull"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"c-itoh"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"canon"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"citizen"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"colorage"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"compaq"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"dataproducts"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"diconix"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"dell"].location != NSNotFound ) return YES;//2016-06-03
	if ( [sPrinterName rangeOfString:@"digital"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"epson"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"fujitsu"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"fuji_xerox"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"gcc"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"gestetner"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"hp"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"ibm"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"infotec"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"iwatsu"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"kodak"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"konica"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"kyocera"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"lanier"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"lasermaster"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"laserjet"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"lexmark"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"linotronic"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"mannesmann"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"tally"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"microsoft"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"microtek"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"minolta"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"monotype"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"nec"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"nrg"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"oce"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"officejet"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"oki"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"okidata"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"olivetti"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"panasonic"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"photosmart"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"printronix"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"qms"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"quad"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"qume"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"radio_shack"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"ricoh"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"riso"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"royal"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"samsung"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"savin"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"schlumberger"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"scitex"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"seiko"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"sharp"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"shinko"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"star"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"tally"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"tandy"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"tegra"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"tektronix"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"texas_instruments"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"toshiba"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"unisys"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"varityper"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"wang"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"wipro"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"xante"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"xerox"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"cups"].location != NSNotFound ) return YES;
	//added 2018-06-12 presumably Konica/Minolta
	if ( [sPrinterName rangeOfString:@"c360creative"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"c280creative"].location != NSNotFound ) return YES;
	if ( [sPrinterName rangeOfString:@"c220creative"].location != NSNotFound ) return YES;
	//added 2021-10-04 Pantum device 
	if ( [sPrinterName rangeOfString:@"pantum"].location != NSNotFound ) return YES;
	//2021-10-29 DocuCentre (Xerox)
	if ( [sPrinterName rangeOfString:@"docucentre"].location != NSNotFound ) return YES;
	//2021-11-11 Taskalfa
	if ( [sPrinterName rangeOfString:@"taskalfa"].location != NSNotFound ) return YES;
	return NO;
#endif
}

-(void) printPage:(NSImage*)image withPrintInfo:(NSPrintInfo*)pi
{
	[[Log getLog] addLine:@"JavelinPdfView::printPage:withInfo"];
	float boundsX = 0;
	float boundsY = 0;
	float boundsHeight = 850;
	float boundsWidth  = 550;

	NSSize size = [pi paperSize];
	boundsWidth = size.width;
	boundsHeight= size.height;
	
	NSRect frameRect;
	frameRect = NSMakeRect(0, 0, boundsWidth, boundsHeight);
	
    NSImageView *view = [[NSImageView alloc] initWithFrame:frameRect];
    [view setImage:image];
    [view setImageScaling:NSScaleProportionally];//NSScaleToFit]
    [view setBoundsOrigin:NSZeroPoint];//NSMakePoint(boundsX, boundsY)];
    [view setBoundsSize:size];//NSMakeSize(boundsWidth, boundsHeight)];
    [view translateOriginToPoint:NSMakePoint(boundsX, [pi paperSize].height - boundsHeight - boundsY)];
	
	
    NSPrintOperation *printOp =
		[NSPrintOperation printOperationWithView:view printInfo:pi];
    [printOp setShowsPrintPanel:NO];
    [printOp runOperation];
}

/*
- (void)print:(id)sender
{
	[[Log getLog] addLine:@"JavelinPdfView::print"];
	[self printJvlnDocument:sender];
//	[super print:sender];
}
*/
/*
- (void)displayAlert:(NSString*)sTitle message:(NSString*)sMessage
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:sTitle 
										defaultButton:nil 
									  alternateButton:nil 
										  otherButton:nil 
							informativeTextWithFormat:sMessage];
	[theAlert setAlertStyle:NSWarningAlertStyle];
	[theAlert runModal];
}*/
/*
- (void)printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate
{
	[[Log getLog] addLine:@"JavelinPdfView::printWithInfo:autoRotate"];
	[super printWithInfo:printInfo autoRotate:doRotate];
}

- (void)printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate pageScaling:(PDFPrintScalingMode)scale
{
	[[Log getLog] addLine:@"JavelinPdfView::printWithInfo:autoRotate:pageScaling"];
	[super printWithInfo:printInfo autoRotate:doRotate pageScaling:scale];
}
*/
// ------------------------------------------------------------------------------------------------------- saveDocumentAs

- (void) copy: (id) sender
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:@"Unable to copy document to pasteboard!" 
										defaultButton:nil 
									  alternateButton:nil 
										  otherButton:nil 
							informativeTextWithFormat:@""];
	[theAlert setAlertStyle:NSWarningAlertStyle];
	[theAlert runModal];
	
	//NSDocument *d = [[[self window] windowController] document];
	return;
/*
    // Put PDF and TIFF data on the Pasteboard if no text selected.
	if ([self currentSelection] == NULL)
	{
		NSData		*pageData;
		NSImage		*image;
		
		// Get PDF data for single (current) page.
		pageData = [[self currentPage] dataRepresentation];
		
		// Create NSImage from PDF data.
		image = [[[NSImage alloc] initWithData: pageData] autorelease];
		
		// Types to pasteboard.
		[[NSPasteboard generalPasteboard] declareTypes: [NSArray arrayWithObjects: NSPDFPboardType, NSTIFFPboardType, 
                                                         NULL] owner: NULL];
		
		// Assign data.
		[[NSPasteboard generalPasteboard] setData: pageData forType: NSPDFPboardType];
		[[NSPasteboard generalPasteboard] setData: [image TIFFRepresentationUsingCompression: NSTIFFCompressionLZW 
                                                                                      factor: 0 ] forType: NSTIFFPboardType];
	}
	else
	{
		// Default behavior (PDFView will handle the text case for free).
		[super copy: sender];
	}*/
}

#pragma mark -------- accessors
// ----------------------------------------------------------------------------------------------------- activeAnnotation

- (PDFAnnotationLink *) activeAnnotation
{
	return _activeAnnotation;
}

// -------------------------------------------------------------------------------------------------- setActiveAnnotation

- (void) setActiveAnnotation: (PDFAnnotationLink *) newLink;
{
	BOOL		linkChange;
	
	// Change?
	linkChange = newLink != _activeAnnotation;
	
	// Will need to redraw old active anotation.
	if (_activeAnnotation != NULL)
	{
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_myActiveAnnotation boundary] fromPage:
                                                    [self currentPage]], [self scaleFactor])];
	}
	
	// Assign.
	if (newLink)
	{
		_activeAnnotation = newLink;
		_activePage = [newLink page];
		
		// Force redisplay.
		[self setNeedsDisplayInRect: RectPlusScale([self convertRect: [_myActiveAnnotation boundary] fromPage: _activePage],
                                                   [self scaleFactor])];
	}
	else
	{
		_activeAnnotation = NULL;
		_activePage = NULL;
	}
	
	if (linkChange)
	{
		// Notification (MyWindowController listens for this).
		//[[NSNotificationCenter defaultCenter] postNotificationName: @"newActiveAnnotation" object: self userInfo: NULL];
	}
}

// --------------------------------------------------------------------------------------------------- defaultNewLinkSize

- (NSSize) defaultNewLinkSize
{
	return NSMakeSize(180.0, 16.0);
}

// --------------------------------------------------------------------------------------------------- resizeThumbForRect

- (NSRect) resizeThumbForRect: (NSRect) rect rotation: (int) rotation
{
	NSRect		thumb;
	
	// Start with rect.
	thumb = rect;
	
	// Use rotation to determine thumb origin.
	switch (rotation)
	{
		case 0:
            thumb.origin.x += rect.size.width -16.0;
            break;
            
		case 90:
            thumb.origin.x += rect.size.width - 16.0;
            thumb.origin.y += rect.size.height - 16.0;
            break;
            
		case 180:
            thumb.origin.y += rect.size.height - 16.0;
            break;
	}
	
	thumb.size.width = 16.0;
	thumb.size.height = 16.0;
	
	return thumb;
}

// -------------------------------------------------------------------------------------------------------- RectPlusScale

static NSRect RectPlusScale (NSRect aRect, float scale)
{
	float		maxX;
	float		maxY;
	NSPoint		origin;
	
	// Determine edges.
	maxX = ceilf(aRect.origin.x + aRect.size.width) + scale;
	maxY = ceilf(aRect.origin.y + aRect.size.height) + scale;
	origin.x = floorf(aRect.origin.x) - scale;
	origin.y = floorf(aRect.origin.y) - scale;
	
	return NSMakeRect(origin.x, origin.y, maxX - origin.x, maxY - origin.y);
}

/////////// DRAGGING
//	dragCursor -- Return a cursor which hints that the user can drag.
//	FIXME: A hand would be better than this pointing finger.
/*+ (NSCursor *) dragCursor
{
    static NSCursor	*openHandCursor = nil;
    
    if (openHandCursor == nil)
    {
        NSImage		*image;
        
        image = [NSImage imageNamed: @"fingerCursor"];
        openHandCursor = [[NSCursor alloc] initWithImage: image
                                                 hotSpot: NSMakePoint (8, 8)]; // guess that the center is good
    }
    
    return openHandCursor;
}*/


#pragma mark PRIVATE INSTANCE METHODS

//	canScroll -- Return YES if the user could scroll.
- (BOOL) canScroll
{
/*    [self documentView] documentv
    if ([[self documentView] frame].size.height > [self documentVisibleRect].size.height)
        return YES;
    if ([[self documentView] frame].size.width > [self documentVisibleRect].size.width)
        return YES;
*/    
    return NO;
}


#pragma mark PUBLIC INSTANCE METHODS -- OVERRIDES FROM NSScrolLView

//	tile -- Override to update the document cursor.
/*- (void) tile
{
    [super tile];
    
    //	If the user can scroll right now, make our document cursor reflect that.
	if ([self canScroll])
        [self setDocumentCursor: [[self class] dragCursor]];
    else
        [self setDocumentCursor: [NSCursor arrowCursor]];
}*/


#pragma mark PUBLIC INSTANCE METHODS

//	dragDocumentWithMouseDown: -- Given a mousedown event, which should be in
//	our document view, track the mouse to let the user drag the document.
- (BOOL) mouseDownDrag: (NSEvent *) theEvent // RETURN: YES => user dragged (not clicked)
{
	NSPoint 		initialLocation;
    NSRect			visibleRect;
    BOOL			keepGoing;
    BOOL			result = NO;
    
	initialLocation = [theEvent locationInWindow];
    visibleRect = [[self documentView] visibleRect];
    keepGoing = YES;
        
    
    while (keepGoing)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
            {
                NSPoint	newLocation;
                NSRect	newVisibleRect;
                float	xDelta, yDelta;
                
                newLocation = [theEvent locationInWindow];
                xDelta = initialLocation.x - newLocation.x;
                yDelta = initialLocation.y - newLocation.y;
                
                //	This was an amusing bug: without checking for flipped,
                //	you could drag up, and the document would sometimes move down!
                if ([[self documentView] isFlipped])
                    yDelta = -yDelta;
                
                //	If they drag MORE than one pixel, consider it a drag
                if ( (abs (xDelta) > 1) || (abs (yDelta) > 1) )
                    result = YES;

                newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
                [[self documentView] scrollRectToVisible: newVisibleRect];
            }
                break;
                
            case NSLeftMouseUp:
                [super mouseUp: theEvent];
                keepGoing = NO;
                break;
                
            default:
                /* Ignore any other kind of event. */
                break;
        }								// end of switch (event type)
    }									// end of mouse-tracking loop
    
    return result;
}

- (void)setDelegate:(id)del
{
	delegate = del;
}

-(void)setNoteViewDelegate:(id)del
{
    m_delNoteView = del;
}

#pragma mark -- Note View Protocol
-(void)itemDoubleClicked:(JAnnotation*)annot
{
    [self editNote:annot];
}

-(void)deleteNote:(JAnnotation*)annot
{
    if ( [[_javelinDocument annotations] removeAnnotation:annot fromPage:[annot pageNumber]] )
    {
        [self setNeedsDisplay: YES];
        [[self window] setDocumentEdited: YES];
        [delegate noteChanged];
    }
}

-(void)exportAllNotes
{
	if ( [[_javelinDocument annotations] count] > 0 )
	{
		NSString* sText = [[_javelinDocument annotations] getAllAnnotations];
		if ( sText != nil && sText.length > 0 )
		{
			NSFileManager* fm = [NSFileManager defaultManager];
			NSString *guid = [NSString stringWithFormat:@"%@.txt", [[NSProcessInfo processInfo] globallyUniqueString]];
			NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
			/*NSData* data = [sText dataUsingEncoding:NSUTF8StringEncoding];
			if(![fm createFileAtPath:path contents:data attributes:nil]) 
			{
				
				[[NSWorkspace sharedWorkspace] openFile:path];
			}*/
			if ( [fm createFileAtPath:path contents:nil attributes:nil] )
			{
				NSString* sFullText = [NSString stringWithFormat:@"Annotations for document\n%@\n\n%@", [_javelinDocument DocumentURL], sText];
				[sFullText writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
				[[NSWorkspace sharedWorkspace] openFile:path];
			}
			else
			{
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:@"ERROR: Unable to show annotations."];
				[alert runModal];
			}
		}
	}
	else
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"This document doesn't have any annotation"];
		[alert runModal];
	}

}


/////////// END-OF-DRAGGING
////////VARIOUS TESTS
/*		NSView *pSuper = [self documentView];//[super self];//[self superview];
 NSPrintOperation *op = [NSPrintOperation printOperationWithView:pSuper
 printInfo:pi];
 [op setShowsPrintPanel:NO];
 [op runOperation];*/
/*
 NSDictionary *d2 = [pi printSettings];
 NSArray *aK2 = [d2 allKeys];
 NSArray *aV2 = [d2 allValues];
 for( int i=0; i<[aK2 count]; i++ )
 {
 NSLog(@"Settings Key:%@ Val:%@", [aK2 objectAtIndex:i], [aV2 objectAtIndex:i]);
 }
 */

//		NSLog( @"PRINTER Name=%@ Type=%@", [pr name], [pr type] );
/*
 NSDictionary *d = [pr deviceDescription];
 NSArray *aK = [d allKeys];
 NSArray *aV = [d allValues];
 for( int i=0; i<[aK count]; i++ )
 {
 NSLog(@"Key:%@ Val:%@", [aK objectAtIndex:i], [aV objectAtIndex:i]);
 //Key:com_apple_print_PrintSettings_PMDestinationType Val:2
 }*/

//		NSPrintOperation *po = [NSPrintOperation currentOperation];
//		[po setShowsPrintPanel:NO];
//		[NSPrintOperation setCurrentOperation:po];
/*
 NSView *pSuper = [self documentView];//[super self];//[self superview];
 NSPrintOperation *op = [NSPrintOperation printOperationWithView:pSuper
 printInfo:pi];
 
 [op setShowsPrintPanel:NO];
 [op runOperation];
 return;
 */		


/*		NSLog( @"PRINTER Name=%@ Type=%@", [pr name], [pr type] );
 
 NSArray *aK = [d allKeys];
 NSArray *aV = [d allValues];
 for( int i=0; i<[aK count]; i++ )
 {
 NSLog(@"Key:%@ Val:%@", [aK objectAtIndex:i], [aV objectAtIndex:i]);
 //Key:com_apple_print_PrintSettings_PMDestinationType Val:2
 }*/

/*		NSArray *aK1 = [d1 allKeys];
 NSArray *aV1 = [d1 allValues];
 for( int i=0; i<[aK1 count]; i++ )
 {
 NSLog(@"PIdict Key:%@ Val:%@", [aK1 objectAtIndex:i], [aV1 objectAtIndex:i]);
 }
 
 NSNumber *rightMargin = [d1 objectForKey:@"NSRightMargin"];
 NSNumber *leftMargin  = [d1 objectForKey:@"NSLeftMargin"];
 NSNumber *topMargin   = [d1 objectForKey:@"NSTopMargin"];
 NSNumber *bottomMargin= [d1 objectForKey:@"NSBottomMargin"];
 NSNumber *firstPage   = [d1 objectForKey:@"NSFirstPage"];
 NSNumber *lastPage    = [d1 objectForKey:@"NSLastPage"];
 NSValue  *pageSize	  = [d1 objectForKey:@"NSPaperSize"];
 
 NSNumber *zero = [NSNumber numberWithInt:0];
 [d1 setObject:zero forKey:@"NSRightMargin"];
 [d1 setObject:zero forKey:@"NSLeftMargin"];
 [d1 setObject:zero forKey:@"NSTopMargin"];
 [d1 setObject:zero forKey:@"NSBottomMargin"];
 NSSize S;
 [pageSize getValue:&S];
 NSView *pSuper = [super self];//[self superview];
 NSPrintOperation *op = [NSPrintOperation printOperationWithView:pSuper
 printInfo:pi];
 [op setShowsPrintPanel:NO];
 [op runOperation];
 //[super printWithInfo:pi autoRotate:YES];
 return;*/

////////END OF VARIOUS TESTS


@end
