//
//  JavelinController.m
//  Javelin
//
//  Created by harry on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JavelinController.h"
#import "Drumlin.h"
//#import "AuthController.h"
#import "DocumentDB.h"
#import "General.h"
#import "Log.h"
#import "PropertiesController.h"
#import "JavelinDocument.h"
#import "Version.h"
#import "VarSystemInfo.h"
#import "Note.h"
#import "JavelinApplication.h"
#import "FreeNoteWindow.h"
#import "FreeNoteController.h"
#import "SearchController.h"
#import "MyThumbnailView.h"
#import "JAnnotation.h"
#import "JAnnotations.h"
#import "JavelinNotes.h"
#import "XmlParser.h"
#import "DocumentList.h"
#import "ActivityManager.h"

//#import "NewThumbItem.h"

//#define HIDE_THUMBNAILS		(1)
//#define NEW_THUMBS	(1)

static NSString *ToolbarBackForward					= @"Back Forward";
static NSString *ToolbarNavigation                  = @"Page Navigation";
//static NSString *ToolbarPreviousPage				= @"Previous Page";
//static NSString *ToolbarNextPage					= @"Next Page";
static NSString *ToolbarPageNumber					= @"Page Number";
static NSString *ToolbarPageCount					= @"Page Count";
static NSString *ToolbarSearch						= @"Search";
static NSString *ToolbarViewMode					= @"View Mode";  
static NSString *ToolbarToggleDrawer				= @"ToggleDrawer";
static NSString *ToolbarZoomInOut                   = @"Zoom In/Out";
static NSString *ToolbarDownload					= @"Download";
static NSString *TooolbarFindText					= @"Find Text";
static NSString *ToolbarRotateLeft					= @"RotateLeft";

static NSString *selectionIndexPathsKey = @"selectionIndexPaths";

@implementation JavelinController


+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	
	[DocumentDB displayEntries];
}

- (id) init
{
    self = [super initWithWindowNibName:@"JavelinDocument"];
	if ( self )
	{
        m_documentID = 0;
		//[[Log getLog] addLine:@"Controller initialised"];
		m_docUrl = nil;
		m_searchController = nil;
		m_bWarningDisplayed = NO;
		
	}
    return self;
}

- (void)receivedNotificationTerminalRunning:(NSNotification *) notification {
	if ([[notification name] isEqualToString:@"terminal_running"]) 
	{
//		int nDocID = [[[self _pdfView] JavelinDocument] m_documentID];
		PDOCEX_INFO pDocInfo = [_pdfView.javelinDocument docInfo];
		if ( pDocInfo != nil )
		{
			//NSLog(@"JavelinController - bad process running DRMZ DocID:[%d]", pDocInfo->dwDocID);
			[[Log getLog] addLine:[NSString stringWithFormat:@"Terminal is running. The document ID:%d", pDocInfo->dwDocID]];
			//[self close];//close - don't save

			//[self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
			[self closeAndDisplayWarning];
		}
		else
			NSLog(@"JavelinController - terminal running PDF [%@]", [_pdfView.javelinDocument DocumentURL]);
	}
}

-(void)closeAndDisplayWarning
{
	JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
	if ( [pApp isTerminalRunning])
	{
		[self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
		dispatch_async(dispatch_get_main_queue(), ^
		{
		   JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
		   [pApp displayTerminalWarning];
		});
	}
	else
		[self performSelectorOnMainThread:@selector(terminalWarning) withObject:nil waitUntilDone:YES];
}

-(void)closeAndDisplayCodeWarning:(unsigned int)docID
{
	//[self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[self close];
		JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
		[pApp displayCodeWarning:docID];
	});
}


-(void)terminalWarning
{
	if ( m_bWarningDisplayed == YES )
		return;
	
	if ( _pdfView != nil )
	{
		JavelinDocument* doc = _pdfView.javelinDocument;
		
		if ( doc != nil )
		{
			PDOCEX_INFO pDocInfo = [doc docInfo];
			if ( pDocInfo != nil )
			{
				if ( pDocInfo->sBlockGrabbers )
				{
					// Replacement for alertWithMessageText:defaultButton:alternateButton:otherButton:informativeTextWithFormat:
					NSAlert *alert = [[NSAlert alloc] init];
					JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
					[alert setMessageText:[NSString stringWithFormat:@"WARNING: %@ is running!", [pApp isBadProcessRunning]]];
					[alert addButtonWithTitle:@"OK"];
					[alert addButtonWithTitle:@"Close document"];
					[alert addButtonWithTitle:@"Bring suspicious process to front"];
					[alert setInformativeText:[NSString stringWithFormat:@"Please close %@ application.\nClose the current document.\nOr close suspicious process", [pApp isBadProcessRunning]]];
					//NSLog(@"About to display ALERT");
					m_bWarningDisplayed = YES;
					[alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
						if ( result == NSAlertSecondButtonReturn )
						{
							[self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
						}
						else if ( result == NSAlertThirdButtonReturn )
						{
							[self performSelectorOnMainThread:@selector(closeProcess:) withObject:[pApp isBadProcessRunning] waitUntilDone:YES];
						}
						m_bWarningDisplayed = NO;
					}];

				}
			}
		}
	}	
}

- (void) closeProcess:(NSString*)sName
{
	if ( sName != nil )
	{
		//NSArray<NSRunningApplication *> *apps = [NSWorkspace runningApplications];
		NSArray<NSRunningApplication*> *apps = 
			[NSRunningApplication runningApplicationsWithBundleIdentifier:sName];
	
		if ( apps != nil && apps.count > 0 )
		{
			NSRunningApplication* app = apps[0];

			if ( app != nil )
			{
				//pid_t pid = [app processIdentifier];
				//[app forceTerminate];
				//killpg(getpgid(pid), SIGTERM);
				[app activateWithOptions:NSApplicationActivateAllWindows];
			}
		}
	}
}	


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        m_documentID = 0;
		//[[Log getLog] addLine:@"Controller initialised"];
		m_docUrl = nil;
		m_searchController = nil;
		
		JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
		[pApp hideWarning];
    }
    
	//- (NSURL *)URLForDirectory:(NSSearchPathDirectory)directory inDomain:(NSSearchPathDomainMask)domain appropriateForURL:(NSURL *)url create:(BOOL)shouldCreate error:(NSError * _Nullable *)error;
/*	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray<NSURL*>* mm = nil;
	mm = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	NSURL* myURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	int i = 100;
	i++;
	
	NSString *directory = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources"];
	
	NSArray *files=[fm contentsOfDirectoryAtPath:directory error:nil];
	NSLog(@"mag1 directory: %@",files);*/
    return self;
}
/*
- (JavelinPdfView*)javelinView
{
	return _pdfView;
}
*/
/*
- (void)dealloc
{
    // No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    // Release outline.
	if (_outline)
		[_outline release];
	_outline = nil;
	
	if (_pdfView)
		[_pdfView release];
	
	//NSString* sss = [NSString stringWithFormat:@"Count=%d", [_pdfView retainCount]];
	//NSLog(@"%@", sss);
	_pdfView = nil;
	
	//[[Log getLog] writeToLogFile:@""];
	
	if ( m_docUrl != nil ) [m_docUrl release];
	[super dealloc];
}
*/
- (BOOL) openPdfFile:(NSURL *)url
{
    NSFileManager *fm;
    NSData *data;
    
    fm = [NSFileManager defaultManager];
    //[[Log getLog] addLine:[NSString stringWithFormat:@"fm=%@", fm ] ];
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
		//[[Log getLog] addLine:@"File exists"];
        data = [[fm contentsAtPath:[url path]] copy];
		//[[Log getLog] addLine:[NSString stringWithFormat:@"data=%@", (data==nil?@"isNULL":@"OK") ] ];
        BOOL res = [self openPdfDocumentFromData:data];
		
	    //[[Log getLog] addLine:[NSString stringWithFormat:@"res=%d", res ] ];
		
		if ( res == YES )
		{
			m_docUrl = url;
			////[_thumbs setPDFView:_pdfView];
			//[[Log getLog] addLine:[NSString stringWithFormat:@"Opened PDF file: %@", m_docUrl]];
		}
		else
		{
			//[[Log getLog] addLine:@"ERROR: Unable to open PDF file"];
			//[data release];
		}
        return res;
    }
    
    return NO;
}

- (BOOL) openDrmxFile:(NSURL *)url
{
    NSFileManager *fm;
    NSData *data;
	NSError* pError = nil;
    
	
	[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile:%@",[[self document] fileURL]]];
	
    fm = [NSFileManager defaultManager];

RE_AUTHORISE:
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
		[[Log getLog] addLine:@"DBG: openDrmxFile - file OK"];
		
        data = [fm contentsAtPath:[url path]];
        BOOL res = [self openDrmxDocumentFromData:data error:&pError];
		
		if ( res == YES )
		{
			m_docUrl = url;
			[[Log getLog] addLine:[NSString stringWithFormat:@"Opened DRMX file: %@", m_docUrl]];

			return YES;
		}
    }
    
	if ( pError != nil && ([pError code] == -110 || [pError code] == -113 || [pError code] == -11 || [pError code] == -5 || [pError code] == -6) )
	{
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile: ERROR CODE: %ld",(long)[pError code]]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: openDrmxFile: ERROR DESC: %@",[pError localizedDescription]]];
		
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
	[d setWindow:[self window]];
	
	NSData *pDoc = nil;
	
	@try{
		[[Log getLog] addLine:@"DBG: openDrmxDocumentFromData: about to call openDrmxFileFromData"];
		pDoc = [d openDrmxFileFromData: data error:ppError];
		m_documentID = [d getDocID];
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
		PDFDocument* pdfDoc = [[PDFDocument alloc] initWithData: pDoc];
		//JavelinDocument* pdfDoc = [[JavelinDocument alloc] initWithData: pDoc];
		if ( pdfDoc != nil )
		{
			@try{
				bool res = [self openDoc:pdfDoc withDocInfo:[d docInfo] authCode:[d getAuthCode]];

				return res;
			}
			@catch( NSException *pex ){
				//NSLog( @"%@", [pex description] );
				return NO;
			}
			@finally{
				//[d release];
			}
		}
	}
	else
	{
		[[Log getLog] addLine:@"DBG: openDrmxDocumentFromData: Unable to open document"];
	}
	//[d release];
	return NO;
}

/*
 Opens a PDF document form a memory buffer (NSData*)
 */
- (BOOL)openPdfDocumentFromData: (NSData*)data
{
    PDFDocument	*pdfDoc;
    // Create PDFDocument.
	if (data != nil )
	{
		pdfDoc = [[PDFDocument alloc] initWithData: data];
	}
	else
	{
		pdfDoc = [[PDFDocument alloc] init];

	}
	
	if ( pdfDoc != nil )
	{
		//[[Log getLog] addLine:[NSString stringWithFormat:@"pdfDoc=%@", pdfDoc]];
		BOOL b = [self openDoc:pdfDoc withDocInfo:NULL authCode:nil];
		
		//[pdfDoc release];//22052012
		return b;
	}
/*	NSRect rect = [[[self window] contentView] bounds];
	rect.size.height += 1;
	rect.size.width += 1;
	[[[self window] contentView] setBounds:rect];
	rect.size.height -= 1;
	rect.size.width -= 1;
	[[[self window] contentView] setBounds:rect];
	[[[self window] contentView] setNeedsLayout:YES];
	*/
	[[Log getLog] addLine:@"ERROR: Unable to read document"];
	return NO;
}


-(void)setupNewThumbs
{
#ifdef NEW_THUMBS
	//NSCollectionViewLayout *layout = nil;
	NSCollectionViewFlowLayout* layout = nil;
	layout = [[NSCollectionViewFlowLayout alloc] init];
	[layout setItemSize:NSMakeSize(150, 212)];
	[layout setMinimumInteritemSpacing:20];
	[layout setMinimumLineSpacing:20];
	[layout setSectionInset:NSEdgeInsetsMake(10, 20, 10, 20)];
	[m_newThumbs setCollectionViewLayout:layout];
	
	//[m_newThumbs setDelegate:self];
	[m_newThumbs setDataSource:self];
	[m_newThumbs setSelectable:YES];
	
	[m_newThumbs addObserver:self forKeyPath:selectionIndexPathsKey options:0 context:NULL];
#endif
}

#ifdef NEW_THUMBS
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == m_newThumbs && [keyPath isEqual:selectionIndexPathsKey]) {
        
        /*
            We're being notified that our imageCollectionView's
            "selectionIndexPaths" property has changed.  Update our status
            TextField with a summary (item count) of the new selection.
        */
        //NSSet<NSIndexPath *> *newSelectedIndexPaths = imageCollectionView.selectionIndexPaths;
        //[self showStatus:[NSString stringWithFormat:@"%lu items selected", (unsigned long)(newSelectedIndexPaths.count)]];
		NSArray<NSIndexPath *> *selected = m_newThumbs.selectionIndexPaths.allObjects;
		//NSLog(@"Selected: %lu", (unsigned long)selected.count);
		int n = (int)selected.firstObject.item;
		PDFPage* page = [[_pdfView document] pageAtIndex: n];
		[_pdfView goToPage:page];
    }
}
#endif

-(void)setupMyView:(PDOCEX_INFO)pDocInfo withAuthCode:(NSString*)authCode
{
	if ( pDocInfo != NULL )
	{
		if ( pDocInfo->szWMText != NULL )
		{
			[_pdfView setWatermark:pDocInfo authCode:authCode];
		}
	}
	[_pdfView setAutoScales: YES];
	[_pdfView setDisplaysPageBreaks: NO];

    NSTabView *myTabView = (NSTabView*)[[[[self window] drawers] objectAtIndex: 0] contentView];
	//[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:2]];//remove bookmarks (not implemented!)

#ifdef HIDE_THUMBNAILS
	[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:2]];
	[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:1]];//remove thumbnails
	
#endif

#ifdef NEW_THUMBS
	[self setupNewThumbs];
#endif
	//NSLog(@"SIZE: H:%f W:%f",[_thumbs thumbnailSize].height, [_thumbs thumbnailSize].width);
	//[_thumbs setThumbnailSize:NSMakeSize(100, 300)];

	_outline = [[_pdfView document] outlineRoot];
	if (_outline)
	{
		if ([[_pdfView document] isLocked] == NO)
		{
            [_outlineView reloadData];
            [_outlineView setAutoresizesOutlineColumn: YES];
			
			// Expand items.
            if ([_outlineView numberOfRows] == 1)
            	[_outlineView expandItem: [_outlineView itemAtRow: 0] expandChildren: NO];
            [self updateOutlineSelection];
			
			// Always open drawer if there is an outline and unencrypted PDF.
			[[[[self window] drawers] objectAtIndex: 0] open];
		}
	}
	else
	{
		int nNumber = (int)[myTabView numberOfTabViewItems];
		////[_thumbs setPDFView:_pdfView];
		[[[[self window] drawers] objectAtIndex: 0] open];
		
		if ( nNumber > 0 )
		{
			[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:0]];//remove outline (doesn't exist)
		}
	}
	////[_thumbs setPDFView:_pdfView];
	[_pdfView setNeedsDisplay:YES];
	[_pdfView setNeedsLayout:YES];
}

- (BOOL) openDoc:(PDFDocument*)pdfDoc 
	 withDocInfo:(PDOCEX_INFO)pDocInfo 
	 authCode:(NSString*)authCode
{
    // Set document.
	//[[Log getLog] addLine:@"1"];
	[_pdfView setDocument:pdfDoc];
	//[[Log getLog] addLine:@"2"];
	if ( pDocInfo != NULL )
	{
			//[[Log getLog] addLine:@"21"];
		if ( pDocInfo->szWMText != NULL )
		{
				//[[Log getLog] addLine:@"22"];
/*			[_pdfView setWatermark:(const unsigned char *)pDocInfo->szWMText 
							  type:(int)pDocInfo->sWMType 
						forDocName:(const unsigned char *)pDocInfo->szDocName 
							 ID:(unsigned int)pDocInfo->dwDocID
						  authCode:(NSString*)authCode];*/
			[_pdfView setWatermark:pDocInfo authCode:authCode];
		}
	}
	//[[Log getLog] addLine:@"3"];
	JavelinDocument* jd = (JavelinDocument*)[self document];
	[jd setDocumentInfo:pDocInfo];
	//[[Log getLog] addLine:@"4"];
	[_pdfView setJavelinDocument:jd];
	[_pdfView setMenu:nil];
	//[[Log getLog] addLine:@"5"];
	//[pdfDoc release];//?????
	
	// Default display mode.
	[_pdfView setAutoScales: YES];
	[_pdfView setDisplaysPageBreaks: NO];
	//[[Log getLog] addLine:@"6"];
    NSTabView *myTabView = (NSTabView*)[[[[self window] drawers] objectAtIndex: 0] contentView];
	[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:2]];//remove bookmarks (not implemented!)
	//[[Log getLog] addLine:@"7"];

	// Get outline (if any).
	_outline = [[_pdfView document] outlineRoot];
	if (_outline)
	{
			//[[Log getLog] addLine:@"71"];
		if ([[_pdfView document] isLocked] == NO)
		{
				//[[Log getLog] addLine:@"72"];
            [_outlineView reloadData];
            [_outlineView setAutoresizesOutlineColumn: YES];
			
			// Expand items.
            if ([_outlineView numberOfRows] == 1)
            	[_outlineView expandItem: [_outlineView itemAtRow: 0] expandChildren: NO];
            [self updateOutlineSelection];
			
			// Always open drawer if there is an outline and unencrypted PDF.
			[[[[self window] drawers] objectAtIndex: 0] open];
		}
	}
	else
	{
			//[[Log getLog] addLine:@"711"];
		int nNumber = (int)[myTabView numberOfTabViewItems];
		////[_thumbs setPDFView:_pdfView];
		//[_thumbs acceptsFirstResponder];
		[[[[self window] drawers] objectAtIndex: 0] open];
		
		if ( nNumber > 0 )
		{
			[myTabView removeTabViewItem:[myTabView tabViewItemAtIndex:0]];//remove outline (doesn't exist)
		}
	}
		//[[Log getLog] addLine:@"8"];
	[_pdfView setNeedsDisplay:YES];
	[_pdfView setNeedsLayout:YES];

    return YES;
}

/*
- (BOOL)shouldCloseDocument
{
	//[[[[self window] drawers] objectAtIndex: 0] closeDrawer];
	[_drawer close];
	_outlineView = nil;
	NSLog(@"CLOSE");
//	[[_pdfView window] makeFirstResponder:self];
	return YES;
}
*/

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	m_oldDisplayMode = kPDFDisplaySinglePage;
	
	//NSLog(@"%@",[[[NSFontManager sharedFontManager] availableFontFamilies] description]);
//
//	VarSystemInfo* v = [[VarSystemInfo alloc] init];
//	[[Log getLog] addLine:[v sysFullUserName]];
//	[[Log getLog] addLine:[v sysModelID]];
//	[[Log getLog] addLine:[v sysModelName]];
//	[[Log getLog] addLine:[v sysOSName]];
//	[[Log getLog] addLine:[v sysOSVersion]];
//	[[Log getLog] addLine:[v sysPhysicalMemory]];
//	[[Log getLog] addLine:[v sysProcessorName]];
//	[[Log getLog] addLine:[v sysProcessorSpeed]];
//	[[Log getLog] addLine:[v sysSerialNumber]];
//	[[Log getLog] addLine:[v sysUserName]];
//	[[Log getLog] addLine:[v sysUUID]];
	
//	[v release];
	
	//[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: windowDidLoad:%@",[[self document] fileURL]]];
	
    //NSString *s = [[self document] fileType];
    //BOOL bRes = NO;
/*
    if ( [s caseInsensitiveCompare:@"PDF document"] == NSOrderedSame )
	{
		//[[Log getLog] addLine:@"Opening a PDF document"];
        bRes = [self openPdfFile:[[self document] fileURL]];
		//[[Log getLog] addLine:@"PDF doc opened"];
	}
    else if ( [s caseInsensitiveCompare:@"Javelin document"] == NSOrderedSame )
	{
        bRes = [self openDrmxFile:[[self document] fileURL]];
	}
    else if ( [s caseInsensitiveCompare:@"Javelin Document Simple"] == NSOrderedSame )
	{
        bRes = [self openDrmxFile:[[self document] fileURL]];
	}
    else
	{
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: Error: %@", s]];
		return;
    }
    if ( bRes == NO )
	{
		[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: Error loading document:%@",[[self document] fileURL]]];
		[[self window] close];
		return; //error while opening file!
	}
*/
	//[[Log getLog] addLine:@"DBG: doc loaded OK"];
	//[self performSelector:@selector(doLoad) withObject:nil afterDelay:2.0f];
	//[self doLoad];
	//
	//
	//	[[Log getLog] addLine:[NSString stringWithFormat:@"Loaded file:%@",[[self document] fileURL]]];
	// How big to create the window?
	// Visible frame for main screen.
	
	// Create toolbar.
	[self setupToolbarForWindow: [self window]];
	
	// Internal notification.
//	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(newActiveAnnotation:) 
//                                                 name: @"newActiveAnnotation" object: _pdfView];

	[_pdfView setDocument: [[self document] pdfDocument]];
	[_pdfView setDelegate:self];//NoteProtocol
	
	JavelinDocument* jd = (JavelinDocument*)[self document];
	[_pdfView setJavelinDocument:jd];
	
	// Establish notifications for this document.
	[self setupDocumentNotifications];
	[self setShouldCloseDocument: YES];


	[self setupMyView:[jd docInfo] withAuthCode:[jd authCode]];
	
	////[[_pdfView window] makeKeyAndOrderFront:self];
	[_pdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[_pdfView setAutoresizesSubviews:YES];
	
	[_outlineView setDataSource:self];
	[_outlineView setDelegate:self];


//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:_pdfView];
//	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowWillClose:)
//                                               name: NSWindowWillCloseNotification object: _pdfView];

	[self.window setDelegate:self];
	
	self.window.titleVisibility = NSWindowTitleVisible;
	self.window.backgroundColor = NSColor.blackColor;
	
		NSRect visibleScreen = [[NSScreen mainScreen] visibleFrame];
	
	// Taking into account the toolbars, etc. in the UI.
	visibleScreen.size.width -= kPDFViewXDelta;
	visibleScreen.size.height -= kPDFViewYDelta;
    
	// If continuous and multi-page, subtract space for a vertical scrollbar.
	if ((([_pdfView displayMode] & 0x01) == 0x01) && ([[_pdfView document] pageCount] > 1))
		visibleScreen.size.width -= [NSScroller scrollerWidth];
	
	// Page size.
	NSSize pageSize = [_pdfView rowSizeForPage: [_pdfView currentPage]];
	
	// Determine limiting scale factor.
	float scaleFactor = visibleScreen.size.width / pageSize.width;
	if (visibleScreen.size.height / pageSize.height < scaleFactor)
		scaleFactor = visibleScreen.size.height / pageSize.height;
	
	// Scale bounds.
	pageSize.width = floorf(pageSize.width * scaleFactor);
	pageSize.height = floorf(pageSize.height * scaleFactor);
	
	if ( pageSize.width <= 0 ) pageSize.width = 300;
	if ( pageSize.height <= 0 ) pageSize.height = 300;
	
	// Set the window size.
	[[self window] setContentSize: pageSize];
	
	//[[Log getLog] addLine:[NSString stringWithFormat:@"window:%@ size:%@", [self window], NSStringFromSize(pageSize)]];
	
	// Close the search results.
	[self setSearchResultsViewHeight: 0];

	[_pageNumberView setStringValue:@"1"];
	_pageCount.integerValue =  [[_pdfView document] pageCount];
	JavelinApplication* pApp = (JavelinApplication*)[NSApplication sharedApplication];
	[pApp enableRemovingAuth:[[self document] isDrm]];
	if ( [[self document] isDrm] )
	{
		[pApp setCurrentDocumentID:[[self document] documentID]];
		//check Terminal app only for protected files
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(receivedNotificationTerminalRunning:)
													 name:@"terminal_running"
												   object:nil];
		NSString* sDocID = [NSString stringWithFormat:@"%u", [jd documentID]];
		[self checkCode:[jd authCode] docID:sDocID];

	}
	else
	{
		[pApp setCurrentDocumentID:0];
	}
	
/*	NSMenu* pMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem* pPrint = nil;
	NSMenuItem* pFile = [pMenu itemAtIndex:1];
	if ( pFile != nil )
	{
		NSMenu* sSub = [pFile submenu];
		pPrint = [sSub itemWithTag:9999];
	}
	if ( pPrint != nil )
	{
		BOOL bEnable = [[self document] printingEnabled];
		[pPrint setEnabled:bEnable];
	}*/
	//[_drawer close];
	
//	[_pdfView setNeedsDisplay:YES];
//	[_pdfView setNeedsLayout:YES];
	
//	[_pdfView zoomIn:self];
//	[_pdfView zoomOut:self];

	m_wndFreeNote = [[FreeNoteWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0) styleMask:NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	//[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0) styleMask:NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[m_wndFreeNote setBackgroundColor:[NSColor whiteColor]];
	[m_wndFreeNote setHidesOnDeactivate:YES];
	[m_wndFreeNote setBecomesKeyOnlyIfNeeded:YES];
	[m_wndFreeNote setCanHide:YES];
	[m_wndFreeNote createWnd];
	
//	[m_wndFreeNote setFloatingPanel:YES];
//	[m_wndFreeNote setShowsResizeIndicator:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteDidResize:) name:NSWindowDidResizeNotification object:m_wndFreeNote];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteDidResignMain:) name:NSWindowDidResignMainNotification object:m_wndFreeNote];
	
	
	m_ctrlNote = [[FreeNoteController alloc] initWithWindowNibName:@"FreeNoteController" ];
	[[m_ctrlNote window] setMinSize:NSMakeSize(200, 100)];
	
    //[m_notes setPdfView:_pdfView];
    [m_notes setDataSource:self];
    [m_notes setDelegate:self];
    [m_notes setNoteViewDelegate:_pdfView];
    
	//goto a page
	NSString* sDoc = _pdfView.javelinDocument.fileURL.filePathURL.absoluteString;
	int nPage = [[General documentList] getPageForDocument:sDoc];
	if ( nPage != -1 )
	{
		[_pdfView goToPage: [[_pdfView document] pageAtIndex:nPage - 1]];
	}
}

//2019-12-27 check current code
-(void)checkCode:(NSString*)sCode docID:(NSString*)sDocID
{
	if ( [sCode isEqualToString:@"self_auth"] )
		return;
	
	dispatch_queue_t queue = dispatch_queue_create("uk.co.drumlinsecurity.Javelin3", NULL);
	dispatch_async(queue, ^{
		//code to be executed in the background

		NSString *sTemp = nil;
		
		NSMutableString *sRequest = [[NSMutableString alloc]init];

		//create soap envelope
		[sRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
		[sRequest appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
		[sRequest appendString:@"<soap:Body>"];
		[sRequest appendString:@"<CheckCode xmlns=\"http://drumlinsecurity.co.uk/\">"];
		
		sTemp = [NSString stringWithFormat:@"<nDocID>%@</nDocID>", sDocID ];
		[sRequest appendString:sTemp];
		
		sTemp = [NSString stringWithFormat:@"<sCode>%@</sCode>", sCode ];
		[sRequest appendString:sTemp];
		
		[sRequest appendString:@"</CheckCode>"];
		[sRequest appendString:@"</soap:Body>"];
		[sRequest appendString:@"</soap:Envelope>"];
		
		//NSLog(@"%@", sRequest);
		NSURL *myWebserverURL = [NSURL URLWithString:@"http://www.drumlinsecurity.co.uk/Service.asmx"];
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL]; 
		
		[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
		[request addValue:@"http://drumlinsecurity.co.uk/CheckCode" forHTTPHeaderField:@"SOAPAction"];//this is default tempuri.org, I changed mine in the project
		
		NSString *contentLengthStr = [NSString stringWithFormat:@"%ld", (unsigned long)[sRequest length]];
		
		[request addValue:contentLengthStr forHTTPHeaderField:@"Content-Length"];
		// Set the action to Post
		[request setHTTPMethod:@"POST"];
		// Set the body
		[request setHTTPBody:[sRequest dataUsingEncoding:NSUTF8StringEncoding]];

		NSError *WSerror;
		NSURLResponse *WSresponse;
		// Execute the asp.net Service and return the data in an NSMutableData object
		NSData *d = [NSURLConnection sendSynchronousRequest:request returningResponse:&WSresponse error:&WSerror]; 
		
		XmlParser *xmlParser = [[XmlParser alloc] initWithName:@"CheckCodeResponse"];
		
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:d];
		[parser setDelegate:xmlParser];
		[parser setShouldProcessNamespaces:NO];
		[parser setShouldReportNamespacePrefixes:NO];
		[parser setShouldResolveExternalEntities:NO];
		[parser parse];
		
		if ( xmlParser.result == nil )
		{
			return;
		}
		
		NSMutableDictionary *res1 = xmlParser.result;
		
		NSDictionary *res = [self getWSResponse:res1];
		
		//NSLog( @"WS Response: %@", res );
		
		NSString* sError = [res objectForKey:@"sError"];
		NSString* sCodeResult = [res objectForKey:@"CheckCodeResult"];
		
		if ( [ sCodeResult isEqualToString:@"-3" ] )
		{
			[[Log getLog] addLine:sError];
			unsigned int docID = (unsigned int)[sDocID intValue];
			[self closeAndDisplayCodeWarning:docID];
		}
		return;
	});
}


-(NSDictionary*) getWSResponse: (NSDictionary*)dict
{
	NSEnumerator *e = [dict keyEnumerator];
	for( NSString* s in e )
	{
		id node = [dict objectForKey: s];
		if ( [node isKindOfClass:[NSDictionary class]] )
		{
			NSDictionary* d = (NSDictionary*)node;
			return [self getWSResponse: d];
		}
		return dict;
	}
	
	return nil;
}


-(void)noteDidResize:(id)sender
{
	NSRect rect = [m_wndFreeNote frame];
	if ( rect.size.width > 5 || rect.size.height > 5 )
	{
		
	}
}

-(void)noteDidResignMain:(id)sender
{
	//NSLog(@"Did resign main");
}


- (void)windowDidExpose:(NSNotification *)notification
{
	//NSLog(@"Expose");
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{//
	//id ooo = [notification object];
	
	//NSLog(@"Becomes Key %@", NSStringFromClass( [ooo class] ) );
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	//id ooo = [notification object];
	//NSLog(@"Resign Key %@", NSStringFromClass( [ooo class] ) );
	[m_wndFreeNote setFrame:NSMakeRect(0, 0, 0, 0) display:NO];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	//id ooo = [notification object];
	
	//NSLog(@"Becomes Main %@", NSStringFromClass( [ooo class] ) );
	[m_ctrlNote close];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	id ooo = [notification object];
	//NSLog(@"Resign Main %@", NSStringFromClass( [ooo class] ) );
}

#pragma mark -------- NSOutlineViewDataSource Protocol
// ----------------------------------------------------------------------------------- outlineView:numberOfChildrenOfItem

- (NSInteger) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
    if ([outlineView isKindOfClass:[JavelinNotes class]])
    {
        if ( item == nil )
        {
            if ( [[_pdfView javelinDocument] annotations] == nil )
                return 0;
            else
                return [[[_pdfView javelinDocument] annotations] numberOfPages];//root element count
        }
        else
            return [item count];//element count of one item in list
    }
    else
    {
        if (item == NULL)
        {
            if ((_outline) && ([[_pdfView document] isLocked] == NO))
                return (int)[_outline numberOfChildren];
            else
                return 0;
        }
        else
            return (int)[(PDFOutline *)item numberOfChildren];
    }
}


// --------------------------------------------------------------------------------------------- outlineView:child:ofItem

- (id) outlineView: (NSOutlineView *) outlineView child: (NSInteger) index ofItem: (id) item
{
    if ([outlineView isKindOfClass:[JavelinNotes class]])
    {
        if ( item == nil )
        {
            if ([[_pdfView javelinDocument] annotations] == nil )
                return nil;
            
            return [[[_pdfView javelinDocument] annotations] notesForIndex:index];
        }
        return [item objectAtIndex:index];
    }
    else
    {
        if (item == NULL)
        {
            if ((_outline) && ([[_pdfView document] isLocked] == NO))
                return [_outline childAtIndex: index];
            else
                return NULL;
        }
        else
            return [(PDFOutline *)item childAtIndex: index];
    }
}

// ----------------------------------------------------------------------------------------- outlineView:isItemExpandable

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    if ([outlineView isKindOfClass:[JavelinNotes class]])
    {
        if ( [item isKindOfClass:[NSArray class]])
            return YES;
        
        return NO;
    }
    else
    {
        if (item == NULL)
        {
            if ((_outline) && ([[_pdfView document] isLocked] == NO))
                return ([_outline numberOfChildren] > 0);
            else
                return NO;
        }
        else
            return ([(PDFOutline *)item numberOfChildren] > 0);
    }
}

// ------------------------------------------------------------------------- outlineView:objectValueForTableColumn:byItem

- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn 
            byItem: (id) item
{
    if ([outlineView isKindOfClass:[JavelinNotes class]])
    {
        if ( item == nil )
            return nil;
        
        if ( [item isKindOfClass:[NSArray class]])
        {
            if ( [item count] > 0 )
            {
                JAnnotation* ann1 = [item objectAtIndex:0];
                return [NSString stringWithFormat:@"Page %d", [ann1 pageNumber]];
            }
            return nil;
        }
        JAnnotation* ann = (JAnnotation*)item;
        switch( [ann type])
        {
            case ANNOTATION_NOTE:
                if ( [[ann text] length] > 15 )
                    return [NSString stringWithFormat:@"%@", [[ann text] substringToIndex:15]];
                else
                    return [NSString stringWithFormat:@"%@",[ann text]];
                break;
                
            case ANNOTATION_HIGHLIGHT:
                return @"Highlight";
                break;
                
            case ANNOTATION_STRIKEOUT:
                return @"Strikeout";
                break;
                
            case ANNOTATION_UNDERLINE:
                return @"Underline";
                break;
                
            default:
                return @"error";
                break;
        }
    }
    else
    {
        if ( _outlineView != nil )
            return [(PDFOutline *)item label];
        return nil;
    }
}

#pragma mark -------- NSOutlineViewDelegate Protocol
// ---------------------------------------------------------------------------------------- outlineViewSelectionDidChange

- (void) outlineViewSelectionDidChange: (NSNotification *) notification
{
    if ([[notification object] isKindOfClass:[JavelinNotes class]])
    {
        int nPage = [m_notes selectedRow];
        id ooo = [m_notes itemAtRow:nPage];
        JAnnotation* ann = nil;
        if ( [ooo isKindOfClass:[NSArray class]])
        {
            ann = (JAnnotation*)[ooo objectAtIndex:0];
        }
        else
        {
            ann = (JAnnotation*)ooo;
        }
        [_pdfView goToPage: [[_pdfView document] pageAtIndex: [ann pageNumber]-1]];
        
        int n = 100;
        n++;
    }
    else
    {
        // Get the destination associated with the search result list. Tell the PDFView to go there.
        if (([notification object] == _outlineView) && (_ignoreNotification == NO))
            [_pdfView goToDestination: [[_outlineView itemAtRow: [_outlineView selectedRow]] destination]];
    }
}

// --------------------------------------------------------------------------------------------- outlineViewItemDidExpand

- (void) outlineViewItemDidExpand: (NSNotification *) notification
{
    if ([[notification object] isKindOfClass:[JavelinNotes class]])
    {
    }
    else
    {
        [self updateOutlineSelection];
    }
}

// ------------------------------------------------------------------------------------------- outlineViewItemDidCollapse

- (void) outlineViewItemDidCollapse: (NSNotification *) notification
{
    if ([[notification object] isKindOfClass:[JavelinNotes class]])
    {
    }
    else
    {
        [self updateOutlineSelection];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

// ----------------------------------------------------------------------------------------------- updateOutlineSelection

- (void) updateOutlineSelection
{
	PDFOutline	*outlineItem;
	int			pageIndex;
//	int			numRows;
	
	// Skip out if this PDF has no outline.
	if (_outline == NULL)
		return;
	
	// Get index of current page.
	pageIndex = (int)[[_pdfView document] indexForPage: [_pdfView currentPage]];
	
	// Test that the current selection is still valid.
	outlineItem = (PDFOutline *)[_outlineView itemAtRow: [_outlineView selectedRow]];
	if ([[_pdfView document] indexForPage: [[outlineItem destination] page]] == pageIndex)
		return;
	
	// Walk outline view looking for best firstpage number match.
//	numRows = (int)[_outlineView numberOfRows];
/*	for (i = 0; i < numRows; i++)
	{
		// Get the destination of the given row....
		outlineItem = (PDFOutline *)[_outlineView itemAtRow: i];
		
		if ([[_pdfView document] indexForPage: [[outlineItem destination] page]] == pageIndex)
		{
			_ignoreNotification = YES;
			[_outlineView selectRow: i byExtendingSelection: NO];
			_ignoreNotification = NO;
			break;
		}
		else if ([[_pdfView document] indexForPage: [[outlineItem destination] page]] > pageIndex)
		{
			_ignoreNotification = YES;
			if (i < 1)				
				[_outlineView selectRow: 0 byExtendingSelection: NO];
			else
				[_outlineView selectRow: i - 1 byExtendingSelection: NO];
			_ignoreNotification = NO;
			break;
		}
	}*/
}

- (void) setupDocumentNotifications
{
	// Find notifications.
	
/*	PDFDocument* doc = [[self document] pdfDocument];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startFind:)
                                                 name: PDFDocumentDidBeginFindNotification object: doc];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endFind:) 
                                                 name: PDFDocumentDidEndFindNotification object: doc];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(startPage:)
                                                 name: PDFDocumentDidBeginPageFindNotification object: doc];
												 //[_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(endPage:) 
                                                 name: PDFDocumentDidEndPageFindNotification object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didMatchString:)
                                                 name: PDFDocumentDidFindMatchNotification object: [_pdfView document]];
*/
	
/*	// Document saving progress notifications.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentBeginWrite:) 
                                                 name: @"PDFDidBeginDocumentWrite" object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndWrite:) 
                                                 name: @"PDFDidEndDocumentWrite" object: [_pdfView document]];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(documentEndPageWrite:) 
                                                 name: @"PDFDidEndPageWrite" object: [_pdfView document]];
												 
*/


	// Delegate.
	[[_pdfView document] setDelegate: self];
}

- (IBAction) doFindText: (id) sender
{
	if ( m_searchController == nil )
	{
		m_searchController = [[SearchController alloc] init];
	}
	PDFSelection *sel = [_pdfView currentSelection];
	if ( sel == nil )
	{
		PDFPage* page = [_pdfView currentPage];
		
		
		NSUInteger numChar = [page numberOfCharacters];
		
		if ( numChar > 0)
		{
			sel = [page selectionForRange:NSMakeRange(0, 1)];
			[_pdfView setCurrentSelection:sel];
		}
	}
//	PDFDocument* doc = [_pdfView document];
	//[m_searchController setPdfDocument:doc];
//	[m_searchController setPdfSelection:sel];

	[m_searchController setPdfView:_pdfView];

	[m_searchController showWindow:self];
	
	//NSArray<PDFSelection*> *res = [[_pdfView document] findString:searchString withOptions:NSCaseInsensitiveSearch];
}

// ------------------------------------------------------------------------------------------------------------- doSearch

- (IBAction) doSearch: (id) sender
{
	NSString	*searchString;
	
	// Cancel find if in progress.
	if ([[_pdfView document] isFinding])
		[[_pdfView document] cancelFindString];
	
	NSString* sText = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	// User cancelled (empty string sent).
	if ( sText == nil || [sText length] == 0)
    {
        [self setSearchResultsViewHeight:0.0];//close search window
		_searchResults = nil;
		_sampleStrings = nil;
		[_searchResultsTable reloadData];
		return;
	}
    
	// Lazily allocate _searchResults.
	//if (_searchResults == nil)
		_searchResults = [[NSMutableArray alloc] initWithCapacity: 10];
	
	// Lazily allocate _sampleStrings.
	//if (_sampleStrings == nil)
		_sampleStrings = [[NSMutableArray alloc] initWithCapacity: 10];
	
	// Open search results if required.
	if ([[[_splitView subviews] objectAtIndex: 0] frame].size.height == 0.0)
		[self setSearchResultsViewHeight: 80.0];
	
	// Normalize search string using Unicode Normalization Form KD.
	searchString = [sText decomposedStringWithCompatibilityMapping];
	
	// Do the search (will search forward, non-literal, and case-insensitive).
	[[_pdfView document] setDelegate:self];

/*	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_11)
	{
		NSArray *searchStrings = nil;
		searchStrings = [NSArray arrayWithObject:searchString];
		
		for (NSString *searchString in searchStrings) {
                NSArray *results = [[_pdfView document] findString:searchString withOptions:NSCaseInsensitiveSearch];
//                for (PDFSelection *result in results)
 //                   [self didMatchString:result];

				for (PDFSelection *result in results)
				{
					[_searchResults addObject:result];
					// Get a string containing a contextual sample of the string searched for and add to array.
					[_sampleStrings addObject: [self getContextualStringFromSelection: result]];
	
					
				}
				[_searchResultsTable reloadData];
		}
	}
	else*/
		[[_pdfView document] beginFindString: searchString withOptions: NSCaseInsensitiveSearch];
/*
/////SINGLE THREAD
	[_searchResults removeAllObjects];
	[_sampleStrings removeAllObjects];
	
	// Clear search results table.
	[_searchResultsTable reloadData];
	
	// Note start time.
	//_searchTime = [[NSDate alloc] initWithTimeIntervalSinceNow: 0.0];
	_searchTime = [NSDate date];

	NSArray<PDFSelection*> *res = [[_pdfView document] findString:searchString withOptions:NSCaseInsensitiveSearch];
	
	if ( res != nil)
	{
		int i = 100;
		i++;
	}
	*/
}

#pragma mark -------- Go Menu items

- (IBAction) doUpMenu:(id)sender
{
	[_pdfView scrollLineUp:sender];
}

- (IBAction) doDownMenu:(id)sender
{
	[_pdfView scrollLineDown:sender];
}

- (IBAction) doPreviousMenu:(id)sender
{
	[_pdfView goToPreviousPage:sender];
}

- (IBAction) doNextMenu:(id)sender
{
	[_pdfView goToNextPage:sender];
}

- (IBAction) doBackMenu:(id)sender
{
	[_pdfView goBack: sender];
}

- (IBAction) doForwardMenu:(id)sender
{
	[_pdfView goForward:sender];
}


// ------------------------------------------------------------------------------------------- setSearchResultsViewHeight

- (void) setSearchResultsViewHeight: (float) height
{
	NSRect		frameBounds;
	float		wasHeight;
	NSArray		*subViews;
	
	// Get subviews of split view.
	subViews = [_splitView subviews];
	
	// Get current height of search results view (view on top, view zero).
	frameBounds = [[subViews objectAtIndex: 0] frame];
	wasHeight = frameBounds.size.height;
	
	// Set it's frame to reflect new height.
	frameBounds.size.height = height;
	frameBounds.origin.y += wasHeight - height;
	
	// Adjust lower view (PDFView, view 1).
	[[subViews objectAtIndex: 0] setFrame: frameBounds];
	frameBounds = [[subViews objectAtIndex: 1] frame];
	frameBounds.size.height += wasHeight - height;
	[[subViews objectAtIndex: 1] setFrame: frameBounds];
	
	// Do we need to call this?  It doesn't seem to hurt.
	[_splitView adjustSubviews];
}
#pragma mark -------- Search notifications
// ------------------------------------------------------------------------------------------------------------ startFind

- (void) startFind: (NSNotification *) notification
{
	NSLog(@"Start find");
	// Empty arrays.
	[_searchResults removeAllObjects];
	[_sampleStrings removeAllObjects];
	
	// Clear search results table.
	[_searchResultsTable reloadData];
	
	// Note start time.
	//_searchTime = [[NSDate alloc] initWithTimeIntervalSinceNow: 0.0];
	_searchTime = [NSDate date];
}

- (void) endFind: (NSNotification *) notification
{
	NSLog(@"End find");
	// Force a reload.
	//[_searchTime release];
	if ( _searchResults == nil || _searchResults.count == 0 )
	{
		NSString* s = [NSString stringWithFormat:@"Unable to find text: %@", [_searchFieldView stringValue]];
		
		NSAlert *alert = [NSAlert alertWithMessageText:@"Text Search"
			defaultButton:@"OK" alternateButton:nil
			otherButton:nil informativeTextWithFormat:@"Unable to find text: %@", [_searchFieldView stringValue]];
		
			
		[alert runModal];
		
		alert = nil;
	}
	else
		[_searchResultsTable reloadData];
}

- (void) startPage: (NSNotification *) notification
{
	NSLog(@"Start page");
}

- (void) endPage: (NSNotification *) notification
{
	NSLog(@"End page");
}
/*
- (void)didMatchString:(PDFSelection *)instance;

- (void)documentDidBeginDocumentFind:(NSNotification *)note
{
	NSLog(@"BegindocFind");
}

- (void)documentDidBeginPageFind:(NSNotification *)notification
{
	NSLog(@"BeginPagefind");
}

- (void)documentDidEndDocumentFind:(NSNotification *)note
{
	NSLog(@"EndDocFind");
}

- (void)documentDidEndPageFind:(NSNotification *)note
{
	NSLog(@"ENdPageFind");
}

- (void)documentDidFindMatch:(NSNotification *)notification
{
	NSLog(@"DidFindMatch");
}
*/
// ------------------------------------------------------------------------------------------------------- didMatchString
// Called when an instance was located. Delegates can instantiate.

- (void) didMatchString: (PDFSelection *) instance
{
	PDFSelection	*instanceCopy;
	NSDate			*newTime;
	unsigned		count;
	
	//NSLog(@"MATCH");
	if (instance == nil) return;
	// Add page label to our array.
	instanceCopy = [instance copy];
	[_searchResults addObject: instance];
	count = (int)[_searchResults count];
	//NSLog(@"Foound: %@", [instance string]);
	// Get a string containing a contextual sample of the string searched for and add to array.
	[_sampleStrings addObject: [self getContextualStringFromSelection: instanceCopy]];
	//[_sampleStrings addObject: instance.attributedString];
	// How much time since we were last called (updating the table view too frequently can be slow for performance).
	newTime = [NSDate date];
/*	if (([newTime timeIntervalSinceDate: _searchTime] > 1.0) || (count == 1))
	{
		// Force a reload.
		[_searchResultsTable reloadData];
		NSLog(@"Reload: %d",count);
		//[_searchTime release];
		_searchTime = newTime;
		
		// Handle found first search result.
		if (count == 1)
		{
			// Select first item (search result) in table view.
			[_searchResultsTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
		}
	}**/
	
	[_searchResultsTable reloadData];
}

// ------------------------------------------------------------------------------------- getContextualStringFromSelection

- (NSAttributedString *) getContextualStringFromSelection: (PDFSelection *) instance
{
	NSMutableAttributedString	*attributedSample;
	NSString					*searchString;
	NSMutableString				*sample;
	NSString					*rawSample;
	unsigned int				count;
	unsigned int				i;
	unichar						ellipse = 0x2026;
	NSRange						searchRange;
	NSRange						foundRange;
	NSMutableParagraphStyle		*paragraphStyle = NULL;
	
	// Get search string.
	searchString = [instance string];
	
	// Extend selection.
	[instance extendSelectionAtStart: 10];
	[instance extendSelectionAtEnd: 128];
	
	// Get string from sample.
	rawSample = [instance string];
	count = (int)[rawSample length];
	
	// String to hold non-<CR> characters from rawSample.
	sample = [NSMutableString stringWithCapacity: count + 10 + 128];
	[sample setString: [NSString stringWithCharacters: &ellipse length: 1]];
	
	// Keep all characters except <LF>.
	for (i = 0; i < count; i++)
	{
		unichar		oneChar;
		
		oneChar = [rawSample characterAtIndex: i];
		if (oneChar == 0x000A || oneChar == 0x000D)
			[sample appendString: @" "];
		else
			[sample appendString: [NSString stringWithCharacters: &oneChar length: 1]];
	}
	
	// Follow with elipses.
	[sample appendString: [NSString stringWithCharacters: &ellipse length: 1]];
	
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString: sample];
	
	// Find instances of search string and "bold" them.
	searchRange.location = 0;
	searchRange.length = [sample length];
	do
	{
		// Search for the string.
		foundRange = [sample rangeOfString: searchString options: NSCaseInsensitiveSearch range: searchRange];
		
		// Did we find it?
		if (foundRange.location != NSNotFound)
		{
			// Bold the text range where the search term was found.
			[attributedSample setAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 
                                                                                          [NSFont systemFontSize]], NSFontAttributeName, NULL] range: foundRange];
			
			// Advance the search range.
			searchRange.location = foundRange.location + foundRange.length;
			searchRange.length = [sample length] - searchRange.location;
		}
	}
	while (foundRange.location != NSNotFound);
	
	// Create paragraph style that indicates truncation style.
	paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	// Add paragraph style.
    [attributedSample addAttributes: [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
                                      paragraphStyle, NSParagraphStyleAttributeName, NULL] range: NSMakeRange(0, [attributedSample length])];
	
	// Clean.
	//[paragraphStyle release];
	
	return attributedSample;
}

-(BOOL)isEdited
{
	return [[self window] isDocumentEdited];
}

#pragma mark -------- window close notification
- (BOOL)windowShouldClose:(id)sender
{
	if ( [[self window] isDocumentEdited] )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Save"];
		[alert addButtonWithTitle:@"Do not save"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Do you want to save the document?"];
		[alert setInformativeText:@"Document has been modified, do you want to save the changes?"];
		[alert setAlertStyle:NSWarningAlertStyle];

		NSModalResponse res = [alert runModal];
		if ( res == NSAlertFirstButtonReturn) {
			// OK clicked, delete the record
			//NSLog(@"Save");
			[[self document] saveDocument];
			return YES;//save and close
		} else if ( res == NSAlertSecondButtonReturn ){
			//NSLog(@"Do not save");
			return YES;//close - don't save
		} else {
			//NSLog(@"Cancel");
			return NO;//don't close
		}
	}
	else
	{
		return  YES;//doc not modified - allow to close
	}
}

-(void) windowWillClose:(NSNotification*)notification
{
#ifdef NEW_THUMBS
	[m_newThumbs removeObserver:self forKeyPath:selectionIndexPathsKey];
#endif
	[m_wndFreeNote close];
	[m_ctrlNote close];
	
	//NSLog(@"WillClose");
    // No more notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[[self document] close];
}
// -------------------------------------------------------------------------------------------------------------- endFind



#pragma mark -------- NSTableView delegate methods
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return 20.0f;
}

// ---------------------------------------------------------------------------------------------- numberOfRowsInTableView

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	if (aTableView == _searchResultsTable && _searchResults != nil)
		return (int)([_searchResults count]);
	else
		return 0;
}

// ------------------------------------------------------------------------------ tableView:objectValueForTableColumn:row

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) theColumn row: (int) rowIndex
{
	if (aTableView == _searchResultsTable && _searchResults != nil && _sampleStrings != nil )
	{
		if ([[theColumn identifier] isEqualToString: @"page"])
			return ([[[[_searchResults objectAtIndex: rowIndex] pages] objectAtIndex: 0] label]);
		//else if ([[theColumn identifier] isEqualToString: @"section"])
		//	return ([[[_pdfView document] outlineItemForSelection: [_searchResults objectAtIndex: rowIndex]] label]);
		else if ([[theColumn identifier] isEqualToString: @"text"])
			return ([_sampleStrings objectAtIndex: rowIndex]);
		else
			return NULL;
	}
	else
	{
		return NULL;
	}
}

#define FIND_RESULT_MARGIN 50.0
// ------------------------------------------------------------------------------------------ tableViewSelectionDidChange
- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	int			rowIndex;
	
	if ([notification object] == _searchResultsTable)
	{
		// What was selected. Skip out if the row has not changed.
		rowIndex = (int)[(NSTableView *)[notification object] selectedRow];
		if (rowIndex >= 0)
		{
			NSRect rect = NSZeroRect;
			PDFSelection* sel = [_searchResults objectAtIndex: rowIndex];
			NSArray<PDFPage*>* pages = sel.pages;
			
			if ( pages != nil && [pages count] > 0 )
			{
				PDFPage* page = [pages firstObject];
				
				rect = NSUnionRect(rect, [sel boundsForPage:page]);
				rect = NSIntersectionRect(NSInsetRect(rect, -FIND_RESULT_MARGIN, -FIND_RESULT_MARGIN), [page boundsForBox:kPDFDisplayBoxCropBox]);
				
				[_pdfView goToPage:page];
				[_pdfView goToRect:rect onPage:page];
				[_pdfView setCurrentSelection:sel animate:YES];
				
				//[_pdfView setCurrentSelection: sel];
				//[_pdfView scrollSelectionToVisible: self];
			}
		}
	}
}


#pragma mark -------- toolbar methods
// ------------------------------------------------------------------------------------------------ setupToolbarForWindow
// Create a new toolbar instance, and attach it to our document window.

- (void) setupToolbarForWindow: (NSWindow *) window
{
	NSToolbar		*toolbar;
	
	// Allocate it.
	toolbar = [[NSToolbar alloc] initWithIdentifier: @"Javelin Toolbar"];
	
	// Set up toolbar properties: Allow customization, give a default display mode, and 
	// remember state in user defaults.
	[toolbar setAllowsUserCustomization: YES];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	
	// We are the delegate
	[toolbar setDelegate: self];
	
	NSRect rect = [window frame];
	
	if (rect.size.width < 100) rect.size.width = 300;
	if ( rect.size.height < 100 ) rect.size.height = 300;
	
	[window setFrame:rect display:YES];
	// Attach the toolbar to the document window.
	[window setToolbar: toolbar];
	
	// Done.
	//[toolbar release];
}
/*
- (IBAction) printDocument: (id) sender
{
	[[Log getLog] addLine:@"JavelinController::printDocument"];
	[self printJavelinDocument:sender];
}
*/
// -------------------------------------------------------------- toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar
// Required delegate method. Given an item identifier, self method returns an 
// item. The toolbar will use self method to obtain toolbar items that can be 
// displayed in the customization sheet, or in the toolbar itself.

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) itemIdent 
  willBeInsertedIntoToolbar: (BOOL) willBeInserted
{
	NSToolbarItem	*toolbarItem;
	
	// Create a new toolbar item.
	toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	if ([itemIdent isEqualToString: ToolbarBackForward])
	{
		// Set the text label to be displayed in the toolbar, customization palette and tooltip.
		[toolbarItem setLabel: NSLocalizedString(@"Back/Forward", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Back/Forward", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Go Back or Forward", NULL)];
		
		// Set toolbar item view.
		//[_backForwardView retain];
		[toolbarItem setView: _backForwardView];
		[toolbarItem setMinSize: [_backForwardView frame].size];
		[toolbarItem setMaxSize: [_backForwardView frame].size];
		
		if (willBeInserted)
		{
			NSMenu		*submenu = NULL;
			NSMenuItem	*submenuItem1 = NULL;
			NSMenuItem	*submenuItem2 = NULL;
			NSMenuItem	*menuFormRep = NULL;
			
			// Create sub menu.
			submenu = [[NSMenu alloc] init];
			
			// Create Back menu item - add to sub menu.
			submenuItem1 = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Back", NULL)
                                                       action: @selector(doGoBack:) keyEquivalent: @""];
			[submenuItem1 setTarget: self];
			[submenu addItem: submenuItem1];
			
			// Create Forward menu item - add to sub menu.
			submenuItem2 = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Forward", NULL)
                                                       action: @selector(doGoForward:) keyEquivalent: @""];
			[submenuItem2 setTarget: self];
			[submenu addItem: submenuItem2];
			
			// Create menu form representation - set it.
			menuFormRep = [[NSMenuItem alloc] init];
			[menuFormRep setTitle: [toolbarItem label]];
			[menuFormRep setSubmenu: submenu];
			[toolbarItem setMenuFormRepresentation: menuFormRep];
		}
	}
    else if ([itemIdent isEqualToString: ToolbarNavigation])
	{
		// Set the text label to be displayed in the toolbar, customization palette and tooltip.
		[toolbarItem setLabel: NSLocalizedString(@"Navigation", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Navigation", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Page Navigation", NULL)];
		
		// Set toolbar item view.
		//[_navigationView retain];
		[toolbarItem setView: _navigationView];
		[toolbarItem setMinSize: [_navigationView frame].size];
		[toolbarItem setMaxSize: [_navigationView frame].size];
	}
	else if ([itemIdent isEqual: ToolbarPageNumber])
	{
		// Set up the standard properties .
		[toolbarItem setLabel: NSLocalizedString(@"Page", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Page", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Go To Page", NULL)];
		
		// Set toolbar item view.
		//[_pageNumberView retain];
		[toolbarItem setView: _pageNumberView];
		[toolbarItem setMinSize: NSMakeSize(50, NSHeight([_pageNumberView frame]))];
		[toolbarItem setMaxSize: NSMakeSize(56, NSHeight([_pageNumberView frame]))];
		
		if (willBeInserted)
		{
			NSMenu		*submenu = NULL;
			NSMenuItem	*submenuItem = NULL;
			NSMenuItem	*menuFormRep = NULL;
			
			// Create sub menu.
			submenu = [[NSMenu alloc] init];
			
			// Create Page Dialog item.
			submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Go To Page Panel", NULL)
                                                      action: @selector(doGoToPagePanel:) keyEquivalent: @""];
			[submenuItem setTarget: self];
			[submenu addItem: submenuItem];
			
			// Create menu form representation - set it.		
			menuFormRep = [[NSMenuItem alloc] init];
			[menuFormRep setTitle: [toolbarItem label]];
			[menuFormRep setSubmenu: submenu];
			[toolbarItem setMenuFormRepresentation: menuFormRep];
		}
		else
		{
			toolbarItem = [toolbarItem copy];
			[(NSTextField *)[toolbarItem view] setStringValue: @"--"];
		}
	}
	else if ([itemIdent isEqual: ToolbarPageCount])
	{
		// Set up the standard properties .
		[toolbarItem setLabel: NSLocalizedString(@"Total Pages", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Pages", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Total Pages", NULL)];
		
		// Set toolbar item view.
		//[_pageNumberView retain];
		[toolbarItem setView: _pageCount];
		[toolbarItem setMinSize: NSMakeSize(50, NSHeight([_pageCount frame]))];
		[toolbarItem setMaxSize: NSMakeSize(56, NSHeight([_pageCount frame]))];
		
		if (willBeInserted)
		{
			NSMenu		*submenu = NULL;
			NSMenuItem	*submenuItem = NULL;
			NSMenuItem	*menuFormRep = NULL;
			
			// Create sub menu.
			submenu = [[NSMenu alloc] init];
			
			// Create Page Dialog item.
			submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Page Count", NULL)
													 action: @selector(doGoToPagePanel:) keyEquivalent: @""];
			[submenuItem setTarget: self];
			[submenu addItem: submenuItem];
			
			// Create menu form representation - set it.		
			menuFormRep = [[NSMenuItem alloc] init];
			[menuFormRep setTitle: [toolbarItem label]];
			[menuFormRep setSubmenu: submenu];
			[toolbarItem setMenuFormRepresentation: menuFormRep];
		}
		else
		{
			toolbarItem = [toolbarItem copy];
			[(NSTextField *)[toolbarItem view] setStringValue: @"--"];
		}
	}

	else if ([itemIdent isEqualToString: ToolbarViewMode])
	{
		// Set the text label to be displayed in the toolbar, customization palette and tooltip.
		[toolbarItem setLabel: NSLocalizedString(@"View Mode", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"View Mode", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Change the Viewing Mode", NULL)];
		
		// Set toolbar item view.
		//[_viewModeView retain];
		[toolbarItem setView: _viewModeView];
		[toolbarItem setMinSize: [_viewModeView frame].size];
		[toolbarItem setMaxSize: [_viewModeView frame].size];
	}
	else if ([itemIdent isEqual: ToolbarSearch])
	{
		// Set up the standard properties .
		[toolbarItem setLabel: NSLocalizedString(@"Search", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Search", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Search document", NULL)];
		
		// Set toolbar item view.
		//[_searchFieldView retain];
		[toolbarItem setView: _searchFieldView];
		[toolbarItem setMinSize: NSMakeSize(128, NSHeight([_searchFieldView frame]))];
		[toolbarItem setMaxSize: NSMakeSize(256, NSHeight([_searchFieldView frame]))];
		
		
		if (willBeInserted)
		{
			NSMenu		*submenu = NULL;
			NSMenuItem	*submenuItem = NULL;
			NSMenuItem	*menuFormRep = NULL;
			
			// Create sub menu.
			submenu = [[NSMenu alloc] init];
			
			// Create Search panel item.
			submenuItem = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Search Panel", NULL)
                                                      action: @selector(doSearch:) keyEquivalent: @""];
			[submenuItem setTarget: self];
			[submenu addItem: submenuItem];
			
			// Create menu form representation - set it.		
			menuFormRep = [[NSMenuItem alloc] init] ;
			[menuFormRep setTitle: [toolbarItem label]];
			[menuFormRep setSubmenu: submenu];
			[toolbarItem setMenuFormRepresentation: menuFormRep];
		}
	}
	else if ([itemIdent isEqualToString: ToolbarZoomInOut])
	{
		// Set the text label to be displayed in the toolbar, customization palette and tooltip.
		[toolbarItem setLabel: NSLocalizedString(@"Zoom In/Out", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Zoom In/Out", NULL)];
		[toolbarItem setToolTip: NSLocalizedString(@"Page zoomming", NULL)];
		
		// Set toolbar item view.
		//[_zoomInOutView retain];
		[toolbarItem setView: _zoomInOutView];
		[toolbarItem setMinSize: [_zoomInOutView frame].size];
		[toolbarItem setMaxSize: [_zoomInOutView frame].size];
	}
	else if ([itemIdent isEqualToString: ToolbarToggleDrawer])
	{
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: NSLocalizedString(@"Outline", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Outline", NULL)];
		
		// Set up a reasonable tooltip, and image.
		[toolbarItem setToolTip: NSLocalizedString(@"Show or Hide Outline", NULL)];
		[toolbarItem setImage: [NSImage imageNamed: @"ToolbarDrawerImage"]];
		
		// Tell the item what message to send when it is clicked.
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(toggleDrawer:)];
	}
	else if ([itemIdent isEqualToString: ToolbarDownload])
	{
		//DOWNLOAD - toolbar
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: NSLocalizedString(@"Download", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Download", NULL)];
		
		// Set up a reasonable tooltip, and image.
		[toolbarItem setToolTip: NSLocalizedString(@"Download a File", NULL)];
		[toolbarItem setImage: [NSImage imageNamed: @"ToolbarDownloadImage"]];
		
		// Tell the item what message to send when it is clicked.
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(downloadFile:)];
	}
	else if ([itemIdent isEqualToString: ToolbarRotateLeft])
	{
		//ROTATE - toolbar
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: NSLocalizedString(@"Rotate", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Rotate", NULL)];
		
		// Set up a reasonable tooltip, and image.
		[toolbarItem setToolTip: NSLocalizedString(@"Rotate Page Anti-clockwise", NULL)];
		[toolbarItem setImage: [NSImage imageNamed: @"ToolbarRotateImage"]];
		
		// Tell the item what message to send when it is clicked.
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(rotatePageLeft:)];
	}

	else if ([itemIdent isEqualToString: TooolbarFindText])
	{
		//Text find 2016-10-20
/*		[toolbarItem setLabel: NSLocalizedString(@"Search", NULL)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Search", NULL)];
		
		// Set up a reasonable tooltip, and image.
		[toolbarItem setToolTip: NSLocalizedString(@"Search Document", NULL)];
		[toolbarItem setImage: [NSImage imageNamed: @"ToolbarSearchImage"]];
		
		// Tell the item what message to send when it is clicked.
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(doFindText:)];*/
	}
	else
	{
		// Not identified, not supported. 
		toolbarItem = NULL;
	}
	
	return toolbarItem;
}

// ---------------------------------------------------------------------------------------- toolbarDefaultItemIdentifiers
// Required delegate method. Returns the ordered list of items to be shown in 
// the toolbar by default. If during the toolbar's initialization, no overriding 
// values are found in the user defaults, or if the user chooses to revert to 
// the default items self set will be used.

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects: 
			ToolbarBackForward, ToolbarNavigation, ToolbarPageNumber, ToolbarPageCount, ToolbarSearch, ToolbarViewMode,
			NSToolbarFlexibleSpaceItemIdentifier, ToolbarZoomInOut, ToolbarDownload, ToolbarRotateLeft, //TooolbarFindText,
			ToolbarToggleDrawer, 
			NULL];
}

// ---------------------------------------------------------------------------------------- toolbarAllowedItemIdentifiers
// Required delegate method. Returns the list of all allowed items by identifier.
// By default, the toolbar does not assume any items are allowed, even the 
// separator. So, every allowed item must be explicitly listed. The set of 
// allowed items is used to construct the customization palette.

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:  
			ToolbarBackForward, ToolbarNavigation, ToolbarPageNumber, ToolbarPageCount, ToolbarSearch, ToolbarViewMode,
			NSToolbarFlexibleSpaceItemIdentifier, ToolbarZoomInOut, ToolbarDownload, ToolbarRotateLeft, //TooolbarFindText,
			ToolbarToggleDrawer,
			NSToolbarSeparatorItemIdentifier, 
            NSToolbarSpaceItemIdentifier,  
			NSToolbarCustomizeToolbarItemIdentifier, NSToolbarPrintItemIdentifier, 
			NULL];
}

// --------------------------------------------------------------------------------------------------- toolbarWillAddItem
// Optional delegate method. Before an new item is added to the toolbar, self 
// notification is posted self is the best place to notice a new item is going 
// into the toolbar. For instance, if you need to cache a reference to the 
// toolbar item or need to set up some initial state, self is the best place 
// to do it. The notification object is the toolbar to which the item is being 
// added. The item being added is found by referencing the @"item" key in the userInfo.

- (void) toolbarWillAddItem: (NSNotification *) theNotification
{
	NSToolbarItem	*addedItem;
	
	// Toolbar item added.
	addedItem = [[theNotification userInfo] objectForKey: @"item"];
	
	// See if it is one we're interested in.
	if ([[addedItem itemIdentifier] isEqualToString: ToolbarBackForward])
	{
		_toolbarBackForwardItem = addedItem ;
		
		// Listen for these.
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateBackForwardState:) 
                                                     name: PDFViewChangedHistoryNotification object: _pdfView];
		
		// Update.
		[self updateBackForwardState: NULL];
	}
	else if ([[addedItem itemIdentifier] isEqualToString: ToolbarPageNumber])
	{
		_toolbarPageNumberItem = addedItem;
		
		// Listen for these.
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updatePageNumberField:) 
                                                     name: PDFViewPageChangedNotification object: _pdfView];
		
		// Update.
		[self updatePageNumberField: NULL];
	}
	else if ([[addedItem itemIdentifier] isEqualToString: ToolbarPageCount])
	{
		_toolbarPageCountItem = addedItem;
		
		// Listen for these.
		//[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updatePageNumberField:) 
		//											 name: PDFViewPageChangedNotification object: _pdfView];
		
		// Update.
		//[self updatePageNumberField: NULL];
	}

	else if ([[addedItem itemIdentifier] isEqualToString: ToolbarViewMode])
	{
		_toolbarViewModeItem = addedItem;
		
		// Update.
		[self updateViewMode: NULL];
	}
	else if ([[addedItem itemIdentifier] isEqualToString: ToolbarSearch])
	{
		_toolbarSearchFieldItem = addedItem;
	}
	else if ([[addedItem itemIdentifier] isEqualToString: ToolbarZoomInOut])
	{
		_toolbarZoomInOutItem = addedItem;
		
		// Update.
//		[self updateViewMode: NULL];
	}
	else if ([[addedItem itemIdentifier] isEqualToString:NSToolbarPrintItemIdentifier])
	{
		[addedItem setAction: @selector(dummyPrint:)];
		//int i =100;
		//i++;
	}

}

-(IBAction)doSaveMe:(id)sender
{
	if ( [[self window] isDocumentEdited] )
	{
		[[self document] saveDocument];
		[[self window] setDocumentEdited:NO];
	}
}

-(IBAction) doExportNotes:(id)sender
{
	if ( _pdfView != nil )
	{
		[_pdfView exportAllNotes];
	}
}

-(IBAction)doCloseMe:(id)sender
{
	if ( [[self window] isDocumentEdited] )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Save"];
		[alert addButtonWithTitle:@"Do not save"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Do you want to save the document?"];
		[alert setInformativeText:@"Document has been modified, do you want to save the changes?"];
		[alert setAlertStyle:NSWarningAlertStyle];

		NSModalResponse res = [alert runModal];
		if ( res == NSAlertFirstButtonReturn) {
			// OK clicked, delete the record
			//NSLog(@"Save");
			[[self document] saveDocument];
			[self close];//save and close
		} else if ( res == NSAlertSecondButtonReturn ){
			//NSLog(@"Do not save");
			[self close];//close - don't save
		}
		return;
	}
	
	[self close];
}

-(void)close
{
    [super close];
	int nPage = (int)CGPDFPageGetPageNumber([[_pdfView currentPage] pageRef]);
	NSString* sDoc = _pdfView.javelinDocument.fileURL.filePathURL.absoluteString;
	
	//NSLog(@"PAGE: %d %@", nPage, sDoc );
	if ( sDoc != nil )
	{
		[[General documentList] addDocument:sDoc startPage:nPage];
		[[General documentList] saveMe];
	}
	
    [_pdfView setJavelinDocument:nil];
    _pdfView = nil;
}
-(IBAction) dummyPrint:(id) sender
{
	BOOL bEnable = [[self document] printingEnabled];
	if ( bEnable == NO )
	{
		NSAlert *theAlert = [NSAlert alertWithMessageText:@"Printing is not allowed!" 
											defaultButton:@"OK" 
										  alternateButton:nil
											  otherButton:nil
								informativeTextWithFormat:@""];
		[theAlert runModal];
	}
	else 
	{
		int nRes = [_pdfView printJvlnDocument:sender];
		
		if ( nRes != 0 )
		{//if not 0 - nRes is documentID
			[DocumentDB deleteDocument:nRes];
			[self close];
		}
	}
}
// ------------------------------------------------------------------------------------------------- toolbarDidRemoveItem

- (void) toolbarDidRemoveItem: (NSNotification *) theNotification
{
	NSToolbarItem	*removedItem;
	
	// Which item is going away?
	removedItem = [[theNotification userInfo] objectForKey: @"item"];
	
	if ([[removedItem itemIdentifier] isEqualToString: ToolbarBackForward])
	{
		// No longer listen.
		[[NSNotificationCenter defaultCenter] removeObserver: self name: PDFViewChangedHistoryNotification 
                                                      object: _pdfView];
		
		// Release.
		//if (_toolbarBackForwardItem)
		//	[_toolbarBackForwardItem release];
		_toolbarBackForwardItem = NULL;
	}
	else if ([[removedItem itemIdentifier] isEqualToString: ToolbarPageNumber])
	{
		// No longer listen.
		[[NSNotificationCenter defaultCenter] removeObserver: self name: PDFViewPageChangedNotification 
                                                      object: _pdfView];
		
		// Release.
		//if (_toolbarPageNumberItem)
		//	[_toolbarPageNumberItem release];
		_toolbarPageNumberItem = NULL;
	}
	else if ([[removedItem itemIdentifier] isEqualToString: ToolbarViewMode])
	{
		// Release.
		//if (_toolbarViewModeItem)
		//	[_toolbarViewModeItem release];
		_toolbarViewModeItem = NULL;
	}
	else if ([[removedItem itemIdentifier] isEqualToString: ToolbarSearch])
	{
		// Release.
		//if (_toolbarSearchFieldItem)
		//	[_toolbarSearchFieldItem release];
		_toolbarSearchFieldItem = NULL;
	}
	else if ([[removedItem itemIdentifier] isEqualToString: ToolbarZoomInOut])
	{
		// Release.
		//if (_toolbarZoomInOutItem)
		//	[_toolbarZoomInOutItem release];
		_toolbarZoomInOutItem = NULL;
	}
	else if ([[removedItem itemIdentifier] isEqualToString: TooolbarFindText])
	{
		// Release.
		m_btnFind = NULL;
	}
	

}


// --------------------------------------------------------------------------------------------------------- toggleDrawer
- (void) toggleDrawer: (id) sender
{
	[_drawer toggle: sender];
}

-(void)closeDrawer
{
	[_drawer close];
	_outlineView = nil;
}

- (void) rotatePageLeft: (id) sender
{
	PDFPage* page = [_pdfView currentPage];
	if ( page != nil )
	{
		NSInteger nRotation = page.rotation;
		nRotation -= 90;
		if ( nRotation == -360)
			nRotation = 0;
		[page setRotation:nRotation];
	}
}

- (void) downloadFile: (id) sender
{
	[NSApp downloadFile:sender];
}

- (IBAction) printJavelinDocument: (id) sender
{
	[[Log getLog] addLine:@"JavelinController::printJavelinDocument"];
	// Pass down to PDF view.
	int nRes = [_pdfView printJvlnDocument: sender];
	if (0 != nRes )
	{//if not 0 - nRes is documentID
		[DocumentDB deleteDocument:nRes];
		if ( m_docUrl != nil )
		{
			[self openDrmxFile:m_docUrl];
		}
	}
}

// -------------------------------------------------------------------------------------------------- validateToolbarItem
// Optional method. Self message is sent to us since we are the target of some 
// toolbar item actions (for example: of the save items action) 

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
	BOOL		enable = YES;
	
	if ([toolbarItem action] == @selector(doGoToPreviousPage:))
	{
		enable = [_pdfView canGoToPreviousPage];
	}
	else if ([toolbarItem action] == @selector(doGoToNextPage:))
	{
		enable = [_pdfView canGoToNextPage];
	}
	else if ([toolbarItem action] == @selector(doGoToPage:))
	{
		// Enabled if the current document is multipage.
		enable = ([[_pdfView document] pageCount] > 1);
	}
	else if ([toolbarItem action] == @selector(toggleDrawer:))
	{
		// Enabled if we have an outline for this PDF.
		//enable = (_outline != NULL);
		enable = YES;
	}
	else if ([toolbarItem action] == @selector(downloadFile:))
	{
		enable = YES;
	}
	else if ([toolbarItem action] == @selector(rotatePageLeft:))
	{
		enable = YES;
	}
	else if ([toolbarItem action] == @selector(doZoomInOut:))
	{
		enable = YES;
	}
	
	//NSLog( @"Toolbar item:%@ [%@]", [toolbarItem description], [toolbarItem label] ); 
	return enable;
}

- (void) updateBackForwardState: (NSNotification *) notification
{
	// Update segemented control state.
	[_backForwardView setEnabled: [_pdfView canGoBack] forSegment: 0];
	[_backForwardView setEnabled: [_pdfView canGoForward] forSegment: 1];
}

- (void) updatePageNumberField: (NSNotification *) notification
{
    if ( _pdfView != nil && [_pdfView document] != nil )
    {
        // Update label displayed in "go-to-page text field".
		if ( [_pdfView currentPage] != nil )
			[_pageNumberView setStringValue: [[_pdfView currentPage] label]];
	}
	// Make sure current outline item is selected.
	[self updateOutlineSelection];
}

// ------------------------------------------------------------------------------------------------------- updateViewMode

- (void) updateViewMode: (NSNotification *) notification
{
	switch ([_pdfView displayMode])
	{
		case kPDFDisplaySinglePageContinuous:
            [_viewModeView setSelectedSegment: 0];
            break;
            
		case kPDFDisplaySinglePage:
            [_viewModeView setSelectedSegment: 1];
            break;
            
		case kPDFDisplayTwoUp:
            [_viewModeView setSelectedSegment: 2];
            break;
        
        default:
            [_viewModeView setSelectedSegment: 3];
            break;
	}
}

#pragma mark --------  actions
// ------------------------------------------------------------------------------------------------------ doGoBackForward

- (IBAction) doGoBackForward: (id) sender
{
	// Segment with tag eqial to zero is the Back, otherwise Forward.
	if ([[sender cell] tagForSegment: [sender selectedSegment]] == 0)
		[_pdfView goBack: sender];
	else
		[_pdfView goForward: sender];
}

// -------------------------------------------------------------------------------------------------------------  doNavigate
- (IBAction) doNavigate: (id) sender
{
    long nWhat = [sender selectedSegment];
	if ( nWhat == 0)
		[_pdfView goToFirstPage: sender];
	else if ( nWhat == 1 )
		[_pdfView goToPreviousPage: sender];
    else if ( nWhat == 2 )
        [_pdfView goToNextPage: sender];
    else
        [_pdfView goToLastPage: sender];
    
}

- (IBAction) doChangeMode: (id) sender
{
    long nWhat = [sender selectedSegment];
	if ( nWhat == 0)
		[_pdfView setDisplayMode: kPDFDisplaySinglePageContinuous];
    else if ( nWhat == 1 )
        [_pdfView setDisplayMode: kPDFDisplaySinglePage];
    else if ( nWhat == 2 )
        [_pdfView setDisplayMode: kPDFDisplayTwoUp];
    else 
        [_pdfView setDisplayMode: kPDFDisplayTwoUpContinuous ];
    
}

// ----------------------------------------------------------------------------------------------------------- doGoToPage

- (IBAction) doGoToPage: (id) sender
{
	int			newPage;
	
	// Make sure page number entered is valid.
	newPage = [self getPageIndexFromLabel: [sender stringValue]];
	if ((newPage < 1) || (newPage > [[_pdfView document] pageCount]))
	{
		// Error.
		[self updatePageNumberField: NULL];
		NSBeep();
	}
	else
	{
		// Go to that page.
		[_pdfView goToPage: [[_pdfView document] pageAtIndex: newPage - 1]];
	}
}

- (IBAction) doZoomInOut: (id) sender
{
	if ([[sender cell] tagForSegment: [sender selectedSegment]] == 0)
		[_pdfView zoomIn:sender];
	else
		[_pdfView zoomOut:sender];
}

#pragma mark -------- utility methods
// ------------------------------------------------------------------------------------------------ getPageIndexFromLabel
// Given a page label (might be "1" or "2" or might be "i" or "iv") try to return the index of the
// page that has that label (or -1 if none). In this exceptional case, pages are 1-based.

- (int) getPageIndexFromLabel: (NSString *) label
{
	int			index = -1;
	int			count;
	int			i;
	
	// Handle empty string.
	if ([label length] < 1)
		goto bail;
	
	// Walk through all pages and compare the page label against 'label'.
	count = (int)[[_pdfView document] pageCount];
	for (i = 0; i < count; i++)
	{
		if ([[[[_pdfView document] pageAtIndex: i] label] isEqualToString: label])
		{
			// Got it.
			index = i + 1;
			break;
		}
	}
	
bail:
	return index;
}



- (IBAction) showProperties: (id)sender
{
/*	PropertiesController *pc = [[PropertiesController alloc] init];
	PDFDocument *doc = [_pdfView document];
	JavelinDocument *docJavelin = [_pdfView javelinDocument];
	DocumentRecord *docRec = nil;
	if ( docJavelin != nil )
	{
		PDOCEX_INFO pDocInfo = [docJavelin docInfo];
		if ( pDocInfo != nil )
		{
			docRec = [DocumentDB getDocument:pDocInfo->dwDocID];
		}
	}

	[pc showProperties:[self window] attributes:[doc documentAttributes] docRecord:docRec];*/
	
	if ( m_properties == nil )
		m_properties = [[PropertiesController alloc] init];
		
	PDFDocument *doc = [_pdfView document];
	JavelinDocument *docJavelin = [_pdfView javelinDocument];
	DocumentRecord *docRec = nil;
	BOOL bSelfAuth = NO;
	NSUInteger nPublisherID = 0;
	BOOL bDisableScreenCapture = NO;
	
	if ( docJavelin != nil )
	{
		PDOCEX_INFO pDocInfo = [docJavelin docInfo];
		if ( pDocInfo != nil )
		{
			docRec = [DocumentDB getDocument:pDocInfo->dwDocID];
			bSelfAuth = (pDocInfo->byAdditional[127] == 80);
			nPublisherID = pDocInfo->dwCreatorID;
			bDisableScreenCapture = (pDocInfo->sBlockGrabbers == 0)?NO:YES;
		}
	}
	
	[m_properties setSelfAuth:bSelfAuth];
	NSUInteger nPages = [doc pageCount];
	NSUInteger nFileSize = [docJavelin fileSize];
	
	[m_properties fillProperties:[doc documentAttributes] 
					   docRecord:docRec 
						fileName:[[docJavelin DocumentURL] path] 
						fileSize:nFileSize 
				   blockGrabbers:bDisableScreenCapture
					 publisherID:nPublisherID
						   pages:nPages 
						inWindow:self.window];

/*	[NSApp beginSheet: m_properties.properties
	   modalForWindow: self.window
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];*/
}

- (IBAction)openAboutPanel:(id)sender
{


    NSDictionary *options;
    //NSImage *img;
	
    //img = [NSImage imageNamed: @"Picture 1"];
    options = [NSDictionary dictionaryWithObjectsAndKeys:
			   [Version date], @"Version",
			   [Version appName], @"ApplicationName",
			   //img, @"ApplicationIcon",
			   [NSString stringWithFormat:@"Copyright 2019, %@",[Version company]], @"Copyright",
			   [NSString stringWithFormat:@"%@ v%@",[Version appName],[Version version]], @"ApplicationVersion",
			   nil];
	
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}
/*
- (IBAction)removeAuthorisation:(id)sender
{
	if ( [[self document] isDrm] )
	{
		UINT docID = [[self document] documentID];
		NSAlert *theAlert = [NSAlert alertWithMessageText:@"Remove authorisation?"
											defaultButton:@"Yes"
										  alternateButton:@"No"
											  otherButton:nil
								informativeTextWithFormat:
								[NSString stringWithFormat:@"Are you sure you want to remove authorisation of current document?\nDocumentID: %d", docID] ];
		int nRes = (int)[theAlert runModal];
		if (nRes == NSAlertDefaultReturn)
		{
			[DocumentDB deleteDocument:docID];
			[self doCloseMe:sender];
		}

	}
	else
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Un-protected document"
			defaultButton:@"OK" alternateButton:nil
			otherButton:nil
			informativeTextWithFormat:@"Unable to remove authorisation of un-protected document" ];
			
		[alert runModal];
		
		alert = nil;
	}
}
*/
#pragma mark NSCollectionViewDataSource Methods
#ifdef NEW_THUMBS
- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if ( _pdfView != nil )
	{
		return [[_pdfView document] pageCount];
	}
	else
	{
		return 0;
	}
}


- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    // Message back to the collectionView, asking it to make a @"Slide" item associated with the given item indexPath.  The collectionView will first check whether an NSNib or item Class has been registered with that name (via -registerNib:forItemWithIdentifier: or -registerClass:forItemWithIdentifier:).  Failing that, the collectionView will search for a .nib file named "Slide".  Since our .nib file is named "Slide.nib", no registration is necessary.
    NewThumbItem *item = (NewThumbItem*)[collectionView makeItemWithIdentifier:@"NewThumbItem" forIndexPath:indexPath];
	int nPage = (int)indexPath.item;
	PDFPage* page = [[_pdfView document] pageAtIndex:nPage];
	//NSLog(@"Index: %ld", (long)indexPath.item);
	NSData *data = [page dataRepresentation];
	NSImage *image = [[NSImage alloc] initWithData:data];
	//item.representedObject = image;
	[item setImage:image];
	
/*	NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	
NSFileManager       *fm = [NSFileManager defaultManager];
NSURL               *downloadsURL;  

downloadsURL = [fm URLForDirectory:NSDownloadsDirectory
                   inDomain:NSUserDomainMask appropriateForURL:nil
                   create:YES error:nil];
	NSString* sPath = [NSString stringWithFormat:@"%@TEST.JPG", NSTemporaryDirectory()];

    BOOL b = [imageData writeToFile:sPath atomically:NO];
*/
    return item;
}
/*
- (nonnull NSView *)collectionView:(nonnull NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(nonnull NSString *)kind atIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *identifier = nil;
    NSString *content = nil;
    NSArray<AAPLTag *> *tags = imageCollection.tags;
    NSInteger sectionIndex = indexPath.section;

    if (sectionIndex < tags.count) {
        AAPLTag *tag = tags[sectionIndex];
        if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
            content = tag.name;
        } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
            content = [NSString stringWithFormat:@"%lu image files tagged \"%@\"", (unsigned long)(tag.imageFiles.count), tag.name];
        }
    } else {
        if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
            content = @"(Untagged)";
        } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
            content = [NSString stringWithFormat:@"%lu image files have no tags assigned", (unsigned long)(imageCollection.untaggedImageFiles.count)];
        }
    }
    
    if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
        identifier = @"Header";
    } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
        identifier = @"Footer";
    }

    id view = identifier ? [collectionView makeSupplementaryViewOfKind:kind withIdentifier:identifier forIndexPath:indexPath] : nil;
    if (content && [view isKindOfClass:[AAPLHeaderView class]]) {
        NSTextField *titleTextField = [(AAPLHeaderView *)view titleTextField];
        titleTextField.stringValue = content;
    }

    return view;
}*/
#endif
#pragma mark NSCollectionViewDelegateFlowLayout Methods

// Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Header" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    //return groupByTag ? NSMakeSize(10000, HEADER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a header.
	return NSMakeSize(100, 200);
}

// Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Footer" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    //return groupByTag ? NSMakeSize(10000, FOOTER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a footer.
	//return NSZeroSize;
	return NSMakeSize(100, 200);
}


#pragma mark -- Note protocol
/*-(void)editNote:(PDFAnnotationText*)annot inWindow:(NSWindow*)window
{
	if ( m_pNote == nil )
		m_pNote = [[Note alloc] init];
	//[m_pNote showNote:annot inWindow:self.window];
	[m_pNote showNote:annot inWindow:window];
}

-(void)editFreeNote:(PDFAnnotationFreeText*)annot inWindow:(NSWindow*)window viewRect:(NSRect)rectView pdfView:(PDFView*)view
{
	NSRect rect = [window convertRectToScreen:annot.bounds];
	
	rect.origin.x = window.frame.origin.x + rectView.origin.x;
	rect.origin.y = window.frame.origin.y + rectView.origin.y;
	rect.size.width = rectView.size.width;
	rect.size.height = rectView.size.height;
	
	[m_ctrlNote open:annot inRect:rect inView:view];

}
*/
-(void)editNote:(JAnnotation*)annot inWindow:(NSWindow*)window
{
}

#define NOTE_WINDOW_WIDTH   (200)
#define NOTE_WINDOW_HEIGHT  (300)
-(void)editFreeNote:(JAnnotation*)annot inWindow:(NSWindow*)window viewRect:(NSRect)rectView pdfView:(PDFView*)view
{
    NSRect rect = [window convertRectToScreen:annot.boundary];
    NSPoint ptOrigin = [view convertPoint:[annot boundary].origin fromPage:[annot page]];
    rect.origin.x = window.frame.origin.x + /*rectView.origin.x + */ptOrigin.x;
    rect.origin.y = window.frame.origin.y + /*rectView.origin.y + */ptOrigin.y;
    rect.size.width = NOTE_WINDOW_WIDTH;//rectView.size.width;
    rect.size.height = NOTE_WINDOW_HEIGHT;//rectView.size.height;
    
    [m_ctrlNote open:annot inRect:rect inView:view];
    
    [m_notes reloadData];
}
-(void)closeNoteWindow
{
	[m_ctrlNote close];
}

-(void)noteChanged
{
    [m_notes collapseItem:nil];
    [m_notes reloadData];
    [m_notes setNeedsDisplay];
    [m_notes setNeedsLayout:YES];
}

- (IBAction)doFullScreen:(id)sender
{
	if ( _pdfView.inFullScreenMode )
	{
		[_pdfView exitFullScreenModeWithOptions:nil];
		[_pdfView setDisplayMode:m_oldDisplayMode];
		//NSLog(@"EXIT FS");
	}
	else
	{
		NSDictionary* FullScreen_Options = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]  forKey: NSFullScreenModeApplicationPresentationOptions];
		m_oldDisplayMode = [_pdfView displayMode];
		[_pdfView setDisplayMode:kPDFDisplaySinglePage];
		[_pdfView enterFullScreenMode:[NSScreen mainScreen] withOptions:FullScreen_Options];
	}
}

- (IBAction)doFind:(id)sender
{
	[self doFindText:sender];
}

- (IBAction)doFindNext:(id)sender
{
}

-(void)cancelOperation:(id)sender
{
	//NSLog(@"ESC");
	
}
- (void)keyDown:(NSEvent *)theEvent
{
	//if (_pdfView.inFullScreenMode)
	{
		[_pdfView exitFullScreenModeWithOptions:nil];
	}
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	//}
}

- (void) mouseDown: (NSEvent *) theEvent
{
	[super mouseDown:theEvent];
}

@end
