//
//  JavelinDocument.m
//  Javelin
//
//  Created by harry on 8/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JavelinDocument.h"
#import "JavelinController.h"
#import "DocumentRecord.h"
#import "DocumentDB.h"
#import "Drumlin.h"
#import "Log.h"
#import "JAnnotation.h"
#import "Note.h"
#import "General.h"
#import "JAnnotations.h"
#import "ActivityManager.h"

@implementation JavelinDocument

@synthesize pdfDocument=m_document;
@synthesize authCode=m_authCode;
@synthesize annotations=m_annotations;
@synthesize DocumentURL=m_docURL;
@synthesize fileSize = m_nFileSize;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		_fileContents = nil;
		m_nFileSize = 0;
		m_authCode = @"";
        m_annotations = [[JAnnotations alloc] initWithDocument:self];
	}
    
    return self;
}
/*
- (void)dealloc
{
	if ( _pDocInfo != NULL )
	{
		free( _pDocInfo );
		_pDocInfo = NULL;
	}

    [super dealloc];
}
*/
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"JavelinDocument";
}
/*
- (void) makeWindowControllers
{
    wc = [[MyPDFWindowController alloc] init];
    [self addWindowController: wc];
    
    fullScreenWindow = nil;
}*/
- (void) makeWindowControllers
{
    //JavelinController	*controller;
    
    // Create controller.
    //m_controller = [[JavelinController alloc] initWithWindowNibName: [self windowNibName]];
	m_controller = [[JavelinController alloc] init];
    [self addWindowController: m_controller];
    
    // Done.
    //[controller release];
    
    return;
}

-(JavelinController*)mainWindowController
{
	return m_controller;
}

- (BOOL) openPDF:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
    NSFileManager *fm;
    NSData *data;

    m_document = nil;
	m_docURL = nil;
	m_nFileSize = 0;
	
    fm = [NSFileManager defaultManager];
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
        data = [[fm contentsAtPath:[url path]] copy];
        BOOL res = [self readFromData:data ofType:typeName error:outError];
		
		if ( res == YES )
		{
			m_docURL = url;
			m_document = [[PDFDocument alloc] initWithData:data];
            [self readAnnotations];
			isClosed = NO;
			m_nFileSize = [data length];
			//m_nFileSize = [[fm attributesOfItemAtPath:[url path] error:nil] fileSize];
		}
        return res;
    }
    
    return NO;
}

- (BOOL) openDRMX:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
    NSFileManager *fm;
    NSData *data;
	NSError* pError = nil;
    
	[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile:%@",url]];
	
    fm = [NSFileManager defaultManager];
	m_nFileSize = 0;
RE_AUTHORISE:
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
		[[Log getLog] addLine:@"DBG: openDrmxFile - file OK"];
		
        data = [fm contentsAtPath:[url path]];
        BOOL res = [self openDrmxDocumentFromData:data error:&pError];
		
		if ( res == YES )
		{
			m_docURL = url;
			isClosed = NO;
			[self readAnnotations];
			[[Log getLog] addLine:[NSString stringWithFormat:@"Opened DRMX file: %@", m_docURL]];
			m_nFileSize = [data length];
			return YES;
		}
    }
    
	if ( pError != nil && ([pError code] == -110 || [pError code] == -113 || [pError code] == -11 || [pError code] == -5 || [pError code] == -6) )
	{
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile: ERROR CODE: %ld",(long)[pError code]]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile: ERROR DESC: %@",[pError localizedDescription]]];
		
		[ActivityManager addActivityWithDocID:0 
								   activityID:0 
								  description:
		 [NSString stringWithFormat:@"ERR: Unable to open document. err:%d desc:%@", (int)[pError code], [pError localizedDescription]] 
										 text:@"" 
										error:nil];
		
		NSAlert *theAlert = [NSAlert alertWithMessageText:[pError localizedDescription] 
											defaultButton:@"OK" 
										  alternateButton:@"Cancel"
											  otherButton:nil
								informativeTextWithFormat:@"Do you want to re-authorise document?"];
		int nRes = (int)[theAlert runModal];
		if (nRes == NSAlertDefaultReturn)
		{
			[DocumentDB deleteDocument:m_documentID];
//			if ( pError != nil ) [pError release];
			pError = nil;
			[[Log getLog] addLine:@"DBG: openDrmxFile - Will try to re-authorise"];
			goto RE_AUTHORISE;
/*			BOOL res = [self openDrmxDocumentFromData:data error:&pError];
			
			if ( res == YES )
			{
				return YES;
			}*/
		}
		return NO;
	}

	NSAlert *theAlert = [NSAlert alertWithError:pError];
	[theAlert runModal];
    return NO;
}

/*
 Opens a DRMX document form a memory buffer (NSData*)
 */
- (BOOL)openDrmxDocumentFromData:(NSData*)data error:(NSError**)ppError
{
	Drumlin *d = [[Drumlin alloc] init];
	[d setWindow:nil];
	
	NSData *pDoc = nil;
	m_nFileSize = 0;
	
	@try{
		[[Log getLog] addLine:@"DBG: openDrmxDocumentFromData: about to call openDrmxFileFromData"];
		pDoc = [d openDrmxFileFromData: data error:ppError];
		m_documentID = [d getDocID];
		m_authCode = [d getAuthCode];
		[self setDocumentInfo:[d docInfo]];
	}
	@catch( NSException *ex){
		if (ppError != NULL) 
		{
			NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
			[errorDetail setValue:[ex reason] forKey:NSLocalizedDescriptionKey];
			*ppError = [NSError errorWithDomain:@"Javelin" code:-300 userInfo:errorDetail];
		}
	}
	
	if ( pDoc != nil )
	{
		//bool res = [self openPdfDocumentFromData:pDoc];
		m_document = [[PDFDocument alloc] initWithData: pDoc];
		m_nFileSize = [data length];

		[ActivityManager addActivityWithDocID:m_documentID 
								   activityID:987 
								  description:[NSString stringWithFormat:@"Opened DocID:%d name:%@", m_documentID, [m_docURL lastPathComponent]] 
										 text:m_authCode error:nil];
		return YES;
	}
	else
	{
		[[Log getLog] addLine:@"DBG: openDrmxDocumentFromData: Unable to open document"];
	}
	//[d release];
	return NO;
}
/*
- (BOOL) openDoc:(PDFDocument*)pdfDoc 
	 withDocInfo:(PDOCEX_INFO)pDocInfo 
	 authCode:(NSString*)authCode
{
    // Set document.
    return YES;
}
*/


- (BOOL) openDRMZ:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
    NSFileManager *fm;
    NSData *data;

    m_document = nil;
	m_docURL = nil;
    
    fm = [NSFileManager defaultManager];
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
        data = [[fm contentsAtPath:[url path]] copy];
        BOOL res = [self readFromData:data ofType:typeName error:outError];
		
		if ( res == YES )
		{
			m_docURL = url;
			m_document = [[PDFDocument alloc] initWithData:data];
			isClosed = NO;
		}
        return res;
    }
    
    return NO;
}

- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( [typeName caseInsensitiveCompare:@"PDF Document"] == NSOrderedSame )
	{
		//read PDF document
		m_boolDrm = NO;
		return [self openPDF:url ofType:typeName error:outError];
	}
	
	m_docURL = url;
	
	if ( [typeName caseInsensitiveCompare:@"Javelin Document"] == NSOrderedSame )
	{
		//read DRMX document
		m_boolDrm = YES;
		return [self openDRMX:url ofType:typeName error:outError];
	}
	
	
	if ( [typeName caseInsensitiveCompare:@"Javelin Document Simple"] == NSOrderedSame )
	{
		//read DRMZ document
		m_boolDrm = YES;
		return [self openDRMZ:url ofType:typeName error:outError];
	}
	
	//FileType not supported
	m_boolDrm = NO;
    return NO;
}


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( [typeName caseInsensitiveCompare:@"PDF Document"] == NSOrderedSame ) return YES;
    if ( [typeName caseInsensitiveCompare:@"Javelin Document"] == NSOrderedSame ) return YES;
	if ( [typeName caseInsensitiveCompare:@"Javelin Document Simple"] == NSOrderedSame ) return YES;
	if ( [typeName caseInsensitiveCompare:@"Javelin Catalog"] == NSOrderedSame ) return YES;
    return NO;
}

- (NSAttributedString*)getFileContents
{
    return _fileContents;
}

- (BOOL)isEdited
{
	NSArray* controllers = [self windowControllers];
	int jj = 0;
	BOOL bDirty = NO;
	
	for( int i=0; i<controllers.count; i++)
	{
		JavelinController* cc = (JavelinController*)[controllers objectAtIndex:i];
		jj++;
		jj = i;
		bDirty = [cc isEdited];
		if ( bDirty )
			return YES;
	}
	
	return bDirty;
}

- (BOOL) saveDocument
{
	//NSLog(@"Saving %@ [%@]", [self fileURL], [self fileType]);
	
/*	if ( [[self fileType] caseInsensitiveCompare:@"PDF Document"] == NSOrderedSame )
	{
		//[self saveAnnotations];//DEBUG ONLY - not required for PDFs
		return [m_document writeToURL:[self fileURL]];
	}
	else**/
	{
		NSString* s = [m_annotations getAllAnnotations];
		NSLog(@"ANNOTS:\r\n %@", s);
		return [self saveAnnotationsNew];
	}
}

- (BOOL) saveAnnotationsNew
{
    return [m_annotations save:[self fileURL]];
}

- (BOOL) saveAnnotations
{
	NSMutableDictionary* pDict = [[NSMutableDictionary alloc] init];
	int nTotal = 0;
	for( int i=0; i<[m_document pageCount]; i++ )
	{
		//NSLog(@"Page: %d", i+1);
		//NSLog(@"-----------");
		PDFPage* page = [m_document pageAtIndex:i];
		int nAnnotCount = (int)[[page annotations] count];
		if ( nAnnotCount > 0 )
		{
			int nCount = 0;
			NSMutableArray* pArray = [[NSMutableArray alloc] init];
			for( int n=0; n < nAnnotCount; n++)
			{
				PDFAnnotation* ann = [[page annotations] objectAtIndex:n];
				if ( [[ann type] isEqualToString:@"Link"] == NO )
				{
					//NSLog(@"%@ -- %@ -- %@", NSStringFromRect([ann bounds]), [ann type], [ann contents] );
					nCount ++;
					
					if ( [ann bounds].origin.x > 0 && [ann bounds].origin.y > 0 && [ann bounds].size.height > 0 && [ann bounds].size.width > 0 )
					{
						JAnnotation* pJA = [[JAnnotation alloc] init];
						pJA.boundary = [ann bounds];
						pJA.type = [pJA getAnnotationType:[ann type]];
						pJA.text = [ann contents];
						if ( pJA.text == nil ) pJA.text = @"";
						
						pJA.title = [ann contents];
						if ( pJA.title == nil ) pJA.title = @"";
						
						[pArray addObject:pJA];
						
						nTotal ++;
					}
				}
			}
			if ( nCount > 0 )
			{
				NSNumber* key = [NSNumber numberWithInt:i];
				[pDict setObject:pArray forKey:key];
			}
		}
	}
	
	if ( nTotal > 0 )
	{
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:pDict];
		
		NSURL* url = [self getNtsUrl:m_docURL];//[m_docURL URLByAppendingPathExtension:@"nts"];
		
		NSError* error;
		BOOL bRes = [data writeToURL:url options:NSDataWritingAtomic error:&error];

		if(error != nil)
		{
			NSLog(@"write error %@", error);
			
			//NSLog(@"%@", [error localizedDescription]);
			[General displayAlert:@"ERROR: Unable to save annotations" message:[error localizedDescription]];
		}
	
		return bRes;
	}
	
	return YES;
}

- (NSURL*)getNtsUrl:(NSURL *)docURL
{
	NSURL* uurl = [General applicationDataDirectory];
	
	//make sure directory exists
//	NSFileManager* fileManager = [[NSFileManager alloc] init];
//	if (![fileManager fileExistsAtPath:[uurl path]])
//		[fileManager createDirectoryAtURL:uurl withIntermediateDirectories:NO attributes:nil error:nil];
	
	uurl = [uurl URLByAppendingPathComponent:[m_docURL lastPathComponent]];
	uurl = [uurl URLByAppendingPathExtension:@"nts"];

	return uurl;
}

- (void) readAnnotations
{
	NSURL* url = [self getNtsUrl:m_docURL];//[m_docURL URLByAppendingPathExtension:@"nts"];
	NSData *contentData = [NSData dataWithContentsOfURL:url];
	
	if ( contentData == nil )
		return;
	
	NSDictionary* dictLoaded = [NSKeyedUnarchiver unarchiveObjectWithData:contentData];
	//int n = [dictLoaded count];
	for (id key in dictLoaded)
	{
		NSArray* pp = dictLoaded[key];
		//NSLog(@"There are %d annotation on page %d", (int)[pp count], [key intValue]);
        int nPage = [key intValue];
		//PDFPage* page = [m_document pageAtIndex:nPage-1];
        
		//if (page != nil)
		{
           // int nPage = (int)CGPDFPageGetPageNumber([page pageRef]);//[key intValue];
			for( JAnnotation* ja in pp )
			{
                ja.pageNumber = nPage;
				if ( ja.type == ANNOTATION_NOTE )
				{
/*					PDFAnnotationText* an = [[PDFAnnotationText alloc] initWithBounds:ja.boundary];
					[an setContents:ja.text];
					[an setIconType:kPDFTextAnnotationIconComment];
					[an setColor:[NSColor greenColor]];

					[page addAnnotation:an];*/
                    if ( ja.boundary.origin.x != 2147483648 && ja.boundary.origin.y != 2147483648 )
                        [m_annotations addHighlight:ja toPage:nPage];
				}
				else if ( ja.type == ANNOTATION_FREE_NOTE )
				{
/*					PDFAnnotationFreeText* an = [[PDFAnnotationFreeText alloc] initWithBounds:ja.boundary];
					[an setContents:ja.text];
					[an setColor:[NSColor colorWithRed:NOTE_RED green:NOTE_GREEN blue:NOTE_BLUE alpha:0.5f]];

					[page addAnnotation:an];*/
                    if ( ja.boundary.origin.x != 2147483648 && ja.boundary.origin.y != 2147483648 )
                        [m_annotations addHighlight:ja toPage:nPage];
				}
				else if ( ja.type == ANNOTATION_HIGHLIGHT )
				{
					//PDFAnnotationMarkup* an = [[PDFAnnotationMarkup alloc] initWithBounds:ja.boundary];
					//[an setMarkupType:kPDFMarkupTypeHighlight];
					//[page addAnnotation:an];
                    if ( ja.boundary.origin.x != 2147483648 && ja.boundary.origin.y != 2147483648 )
                        [m_annotations addHighlight:ja toPage:nPage];
				}
				else if ( ja.type == ANNOTATION_UNDERLINE )
				{
					//PDFAnnotationMarkup* an = [[PDFAnnotationMarkup alloc] initWithBounds:ja.boundary];
					//[an setMarkupType:kPDFMarkupTypeUnderline];
					//[an setColor:[NSColor blackColor]];
					//[page addAnnotation:an];
                    if ( ja.boundary.origin.x != 2147483648 && ja.boundary.origin.y != 2147483648 )
                        [m_annotations addHighlight:ja toPage:nPage];
				}
				else if ( ja.type == ANNOTATION_STRIKEOUT )
				{
					//PDFAnnotationMarkup* an = [[PDFAnnotationMarkup alloc] initWithBounds:ja.boundary];
					//[an setMarkupType:kPDFMarkupTypeStrikeOut];
					//[an setColor:[NSColor blackColor]];
					//[page addAnnotation:an];
                    if ( ja.boundary.origin.x != 2147483648 && ja.boundary.origin.y != 2147483648 )
                        [m_annotations addHighlight:ja toPage:nPage];
				}
			}
		}
	}

}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

/*
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
   
//Insert code here to read your document from the given data of the specified type. 
//If outError != NULL, ensure that you create and set an appropriate error when returning NO.
//You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}
*/

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	return nil;
/*	[[Log getLog] addLine:@"JavelinDocument:printOperationWithSettings"];
	//get current view
	NSView *pView = nil;
	NSArray *pa = [self windowControllers];
	if ( pa != nil )
	{
		NSWindowController* pw = nil;
		for( int i=0; i<[pa count]; i++ )
		{
			pw = [pa objectAtIndex:i];
			if ( [pw isKindOfClass:[JavelinController class]] == YES )
			{
				JavelinController *jc = (JavelinController*)pw;
				[[jc javelinView] printJvlnDocument:nil];
				//pView = [jc javelinView];
				
				return nil;
			}
		}
	}*/
	/*
	if ( pView == nil ) return nil;
	
	if ( [self docInfo] != NULL )
	{
		int nPrintCount = [self docInfo]->dwPrintingCount;
		if ( nPrintCount >= 0 )
		{
			//print counter set!
			DocumentRecord *dr = [DocumentDB getDocument:[self docInfo]->dwDocID];
			if ( dr == nil )
			{
				return nil;
			}
		
			int nPrintCountSaved = [dr printCount];
			if ( nPrintCount == 0 || nPrintCountSaved == 0 )
			{
				//unable to print
				if (outError) 
				{
					NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
					[errorDetail setValue:@"ERROR: Printing not enabled!" forKey:NSLocalizedDescriptionKey];
					*outError = [NSError errorWithDomain:@"Javelin" code:-100 userInfo:errorDetail];
				}
				return nil;
			}
			else
			{
				//update print counter
				nPrintCountSaved--;
				[dr setPrintCount: nPrintCountSaved];
				[DocumentDB saveDocRec:dr];
			}
		}
	}

	//print counter not set (or we have a PDF) - allowed to print
	NSPrintInfo *printInfo = [self printInfo];

	NSPrintOperation *po = [NSPrintOperation printOperationWithView:pView
														  printInfo:printInfo];
	DrumlinPrintPanel *dpp = [[DrumlinPrintPanel alloc] init];
	NSPrintPanelOptions opt = [[NSPrintPanel printPanel] options];

	[dpp setOptions:opt];
	[po setPrintPanel:dpp];
	return po;*/
}

- (void) setDocumentInfo: (PDOCEX_INFO)pDocInfo
{
	if ( pDocInfo != NULL )
	{
		size_t i = sizeof( DOCEX_INFO );
		if ( _pDocInfo != NULL ) free( _pDocInfo );
		_pDocInfo = (PDOCEX_INFO)malloc( i );
		
		memcpy( _pDocInfo, pDocInfo, i );
	}
}

- (PDOCEX_INFO) docInfo
{
	return _pDocInfo;
}
/*
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	NSLog(@"DocClose");
	NSArray* cnts = [self windowControllers];
	for( int i=0; i<cnts.count; i++)
	{
		JavelinController* cc = (JavelinController*)[cnts objectAtIndex:i];
		[cc closeDrawer];
	}
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (void) close
{
	NSLog(@"isClosed=YES");
	
	isClosed = YES;
	m_document = nil;
	m_docURL = nil;

	[super close];
}
*/
-(BOOL)isClosed
{
	return isClosed;
}

- (BOOL) isDrm
{
	return m_boolDrm;
}

- (unsigned int) documentID
{
	if ( _pDocInfo != nil )
		return _pDocInfo->dwDocID;
	
	return 0;
}

- (BOOL) printingEnabled
{
	if ( _pDocInfo != nil )
	{
		BOOL bOK = (_pDocInfo->dwPagesToPrint >0)&&(_pDocInfo->dwPrintingCount > 0 );
		return bOK;
	}

	return YES;
}
@end
