//
//  DownloadController.m
//  Javelin
//
//  Created by harry on 26/08/2013.
//
//

#import "DownloadController.h"
//#import "DownloadItem.h"
#import "DownloadCell.h"
#import "DownloadTableView.h"
#import "Log.h"

@implementation DownloadController

//@synthesize window=m_wndDownload;

- (id)init
{
    //self = [super init];
	self = [super initWithWindowNibName:@"DownloadController"];
    if (self) {
        // Initialization code here.
		//pdfAttributes = nil;
		//m_downloads = [[NSMutableArray alloc] init];
		[self loadDownloads];
		
		m_numberFormat = [[NSNumberFormatter alloc] init];
		m_numberFormat.usesGroupingSeparator = YES;
		m_numberFormat.groupingSeparator = @",";
		m_numberFormat.groupingSize = 3;
    }
	[[Log getLog] addLine:@"DownloadController initialised"];
    return self;
}
/*
- (void)dealloc
{
	//if ( pdfAttributes != nil ) [pdfAttributes release];
    [m_download cancel];
    [m_download release];
    [m_originalURL release];
    [m_fileURL release];
    [m_downloads release];
	[m_numberFormat release];

	[[Log getLog] addLine:@"DownloadController: Deallocating"];
		
    [super dealloc];
}
*/
- (void)awakeFromNib
{
	[m_table setDoubleAction:@selector(doubleClick:)];
	[m_table setAction:nil];
}

- (void)windowDidLoad  
{  
	[super windowDidLoad];

	[m_wndDownload setDefaultButtonCell:[m_ok cell]];
	
	[[Log getLog] addLine:@"DownloadController: About to beginSheet"];
	[m_table setDoubleAction:@selector(doubleClick:)];
	[self refreshTable];
	[[self window] center];  // Center the window.
}  


- (void)showDownload: (NSWindow *)window attributes:(NSDictionary*)attrs
{
	if ( ![NSBundle loadNibNamed: @"DownloadController" owner: self] )
	{
		[[Log getLog] addLine:@"DownloadController: Unable to load NIB"];
		return;
	}

	[m_wndDownload setDefaultButtonCell:[m_ok cell]];
	
	[[Log getLog] addLine:@"DownloadController: About to beginSheet"];
    [NSApp beginSheet: m_wndDownload
	   modalForWindow: window
		modalDelegate: nil//self
	   didEndSelector: nil//@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];

	[NSApp runModalForWindow:m_wndDownload];
	[[Log getLog] addLine:@"DownloadController: beginSheet call issued"];
	
	[NSApp endSheet: m_wndDownload];
    [m_wndDownload orderOut: self];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[Log getLog] addLine:@"DownloadController: didEndSheet called"];
    [sheet orderOut:self];
	//[NSApp endSheet:m_wndDownload];
}

- (IBAction)closeDownload: (id)sender
{
	[self updateUI:NO];
	
	if ( m_downloading )
	{
		[m_download cancel];
		m_downloading = NO;
		
		return;
	}
	
	BOOL bRes = [self writeDownloads];
	
	if ( bRes == NO)
	{
		[[Log getLog] addLine:@"Unable to save Documents.bin"];
	}
	else
	{
		[[Log getLog] addLine:@"Documents.bin saved"];
	}
	//NSLog(@"OK = %d", bRes);
	
    [NSApp endSheet:m_wndDownload];
	//[NSApp stopModal];
}

- (IBAction)openFile:(id)sender
{
	int ii = [m_table rightClickedRow];

	if ( ii != -1 )
	{
		NSString* sItem = [m_downloads objectAtIndex:ii];
		NSRange r = [sItem rangeOfString:@" -> " ];
		if ( r.location != NSNotFound )
		{
			NSString *sFile = [sItem substringFromIndex:r.location+r.length];
			NSURL *url = [NSURL URLWithString:sFile];
			
			[self openFileFromURL:url];
		}
	}
}

- (IBAction)deleteItem:(id)sender
{
	int ii = [m_table rightClickedRow];
	
	if ( ii != -1 )
	{
		[[self mutableArrayValueForKey:@"m_downloads"] removeObjectAtIndex:ii];
		
		[self performSelector:@selector(refreshTable) withObject:nil afterDelay:.1];

		//NSLog(@"%@", m_downloads);
	}
}

- (IBAction)doubleClick:(id)sender
{
	long row = [m_table clickedRow];
	
	if ( row != -1 )
	{
		NSString* sItem = [m_downloads objectAtIndex:row];
		NSRange r = [sItem rangeOfString:@" -> " ];
		if ( r.location != NSNotFound )
		{
			NSString *sFile = [sItem substringFromIndex:r.location+r.length];
			//NSLog(@"%@", sFile );
			
			sFile = [sFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			//NSLog(@"%@", sFile);
			
			NSURL *url = [NSURL URLWithString:sFile];
			//NSLog(@"%@", url);
			
			[self openFileFromURL:url];
		}
	}

}

-(void)refreshTable
{
	[m_table reloadData];
	[m_table setNeedsLayout:YES];
	[m_table setNeedsDisplay:YES];
	
	[[m_wndDownload contentView] setNeedsDisplay:YES];
}


-(BOOL)writeDownloads
{
/*	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* currentPath = [fm currentDirectoryPath];
	
	currentPath  = [currentPath stringByAppendingPathComponent:@"downloads.xml"];

//	NSArray* args = [[NSProcessInfo processInfo] arguments];
//   NSString* exe = [args objectAtIndex:0];
	
	
	[[Log getLog] addLine:@"Writing to:"];
	[[Log getLog] addLine:currentPath];
//	[[Log getLog] addLine:exe];
	return [m_downloads writeToFile:currentPath atomically:YES];
	*/
	
	//return [self writeToPlistFile:JAVELIN_DOWNLOAD_FILE];
	//return [self writeToFile:JAVELIN_DOWNLOAD_FILE];
	
	return [self writeToPlist];
}

-(void)loadDownloads
{
/*	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* currentPath = [fm currentDirectoryPath];
	
	currentPath  = [currentPath stringByAppendingPathComponent:@"downloads.xml"];
	
	m_downloads = [NSArray arrayWithContentsOfFile:currentPath];
	*/
	
/*	NSArray* aa = [self readFromPlistFile:JAVELIN_DOWNLOAD_FILE];
	if ( aa == nil )
		m_downloads = [[NSMutableArray alloc] init];
	else
		m_downloads = [NSMutableArray arrayWithArray:aa];*/
		
	//NSArray* aa = [self readFromFile:JAVELIN_DOWNLOAD_FILE];
	NSArray* aa = [self readFromPlist];
	if ( aa == nil )
		m_downloads = [[NSMutableArray alloc] init];
	else
	{
		m_downloads = [NSMutableArray arrayWithArray:aa];
//		if ( [m_downloads count] > 0 )
//		{
//			NSString* s = [m_downloads objectAtIndex:([m_downloads count]-1)];
//			if ( s.length == 0 )
//			{
//				[m_downloads removeLastObject];
//			}
//		}
	}
}
/*
	[[NSUserDefaults standardUserDefaults] setObject:theData forKey:sKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
*/
-(BOOL)writeToPlist
{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:m_downloads];

	[[NSUserDefaults standardUserDefaults] setObject:data forKey:JAVELIN_DOWNLOAD_KEY];
	return [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSArray*)readFromPlist
{
	NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:JAVELIN_DOWNLOAD_KEY];
	
	if ( data == nil )
	{
		return nil;
	}
	else
	{
		return  [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
}

-(BOOL)writeToPlistFile:(NSString*)filename{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:m_downloads];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    BOOL didWriteSuccessfull = [data writeToFile:path atomically:YES];
    return didWriteSuccessfull;
}

-(NSArray*)readFromPlistFile:(NSString*)filename{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] == NO )
		return nil;
	else
	{
		NSData * data = [NSData dataWithContentsOfFile:path];
		return  [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
}

-(BOOL)writeToFile:(NSString*)filename
{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * fullPath = [documentsDirectory stringByAppendingPathComponent:filename];
	
	NSFileHandle *outputFileHandle  = nil;
	
	NSString* s;
	
	@try
	{
		outputFileHandle  = [NSFileHandle fileHandleForWritingAtPath: fullPath];
		if ( outputFileHandle == nil )
		{
			[[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
			outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
			
			if ( outputFileHandle == nil ) return NO;
		}
		
		for( int i=0; i<[m_downloads count]; i++ )
		{
			if ( i == [m_downloads count]-1)
				s = [NSString stringWithString:[m_downloads objectAtIndex:i]];
			else
				s = [NSString stringWithFormat:@"%@\r\n", [m_downloads objectAtIndex:i]];
			[outputFileHandle writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	@catch( NSException* ex )
	{
		[[Log getLog] addLine:[ex reason]];
		return NO;
	}
	@finally {
		[outputFileHandle closeFile];
	}
}

-(NSArray*)readFromFile:(NSString*)filename
{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * fullPath = [documentsDirectory stringByAppendingPathComponent:filename];
	
	NSFileHandle *inputFileHandle  = [NSFileHandle fileHandleForReadingAtPath: fullPath];
	
	if ( inputFileHandle == nil ) return nil;
	
//	NSMutableArray* array = [[NSMutableArray alloc] init];
	
	@try
	{
		NSData* data = nil;
		
		data = [inputFileHandle readDataToEndOfFile];
		
		if ( data == nil ) return nil;
		
		NSString* s = [NSString stringWithUTF8String:[data bytes]];
		
		NSArray* a = [s componentsSeparatedByString:@"\r\n"];

		return a;
	}
	@catch( NSException* ex )
	{
		[[Log getLog] addLine:[ex reason]];
		return nil;
	}
	@finally {
		[inputFileHandle closeFile];
	}
}

- (IBAction)downloadAFile: (id)sender
{
    NSString* urlString = [NSString stringWithString:[m_url stringValue]];
	if ( urlString.length == 0 )
	{
		NSRunAlertPanel(@"Error", @"Please enter URL", @"OK", nil, nil);
		return;
	}
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	//[urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([urlString length] == 0) {
		NSRunAlertPanel(@"Error", @"Please enter a valid URL", @"OK", nil, nil);
		return;
    }
	
	NSString* urlStringCopy = [urlString lowercaseString];

	//check protocol
	NSRange r = [urlStringCopy rangeOfString:@"://"];
	
	if ( r.location != NSNotFound )
	{
		NSString *pProtocol = [urlStringCopy substringToIndex:r.location];
		
		if ( [pProtocol hasPrefix:@"http"] == NO && [pProtocol hasPrefix:@"https"] == NO )
		{
			NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"Unsupported protocol: %@", pProtocol], @"OK", nil, nil);
			return;
		}
	}
	
	if ( [urlStringCopy hasPrefix:@"http://"] == NO && [urlStringCopy hasPrefix:@"https://"] == NO )
	{
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	}
    
	NSURL* url = [NSURL URLWithString:urlString];
	if ( url == nil )
	{
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"Invalid URL: %@", urlString], @"OK", nil, nil);
		return;
	}
//	NSLog(@"filePathURL: %@", url.filePathURL);
//	NSLog(@"fileReferenceURL: %@", url.fileReferenceURL);
//	NSLog(@"Host: %@", url.host);
//	NSLog(@"lastPathComponent: %@", url.lastPathComponent);
//	NSLog(@"pathExtension: %@", url.pathExtension);
//	NSLog(@"scheme: %@", url.scheme);
//	NSLog(@"standardizedURL: %@", url.standardizedURL);

	if ( url.lastPathComponent == nil || url.lastPathComponent.length == 0 )
	{
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"You must include file name in URL:\n %@", urlString], @"OK", nil, nil);
		return;
	}
	
/*	NSArray* comps = [urlString pathComponents];
	for( int i=0; i<[comps count]; i++ )
	{
		NSLog(@"%@", [comps objectAtIndex:i]);
	}*/
/*	//check filename - does it exist in the url
	r = [urlString rangeOfString:@"://"];
	
	if ( r.location != NSNotFound )
	{
		//something very bad has happened
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"Unable to download from this URL:\n%@", urlString], @"OK", nil, nil);
		return;
	}
	else
	{
		NSRange rr = NSMakeRange(r.location+r.length, [urlString length]-r.location-r.length);
		NSRange rFile = [urlString rangeOfString:@"/" options:NSRegularExpressionSearch range:rr];
		
		if ( rFile.location == NSNotFound )
		{
			NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"You must include file name in URL:\n%@", urlString], @"OK", nil, nil);
			return;
		}
	}
	*/
	NSString* sExt = [urlString pathExtension];
	
	if ( [sExt caseInsensitiveCompare:@"xml"] == NSOrderedSame || [sExt caseInsensitiveCompare:@"pdf"] == NSOrderedSame ||
			[sExt caseInsensitiveCompare:@"drm"] == NSOrderedSame || [sExt caseInsensitiveCompare:@"drmx"] == NSOrderedSame ||
			[sExt caseInsensitiveCompare:@"drmz"] == NSOrderedSame)
	{
		int nRes = [self startDownloading:urlString];
		
		if ( nRes == DOWNLOAD_ERROR_WRONG_URL )
		{
			NSRunAlertPanel(@"Error", @"Wrong URL", @"OK", nil, nil);
		}
		else if ( nRes == DOWNLOAD_ERROR_GENERAL )
		{
			NSRunAlertPanel(@"Error", @"Unable to download from this URL", @"OK", nil, nil);
		}
	}
	else
	{
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"Unable to download this type [*.%@] of file", sExt], @"OK", nil, nil);
	}
}

- (int) startDownloading:(NSString*)strUrl
{
	NSURL* url = nil;

	NSRange r = [strUrl rangeOfString:@"%20"];
	
	if ( r.location == NSNotFound )
	{
		//no escape chars - be careful
		NSString *urlTextEscaped = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		url = [NSURL URLWithString:urlTextEscaped];
	}
	else
	{
		//string already contains escape chars
		url = [NSURL URLWithString:strUrl];
	}

    if (!url)
	{
        return DOWNLOAD_ERROR_WRONG_URL;
    }
	
	NSLog(@"url:%@", url);
	
	m_originalURL = url;
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    m_download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
    
	if ( m_download != nil ){
		[self updateUI:YES];
		m_downloadIsIndeterminate = YES;
		m_downloadProgress = 0.0f;
		m_downloading = YES;
		CFRunLoopStop(CFRunLoopGetCurrent());
	} else {
		NSRunAlertPanel(@"ERROR", @"Unable to initiate download process", @"OK", nil, nil);
	}
//    [[downloadsTableView window] makeFirstResponder:downloadsTableView];

	return DOWNLOAD_OK;
}

-(void)openFileFromURL:(NSURL*)url
{
	[self writeDownloads];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
	[NSApp endSheet:m_wndDownload];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response;
{
	NSLog(@"Download didreceive");
	
    m_expectedLength = [response expectedContentLength];
    if (m_expectedLength > 0) {
		m_downloadIsIndeterminate = NO;
        m_downloadedSoFar = 0;
		[m_progress setIndeterminate:NO];
		m_progress.minValue = 0.0f;
		m_progress.maxValue = 100.0f;
		m_startTime = [[NSDate alloc] init];
    } else {
		[m_progress setIndeterminate:YES];
	}
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	NSLog(@"Download didreceiveLength");

    m_downloadedSoFar += length;
    if (m_downloadedSoFar >= m_expectedLength) {
        // the expected content length was wrong as we downloaded more than expected
        // make the progress indeterminate
		m_downloadIsIndeterminate = YES;
    } else {
        m_downloadProgress = (float)m_downloadedSoFar / (float)m_expectedLength;
		[m_progress setDoubleValue:(m_downloadedSoFar/(double)m_expectedLength)*100.0];
		NSString *soFarString = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:m_downloadedSoFar]];
		NSString *expected = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:m_expectedLength]];
		[m_bytes setStringValue:[NSString stringWithFormat:@"%@/%@", soFarString, expected]];
		[m_percentage setStringValue:[NSString stringWithFormat:@"%d%%", (int)(m_downloadProgress*100)]];
		NSDate* now = [NSDate date];
		NSTimeInterval elapsed = [now timeIntervalSinceDate:m_startTime];
		
		if ( elapsed > 0 )
		{
			long seconds;// = lroundf(elapsed); // Modulo (%) operator below needs int or long

			float fBytesPerSecond = (float)(m_downloadedSoFar / elapsed);//bytes per second
			float f1 = (float)((m_expectedLength-m_downloadedSoFar) / fBytesPerSecond);
			
			if ( fabs(f1-m_old) > 1 )
			{
				seconds = lroundf(f1);
		//		int hour = seconds / 3600;
				int mins = (int)(seconds / 60);
				int secs = seconds % 60;
				//NSLog(@"bps:%f f1:%f s:%lu", fBytesPerSecond, f1, seconds);
				if ( mins > 99 )
					[m_time setStringValue:@"100+ min"];
				else
					[m_time setStringValue:[NSString stringWithFormat:@"%02dmin %02ds", mins, secs]];
					
				m_old = f1;
			}
		}
    }
}


- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename
{
	NSLog(@"download decide Dest");
	NSArray* aa = [[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask];
	//NSLog(@"%@", aa );
	
	//NSString* path1 = [[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:filename];
	//NSLog(@"%@", path1);
	
	NSString* s = [[aa objectAtIndex:0] absoluteString];
	NSString* path = [s stringByAppendingPathComponent:filename];
	NSString* urlTextEscaped = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	//NSLog(@"%@", path);
	
	NSURL* url = [NSURL URLWithString:urlTextEscaped];
	path = [url path];
	//NSLog(@"%@", path);
	
	NSRange r = [path rangeOfString:@"/localhost"];
	if ( r.location != NSNotFound )
	{
		path = [path substringFromIndex:r.location+r.length];
	}
	
	//NSLog(@"%@", path);
	
    [aDownload setDestination:path allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
	NSLog(@"download didcreatedest");
	
    m_fileURL = [[NSURL alloc] initFileURLWithPath:path];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	NSLog(@"Download did finish");
	BOOL bOK = NO;
	
    if (m_originalURL && m_fileURL)
	{
		NSString* sSrc = [[m_originalURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString* sDst = [[m_fileURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[[self mutableArrayValueForKey:@"m_downloads"] addObject:[NSString stringWithFormat:@"%@ -> %@", sSrc, sDst]];
		[m_table reloadData];
		
		bOK = YES;
    }
    
    m_downloading = NO;
	
	[self updateUI:NO];
	
	if ( bOK )
	{
		NSString* sExt = [[[[download request] URL] pathExtension] lowercaseString];
		
		if ( [sExt compare:@"pdf"] == NSOrderedSame || [sExt compare:@"drm"] == NSOrderedSame || [sExt compare:@"drmz"] == NSOrderedSame || [sExt compare:@"drmx"] == NSOrderedSame )
		{
			long nRes = NSRunAlertPanel(@"File downloaded", [NSString stringWithFormat:@"Do you want to open file:\n%@", [m_fileURL path]], @"Yes", @"No", nil);
			switch(nRes) {
			case NSAlertDefaultReturn:
				//NSLog(@"%@", m_fileURL );
				[self openFileFromURL:m_fileURL];
				break;
			case NSAlertAlternateReturn:
				break;
			case NSAlertOtherReturn:
				break;
			}
		}
		else
		{
			NSRunAlertPanel(@"File downloaded", [m_fileURL path], @"OK", nil, nil);
		}
	}
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
	NSLog(@"Download error: %@", error);
	NSString* s = nil;
	
	if ( [error code] == -1100 && [error domain] == NSURLErrorDomain )
		s = [NSString stringWithFormat:@"Invalid URL - Please check URL is valid and has correct upper/lower case usage\n%@", m_originalURL];//[error localizedFailureReason], [error localizedRecoverySuggestion]];
	else
		s = [NSString stringWithFormat:@"%@\n%@", [error localizedDescription], m_originalURL];//[error localizedFailureReason], [error localizedRecoverySuggestion]];

	NSRunAlertPanel(@"Error", s, @"OK", nil, nil);
    m_downloading = NO;
	
	[self updateUI:NO];
}

- (void) updateUI:(BOOL)bDownloading
{
	[m_table setEnabled:!bDownloading];
	[m_ok setEnabled:!bDownloading];
	[m_url setEnabled:!bDownloading];
	
	if ( bDownloading == NO )
	{
//		[m_progress setIndeterminate:YES];
		[m_progress setDoubleValue:0.0];
		[m_cancel setTitle:@"Close"];
		[m_time setStringValue:@"00min 00s"];
		[m_percentage setStringValue:@"0%"];
		[m_bytes setStringValue:@"0/0"];
		m_old = 0;
	}
	else
	{
		[m_cancel setTitle:@"Cancel"];
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqual:@"Filename"])
	{
		NSString *sItem = [m_downloads objectAtIndex:row];
		NSRange r = [sItem rangeOfString:@" -> " ];
		if ( r.location == NSNotFound )
		{
			((DownloadCell *)cell).originalURL = nil;
		}
		else
		{
			NSString *sUrl = [sItem substringToIndex:r.location];
			NSURL *url = [NSURL URLWithString:sUrl];
			((DownloadCell *)cell).originalURL = url;
		}
		//((DownloadItem *)[m_downloads objectAtIndex:row]).originalURL;
        [cell setFont:[NSFont systemFontOfSize:TEXT_SIZE]];
		[cell setEditable:NO];
		[cell setSelectable:NO];
    }
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
 
    // get an existing cell with the MyView identifier if it exists
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
 
    // There is no existing cell to reuse so we will create a new one
    if (result == nil) {
 
         // create the new NSTextField with a frame of the {0,0} with the width of the table
         // note that the height of the frame is not really relevant, the row-height will modify the height
         // the new text field is then returned as an autoreleased object
         result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
 
         // the identifier of the NSTextField instance is set to MyView. This
         // allows it to be re-used
         result.identifier = @"MyView";
      }
 
      // result is now guaranteed to be valid, either as a re-used cell
      // or as a new cell, so set the stringValue of the cell to the
      // nameArray value at row
	 // DownloadItem* ii = [m_downloads objectAtIndex:row];
	 // NSLog(@"row:%d %@", row, ii);
	//result.stringValue = [[ii originalURL] absoluteString];
	
	result.stringValue = [m_downloads objectAtIndex:row];
      // return the result.
      return result;
 
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger ii = [m_table selectedRow];
	
	if ( ii >= 0 )
	{
		NSString* sItem = [m_downloads objectAtIndex:ii];
		NSRange r = [sItem rangeOfString:@" -> " ];
		if ( r.location != NSNotFound )
		{
			NSString *sUrl = [sItem substringToIndex:r.location];
			//NSURL *url = [NSURL URLWithString:sUrl];
			//NSLog(@"--> %@", sUrl);
			m_url.stringValue = sUrl;
		}
	}
	
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return m_downloads.count;
}
@end
