//
//  PropertiesController.m
//  Javelin
//
//  Created by harry on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PropertiesController.h"
#import "PDFDocument.h"
#import "DocumentRecord.h"


@implementation PropertiesController
@synthesize properties;
@synthesize selfAuth = m_bSelfAuth;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		//pdfAttributes = nil;
    }
    
    return self;
}
/*
- (void)dealloc
{
	//if ( pdfAttributes != nil ) [pdfAttributes release];
	
    [super dealloc];
}
*/
/*
- (void) setProperties: (NSDictionary*)attrs
{
	pdfAttributes = [NSDictionary dictionaryWithDictionary:attrs];
}
*/

- (void) set:(NSTextField*)field withText:(id)value
{
	if ( value != nil )
	{
		[field setStringValue:(NSString*)value];
	}
	else
	{
		[field setStringValue:@"N/A"];
	}
}

- (void)fillProperties:(NSDictionary*)attrs 
			 docRecord:(DocumentRecord*)docRec 
			  fileName:(NSString*)sFileName  
			  fileSize:(NSUInteger)nFileSize 
		 blockGrabbers:(BOOL)bBlockGrabbers
			publisherID:(NSUInteger)nPublisherID	
				 pages:(NSUInteger)nPages 
			  inWindow:(NSWindow*)window
{
	[NSBundle loadNibNamed: @"Properties" owner: self];
	
	if ( attrs != nil )
	{
/*		NSArray *keys = [attrs allKeys];
		NSArray	*vals = [attrs allValues];
		
		for( int i=0; i<[keys count]; i++ )
		{
			NSLog( @"%@=%@", [keys objectAtIndex:i], [vals objectAtIndex:i] );
		}*/
		[self set:creator withText:[attrs objectForKey:@"Creator"]];
		[self set:title withText:[attrs objectForKey:@"Title"]];
		[self set:author withText:[attrs objectForKey:@"Author"]];
		[self set:subject withText:[attrs objectForKey:@"Subject"]];
		[self set:pages withText:[NSString stringWithFormat:@"%lu", nPages]];
		[self set:filesize withText:[NSString stringWithFormat:@"%lu", nFileSize]];
		[self set:filename withText:sFileName];
		
		id keywords1 = [attrs objectForKey:@"Keywords"];
		if ( keywords1 != nil )
		{
			NSArray* ar = (NSArray*)keywords1;
			NSMutableString *s33 = [[NSMutableString alloc] init];
			for( int i=0; i<[ar count]; i++ )
			{
				NSString *ss1 = [NSString stringWithFormat:@"[%@] ", [ar objectAtIndex:i]];
				[s33 appendString:ss1];
			}
			[self set:keywords withText:s33];
		}
		else [self set:keywords withText:@"N/A"];
			
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];		

		id d = [attrs objectForKey:@"CreationDate"];
		
		if ( d != nil )
		{
			NSString *ss1 = [dateFormatter stringFromDate:d];
//			NSString* ss1 = [NSString stringWithFormat:@"%04d-%02d-%02d", d.year, d.month, d.day ];
			[self set:created withText:ss1];
		}
		else [self set:created withText:@"N/A"];
		
		d = [attrs objectForKey:@"ModDate"];
		if ( d != nil )
		{
			NSString *ss1 = [dateFormatter stringFromDate:d];
			[self set:modified withText:ss1];
		}
		else [self set:modified withText:@"N/A"];

		[self set:producer withText:[attrs objectForKey:@"Producer"]];
	}
	
	if ( docRec != nil )
	{
		if ( [docRec openCount] > 0 )
			[openedNo setStringValue:[NSString stringWithFormat:@"%d views", [docRec openCount]]];
		else if ( [docRec openCount] == 0 )
			[openedNo setStringValue:@"Not allowed"];
		else
			[openedNo setStringValue:@"Unlimited"];

		if ( [docRec printCount] > 0 && [docRec pagesCount] != 0 )
			[printedNo setStringValue:[NSString stringWithFormat:@"%d prints", [docRec printCount]]];
		else if ( [docRec printCount] == 0 || [docRec pagesCount] == 0 )
			[printedNo setStringValue:@"No printing allowed"];
		else
			[printedNo setStringValue:@"Unlimited"];

		if ( [docRec pagesCount] > 0 && [docRec printCount] != 0)
			[printPages setStringValue:[NSString stringWithFormat:@"%d pages", [docRec pagesCount]]];
		else if ( [docRec printCount] == 0 || [docRec pagesCount] == 0  )
			[printPages setStringValue:@"No printing allowed"];
		else
			[printPages setStringValue:@"Unlimited"];

		[endDate setStringValue:[docRec expiresString]]; 
		[startDate setStringValue:@"N/A"];
		[docID setStringValue:[NSString stringWithFormat:@"%d", [docRec docID]]];
		
		[txSelfAuth setStringValue:(m_bSelfAuth?@"YES":@"NO")];
		
		[disableScreenCapture setStringValue:(bBlockGrabbers?@"YES":@"NO")];
		[publisherID setStringValue:[NSString stringWithFormat:@"%lu", nPublisherID]];
	}

    [NSApp beginSheet: properties
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	
    // Sheet is up here.
    // Return processing to the event loop
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (IBAction)closeProperties: (id)sender
{
    [NSApp endSheet:properties];
}
@end
