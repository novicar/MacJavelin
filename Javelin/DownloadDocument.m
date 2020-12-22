/*
     File: MyDocument.m
 Abstract: MyDocument manages a list of downloaded items.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "DownloadDocument.h"
#import "DownloadItem.h"
#import "DownloadCell.h"
#import "DownloadProtocol.h"
#import "General.h"

NSString* const DwnDocumentUTI = @"com.drumlinsecurity.dwnlist";

// DownloadItem will be used directlty as the items in preview panel
// The class just need to implement the QLPreviewItem protocol
@interface DownloadItem (QLPreviewItem) <QLPreviewItem>

@end

@implementation DownloadItem (QLPreviewItem)

- (NSURL *)previewItemURL
{
    return self.resolvedFileURL;
}

- (NSString *)previewItemTitle
{
    return [self.originalURL absoluteString];
}

@end

@implementation DownloadDocument

@synthesize prot;

- (id)init
{
    self = [super init];
    if (self) {
        downloads = [[NSMutableArray alloc] init];
        selectedIndexes = [[NSIndexSet alloc] init];
		
		m_numberFormat = [[NSNumberFormatter alloc] init];
		m_numberFormat.usesGroupingSeparator = YES;
		m_numberFormat.groupingSeparator = @",";
		m_numberFormat.groupingSize = 3;
		
		

    }
    return self;
}

- (void)awakeFromNib
{
	[downloadsTableView setDoubleAction:@selector(doubleClick:)];
}

/*
- (void)dealloc
{
    [download cancel];
    [download release];
    [originalURL release];
    [fileURL release];
    [downloads release];
    [selectedDownloads release];
    [super dealloc];
}
*/
- (NSString *)windowNibName
{
    return @"DownloadDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableArray* propertyList = [[NSMutableArray alloc] initWithCapacity:[downloads count]];
    
    for (DownloadItem* item in downloads) {
        id plistForItem = [item propertyListForSaving];
        if (plistForItem) {
            [propertyList addObject:plistForItem];
        }
    }
    
    NSData* result = [NSPropertyListSerialization dataWithPropertyList:propertyList
                                                                format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    //[propertyList release];
    
    //assert(result);
    
    return result;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSArray* propertyList = [NSPropertyListSerialization propertyListWithData:data
                                                                      options:NSPropertyListImmutable
                                                                       format:NULL error:outError];
    if (!propertyList) {
        return NO;
    }
    
    if (![propertyList isKindOfClass:[NSArray class]]) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:NULL];
        }
        return NO;
    }
    
    NSMutableArray* observableDownloads = [self mutableArrayValueForKey:@"downloads"];
    [observableDownloads removeAllObjects];
    
    for (id plistItem in propertyList) {
        DownloadItem* item = [[DownloadItem alloc] initWithSavedPropertyList:plistItem];
        if (item) {
            [observableDownloads addObject:item];
            //[item release];
        }
    }
    
    return YES;
}

-(void)downloadStop
{
	[download cancel];
	self.downloading = NO;
	[m_button setTitle:DOWNLOAD];
}

-(void)downloadStart
{
 /*   NSString* urlString = [downloadURLField stringValue];
    assert(urlString);
    
    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([urlString length] == 0) {
        NSBeep();
        return;
    }
    
    NSURL* url = [NSURL URLWithString:urlString];
    if (!url) {
        NSBeep();
        return;
    }
    
    originalURL = [url copy];
	
	*/
	
	///////////////////////
	NSString* urlString = [downloadURLField stringValue];
	if ( urlString.length == 0 )
	{
		NSRunAlertPanel(@"Error", @"Please enter URL", @"OK", nil, nil);
		return;
	}
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
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

	if ( url.lastPathComponent == nil || url.lastPathComponent.length == 0 )
	{
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"You must include file name in URL:\n %@", urlString], @"OK", nil, nil);
		return;
	}
	
	NSString* sExt = [urlString pathExtension];
	
	if ( [sExt caseInsensitiveCompare:@"xml"] == NSOrderedSame || [sExt caseInsensitiveCompare:@"pdf"] == NSOrderedSame ||
			[sExt caseInsensitiveCompare:@"drm"] == NSOrderedSame || [sExt caseInsensitiveCompare:@"drmx"] == NSOrderedSame ||
			[sExt caseInsensitiveCompare:@"drmz"] == NSOrderedSame/* || [sExt caseInsensitiveCompare:@"zip"] == NSOrderedSame*/)
	{
		//int nRes = [self startDownloading:urlString];
		
		
	    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
		self.downloadIsIndeterminate = YES;
		self.downloadProgress = 0.0f;
		self.downloading = YES;
		originalURL = [url copy];
    
		download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
    
		[m_button setTitle:STOP];
	
		[[downloadsTableView window] makeFirstResponder:downloadsTableView];

	}
	else
	{
		NSRunAlertPanel(@"Error", [NSString stringWithFormat:@"Unable to download this type [*.%@] of file", sExt], @"OK", nil, nil);
	}

	///////////////////////
}

- (IBAction)startDownload:(id)sender
{
    if ( downloading )
		[self downloadStop];
	else
		[self downloadStart];
    
}

@synthesize downloadProgress, downloadIsIndeterminate;

-(NSArray*) selectedDownloads
{
	return [selectedDownloads copy];
}

-(NSIndexSet*) selectedIndexes
{
	return [selectedIndexes copy];
}

- (void)setSelectedIndexes:(NSIndexSet *)indexSet
{
    if (indexSet != selectedIndexes) {
        indexSet = [indexSet copy];
        //[selectedIndexes release];
        selectedIndexes = indexSet;
        self.selectedDownloads = [downloads objectsAtIndexes:indexSet];
    }
}

- (void)setSelectedDownloads:(NSArray *)array
{
    if (array != selectedDownloads) {
        array = [array copy];
        //[selectedDownloads release];
        selectedDownloads = array;
        [previewPanel reloadData];
    }
}

// Download support

- (void)displayDownloadProgressView
{
    if (!downloading) {
        return;
    }

    // position and size downloadsProgressFrame appropriately
    NSRect downloadProgressFrame = [downloadProgressView frame];
    NSRect downloadsFrame = [downloadsView frame];
    downloadProgressFrame.size.width = downloadsFrame.size.width;
    downloadProgressFrame.origin.y = NSMaxY(downloadsFrame);
    [downloadProgressView setFrame:downloadProgressFrame];
    
    [[[downloadsView superview] animator] addSubview:downloadProgressView positioned:NSWindowBelow relativeTo:downloadsView];
}

- (void)startDisplayingProgressView
{
    if (!downloading || [downloadProgressView superview]) {
        return;
    }
    
    
    // we are starting a download, display the download progress view
    NSRect downloadProgressFrame = [downloadProgressView frame];
    NSRect downloadsFrame = [downloadsView frame];
    
    // reduce the size of the downloads view
    downloadsFrame.size.height -= downloadProgressFrame.size.height;
    
    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setDuration:0.2];
    
    [[downloadsView animator] setFrame:downloadsFrame];
    
    [NSAnimationContext endGrouping];
    
    [self performSelector:@selector(displayDownloadProgressView) withObject:nil afterDelay:0.2];
}

- (void)hideDownloadProgressView
{
    if (downloading) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayDownloadProgressView) object:nil];
    
    // we are ending a download, remove the download progress view
    [downloadProgressView removeFromSuperview];

    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    [[downloadsView animator] setFrame:[[downloadsView superview] bounds]];
    
    [NSAnimationContext endGrouping];
}
-(BOOL)isDownloading
{
	return downloading;
}

- (void)setDownloading:(BOOL)flag
{
    if (!flag != !downloading) {
        if (flag) {
            [self performSelector:@selector(startDisplayingProgressView) withObject:nil afterDelay:0.0];
        } else {            
            [self performSelector:@selector(hideDownloadProgressView) withObject:nil afterDelay:0.1];
            //[originalURL release];
            originalURL = nil;
            //[fileURL release];
            fileURL = nil;
            //[download release];
            download = nil;
        }
        downloading = flag;
    }
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response;
{
    expectedContentLength = [response expectedContentLength];
    if (expectedContentLength > 0.0) {
        self.downloadIsIndeterminate = NO;
        downloadedSoFar = 0;
		m_startTime = [[NSDate alloc] init];
		[m_progress setMaxValue:100];
		[m_progress setMinValue:0];
		
    }
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    downloadedSoFar += length;
    if (downloadedSoFar >= expectedContentLength) {
        // the expected content length was wrong as we downloaded more than expected
        // make the progress indeterminate
        self.downloadIsIndeterminate = YES;
    } else {
		self.downloadProgress = 100.0f * (float)downloadedSoFar / (float)expectedContentLength;
		
		NSString *soFarString = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:downloadedSoFar]];
		NSString *expected = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:expectedContentLength]];
		[bytes setStringValue:[NSString stringWithFormat:@"%@/%@", soFarString, expected]];
		[percentage setStringValue:[NSString stringWithFormat:@"%d%%", (int)downloadProgress]];
		NSDate* now = [NSDate date];
		NSTimeInterval elapsed = [now timeIntervalSinceDate:m_startTime];
		
		if ( elapsed > 0 )
		{
			long seconds;// = lroundf(elapsed); // Modulo (%) operator below needs int or long

			float fBytesPerSecond = (float)(downloadedSoFar / elapsed);//bytes per second
			float f1 = (float)((expectedContentLength-downloadedSoFar) / fBytesPerSecond);
			
			if ( fabs(f1-m_old) > 1 )
			{
				seconds = lroundf(f1);
		//		int hour = seconds / 3600;
				int mins = (int)(seconds / 60);
				int secs = seconds % 60;
				//NSLog(@"bps:%f f1:%f s:%lu", fBytesPerSecond, f1, seconds);
				if ( mins > 99 )
					[time setStringValue:@"100+ min"];
				else
					[time setStringValue:[NSString stringWithFormat:@"%02dmin %02ds", mins, secs]];
					
				m_old = f1;
			}
		}
    }
}


- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename
{
	//NSArray* aa = [[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask];
	//NSString* s = [[aa objectAtIndex:0] absoluteString];
	NSURL *urlHome = [NSURL fileURLWithPath:NSHomeDirectory()];
	NSString* s = [urlHome absoluteString];
	NSString* path = [s stringByAppendingPathComponent:filename];
	NSString* urlTextEscaped = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL* url = [NSURL URLWithString:urlTextEscaped];
	path = [url path];
	//NSLog(@"%@", path);
	
	NSRange r = [path rangeOfString:@"/localhost"];
	if ( r.location != NSNotFound )
	{
		path = [path substringFromIndex:r.location+r.length];
	}

	fileURL = [[NSURL alloc] initFileURLWithPath:path isDirectory:NO];
    [aDownload setDestination:path allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
    fileURL = [[NSURL alloc] initFileURLWithPath:path];
}

- (void)downloadDidFinish:(NSURLDownload *)urldownload
{
    if (originalURL && fileURL) {
        DownloadItem* item = [[DownloadItem alloc] initWithOriginalURL:originalURL fileURL:fileURL];
		//check extensions
		NSString* sOriginal = [[[originalURL absoluteString] pathExtension] lowercaseString];
		NSString* sResolved = [[[fileURL absoluteString] pathExtension] lowercaseString];
		
		if ( [sOriginal isEqualToString:sResolved] == NO )
		{
			self.downloading = NO;
			[m_button setTitle:DOWNLOAD];
			NSRunAlertPanel(@"ERROR", @"File not found!", @"OK", nil, nil);
			return;
		}
		
        if (item) {
            [[self mutableArrayValueForKey:@"downloads"] addObject:item];
            //[item release];
            [self updateChangeCount:NSChangeDone];
			
			NSString* sExt = [[[[urldownload request] URL] pathExtension] lowercaseString];
			
			if ( [sExt compare:@"pdf"] == NSOrderedSame || [sExt compare:@"drm"] == NSOrderedSame || [sExt compare:@"drmz"] == NSOrderedSame || [sExt compare:@"drmx"] == NSOrderedSame )
			{
				long nRes = NSRunAlertPanel(@"File downloaded", [NSString stringWithFormat:@"Do you want to open file:\n%@", [fileURL path]], @"Yes", @"No", nil);
				switch(nRes) {
				case NSAlertDefaultReturn:
					//NSLog(@"%@", m_fileURL );
					[self openFileFromURL:fileURL];
					break;
				case NSAlertAlternateReturn:
					break;
				case NSAlertOtherReturn:
					break;
				}
			}
			/*else if ( [sExt compare:@"zip"] == NSOrderedSame )
			{
				NSString* sZipFile = [fileURL path];
				NSString* sDestDir = [sZipFile stringByDeletingLastPathComponent];
				NSURL* urlAppData = [General applicationDataDirectory];
				sDestDir = [[urlAppData absoluteString] stringByAppendingPathComponent:@"temp234"];
				NSFileManager* fm = [NSFileManager defaultManager];
				BOOL isDir = NO;
				BOOL isFile = [fm fileExistsAtPath:sDestDir isDirectory:&isDir];
				if ( isDir == NO )
				{
					[fm createDirectoryAtPath:sDestDir withIntermediateDirectories:YES attributes:nil error:nil];
				}
				if ( [self unzip:sZipFile toDestinationDir:sDestDir] )
				{
					//file unzipped OK - open the catalog
					//[self openCatalog:sXmlFile];
					
					//[self performSelector:@selector(openCatalog:) withObject:sXmlFile afterDelay:1];
					//[[General catalogStack] add:sXmlFile];
					return;
				}
				long nRes = NSRunAlertPanel(@"File downloaded", [NSString stringWithFormat:@"Do you want to open file:\n%@", [fileURL path]], @"Yes", @"No", nil);
				switch(nRes) {
					case NSAlertDefaultReturn:
						//NSLog(@"%@", m_fileURL );
						[self openFileFromURL:fileURL];
						break;
					case NSAlertAlternateReturn:
						break;
					case NSAlertOtherReturn:
						break;
				}
			}*/
			else
			{
				NSRunAlertPanel(@"File downloaded", [fileURL path], @"OK", nil, nil);
			}
        } else {
            NSLog(@"Can't create download item at %@", fileURL);
        }
    }
    
    self.downloading = NO;
	[m_button setTitle:DOWNLOAD];
}

-(BOOL)unzip:(NSString*)sZipFile toDestinationDir:(NSString*)sDestDir
{
	@try
	{
		NSTask *unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		//[unzip setArguments:[NSArray arrayWithObjects:@"-u", @"-d", sDestDir, sZipFile, nil]];
		[unzip setArguments:[NSArray arrayWithObjects:@"-d", sDestDir, sZipFile, nil]];
		
		NSPipe *aPipe = [[NSPipe alloc] init];
		[unzip setStandardOutput:aPipe];
		
		[unzip launch];
		[unzip waitUntilExit];
		
		return YES;
	}
	@catch(NSException* ex)
	{
		NSLog( @"Name: %@", ex.name);
		NSLog( @"Reason: %@", ex.reason );
		return NO;
	}
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
//  NSLog(@"Download failed! Error - %@ %@",
//          [error localizedDescription],
//          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
//    [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    self.downloading = NO;
	[m_button setTitle:DOWNLOAD];
	
	NSRunAlertPanel(@"Download Error", [General convertDomainError:[error code]], @"OK", nil, nil);
}

// table view delegate
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqual:@"Filename"]) {
        ((DownloadCell *)cell).originalURL = ((DownloadItem *)[downloads objectAtIndex:row]).originalURL;
        [cell setFont:[NSFont systemFontOfSize:TEXT_SIZE]];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger ii = [downloadsTableView selectedRow];
	
	if ( ii >= 0 )
	{
		DownloadItem* item = [downloads objectAtIndex:ii];
		
		[downloadURLField setStringValue:[[item originalURL] absoluteString]];
		//NSLog(@"item: %@", [item resolvedFileURL]);
	}
	
}


// Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    //[previewPanel release];
    previewPanel = nil;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [selectedDownloads count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [selectedDownloads objectAtIndex:index];
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    // redirect all key down events to the table view
    if ([event type] == NSKeyDown) {
        [downloadsTableView keyDown:event];
        return YES;
    }
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    NSInteger index = [downloads indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    }
        
    NSRect iconRect = [downloadsTableView frameOfCellAtColumn:0 row:index];
    
    // check that the icon rect is visible on screen
    NSRect visibleRect = [downloadsTableView visibleRect];
    
    if (!NSIntersectsRect(visibleRect, iconRect)) {
        return NSZeroRect;
    }
    
    // convert icon rect to screen coordinates
    iconRect = [downloadsTableView convertRectToBase:iconRect];
    iconRect.origin = [[downloadsTableView window] convertBaseToScreen:iconRect.origin];
    
    return iconRect;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    DownloadItem* downloadItem = (DownloadItem *)item;

    return downloadItem.iconImage;
}

-(BOOL)shouldClose
{
	return YES;
}

/*
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	return [downloads writeToFile:[[self fileURL] absoluteString]  atomically:YES];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if ( downloads )
	{
		[downloads removeAllObjects];
	}
	else
	{
		downloads = [[NSMutableArray alloc] init];
	}
	
	downloads = [NSArray arrayWithContentsOfURL:[self fileURL]];
	
	if ( downloads ) return YES;
	return NO;
}

- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	[super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}
*/
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	//[self writeToURL:[self fileURL] ofType:DwnDocumentUTI error:nil];
	//[self updateChangeCount:NSSaveOperation];
	[self saveDocument:self];
	if ( prot )
	{

		[prot windowClosed];
	}
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

-(void)openFileFromURL:(NSURL*)url
{
	[self saveDocument:self];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
}

- (IBAction)doubleClick:(id)sender
{
	long row = [downloadsTableView clickedRow];
	
	if ( row != -1 )
	{
		DownloadItem* item = [downloads objectAtIndex:row];
		if ( item != nil )
			[self openFileFromURL:[item resolvedFileURL]];
	}

}


@end
