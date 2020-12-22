//
//  JavelinPrintView.m
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JavelinPrintView.h"
#import "Watermark.h"


@implementation JavelinPrintView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		_watermark = nil;
    }
    //[self setImageFrameStyle:NSImageFramePhoto];
    return self;
}
/*
- (void)dealloc
{
	if ( _watermark != nil ) [_watermark release];
	
    [super dealloc];
}
*/
-(void) setWatermark:(Watermark*)watermark
{
	//[_watermark release];
	_watermark = watermark;
	//[_watermark retain];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if ( _watermark != nil )
	{
		NSRect myRect = [self frame];

		[_watermark printAt:NSMakePoint(0, 0) rect:myRect];
	}
}
/*
NSPrintOperation* op1 = nil;
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
    [invocation getReturnValue:&op1];
	
    // Run the print operation without showing any dialogs.
    [op1 setShowsPrintPanel:NO];
    [op1 setShowsProgressPanel:NO];
    if ( YES == [op1 runOperation] )
	{
	}
}

-(void) doMyPrint:(NSPrintInfo*)pi
{
	[pi setTopMargin:0.0];
	[pi setBottomMargin:0.0];
	[pi setLeftMargin:0.0];
	[pi setRightMargin:0.0];
	[pi setHorizontalPagination:NSFitPagination];
    [pi setVerticalPagination:NSFitPagination];

	NSMutableDictionary *d1 = [pi dictionary];
	
	[d1 setValue:[NSNumber numberWithInteger:1] forKey:@"NSFirstPage"];
	[d1 setValue:[NSNumber numberWithInteger:3] forKey:@"NSLastPage"];
	
	
	
	NSNumber *rightMargin = [d1 objectForKey:@"NSRightMargin"];
	NSNumber *leftMargin  = [d1 objectForKey:@"NSLeftMargin"];
	NSNumber *topMargin   = [d1 objectForKey:@"NSTopMargin"];
	NSNumber *bottomMargin= [d1 objectForKey:@"NSBottomMargin"];
	NSNumber *firstPage   = [d1 objectForKey:@"NSFirstPage"];
	NSNumber *lastPage    = [d1 objectForKey:@"NSLastPage"];
	NSValue  *pageSize	  = [d1 objectForKey:@"NSPaperSize"];
	NSNumber* copies	  = [d1 objectForKey:NSPrintCopies];

	NSPrintOperation *printOp =
		[NSPrintOperation printOperationWithView:self printInfo:pi];
	[printOp setShowsPrintPanel:NO];

	//[[Log getLog] addLine:[NSString stringWithFormat:@"Printing from:%d to %d", nFirstPage, nLastPage ]];
	
	//printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate;
	
	//[self printWithInfo:pi autoRotate:YES];
	[printOp setPrintInfo:pi];
	[printOp runOperation];

}

- (void)printWithInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)doRotate pageScaling:(PDFPrintScalingMode)scale
{
	[super printWithInfo:printInfo autoRotate:doRotate pageScaling:scale];
	
	int i = 100;
	i++;
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
*/

@end
