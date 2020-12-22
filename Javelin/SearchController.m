//
//  SearchController.m
//  JavelinM
//
//  Created by harry on 20/10/2016.
//
//

#import "SearchController.h"

@interface SearchController ()

@end

@implementation SearchController
//@synthesize pdfDocument=m_document;
//@synthesize pdfSelection=m_selection;
@synthesize pdfView=m_pdfView;

-(id)init
{
	if (![super initWithWindowNibName:@"SearchController"])
	{
		return nil;
	}
	
	//m_document = nil;
	//m_selection = nil;
	m_pdfView = nil;
	[m_btnNext setKeyEquivalent:@"\r"];
	return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
}

- (IBAction)findNext: (id)sender
{
	if ( m_pdfView != nil )
	{
		NSString* s = [m_txString stringValue];
		if ( s == nil || s.length <= 0 )
			return;
		
		NSInteger options = NSCaseInsensitiveSearch;
		PDFSelection* currentSelection = [m_pdfView currentSelection];
		PDFSelection* selection = [[m_pdfView document] findString:s fromSelection:currentSelection withOptions:options];
		
//		if ([selection hasCharacters] == NO )
//			selection = [m_document findString:s fromSelection:nil withOptions:options];
		
		if (selection)
		{
//			[m_pdfView setCurrentSelection:selection];
			//NSLog(@"%@", [selection string]);
			NSArray<PDFPage*>* pages = [selection pages];
			if ( pages != nil && pages.count > 0 )
			{
				//NSLog(@"%@", NSStringFromRect([selection boundsForPage:[pages objectAtIndex:0]]));
				[m_pdfView goToPage:[pages objectAtIndex:0]];
				[m_pdfView scrollSelectionToVisible:self];
				[m_pdfView setCurrentSelection:selection animate:YES];
			}
		} else {
			NSBeep();
		}
	}
}

- (IBAction)findPrevious: (id)sender
{
	if ( m_pdfView != nil )
	{
		NSString* s = [m_txString stringValue];
		if ( s == nil || s.length <= 0 )
			return;
		
		NSInteger options = NSCaseInsensitiveSearch | NSBackwardsSearch;
		PDFSelection* currentSelection = [m_pdfView currentSelection];
		PDFSelection* selection = [[m_pdfView document] findString:s fromSelection:currentSelection withOptions:options];
		
//		if ([selection hasCharacters] == NO )
//			selection = [m_document findString:s fromSelection:nil withOptions:options];
		
		if (selection)
		{
			NSArray<PDFPage*>* pages = [selection pages];
			if ( pages != nil && pages.count > 0 )
			{
				[m_pdfView goToPage:[pages objectAtIndex:0]];
				[m_pdfView scrollSelectionToVisible:self];
				[m_pdfView setCurrentSelection:selection animate:YES];
			}
		} else {
			NSBeep();
		}
	}
}

- (IBAction)close: (id)sender
{
	[self dismissController:self];
}

@end
