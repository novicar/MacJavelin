//
//  CatalogWindowController.m
//  Javelin3
//
//  Created by Novica Radonic on 14/05/2018.
//

#import "CatalogWindowController.h"
#import "CatalogStack.h"
#import "General.h"
#import "Log.h"

@interface CatalogWindowController ()

@end

@implementation CatalogWindowController

- (id)initWithDirectory:(NSString*)sDirectory
{
	self = [[CatalogWindowController alloc] initWithWindowNibName:@"CatalogWindowController"];
	if (self) 
	{
		// Initialization code here.
		m_sInitialPath = sDirectory;
		NSString *path = [[NSBundle mainBundle] pathForResource:@"exit-arrow" ofType:@"png"];
		m_imageExit = [[NSImage alloc] initWithContentsOfFile:path];
		path = [[NSBundle mainBundle] pathForResource:@"down-arrow" ofType:@"png"];
		m_imageDownload = [[NSImage alloc] initWithContentsOfFile:path];
	}
	
	return self;
}

-(BOOL)windowShouldClose:(NSWindow*)sender
{
	if ( m_bDownloading )
	{
		[m_lblError setHidden:NO];
		[m_lblError setStringValue:@"Unable to close during download."];
		return NO;
	}
	return YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];
	CatalogStack* ppp = [General catalogStack];

	m_item = nil;
	m_sCurrentString = nil;
	m_sElementName = nil;
	m_contents = nil;
	[m_lblError setHidden:YES];
	[m_progress setHidden:YES];
	
	[m_collectionView setDataSource:self];
	//[self loadData:nil];
	[self loadXMLCatalog:[ppp getTop]];
	
	if (@available(macOS 10.13, *)) {
		[m_collectionView setFrameSize: m_collectionView.collectionViewLayout.collectionViewContentSize];
	}
	
	[m_txtURL setTarget:self];
	[m_txtURL setAction:@selector(download:)];
	//[m_collectionView becomeFirstResponder];
	[self.window makeFirstResponder:m_collectionView];
}


-(void)loadDirectory:(NSString*)sPath
{
	//populate the grid with XML documents
	NSFileManager* fm = [NSFileManager defaultManager];
	NSURL* myURL = [NSURL fileURLWithPath:sPath isDirectory:YES];
	NSArray * dirContents = 
	[fm contentsOfDirectoryAtURL:myURL
	  includingPropertiesForKeys:@[] 
						 options:NSDirectoryEnumerationSkipsHiddenFiles
						   error:nil];
	NSPredicate * fltr = [NSPredicate predicateWithFormat:@"pathExtension='xml'"];
	NSArray * onlyXMLs = [dirContents filteredArrayUsingPredicate:fltr];
	
	if ( onlyXMLs.count > 0 )
	{
		m_catalogItem = [[CatalogItem alloc] initWithNibName:@"CatalogItem" bundle:nil];
		//[m_collectionView setItemPrototype:m_catalogItem];
		
		m_contents = [[NSMutableArray alloc] initWithCapacity:onlyXMLs.count];
		for(int i=0; i<onlyXMLs.count; i++)
		{
			//NSLog(@"FILE: %@", [onlyXMLs objectAtIndex:i]);
			NSMutableDictionary* item = [[NSMutableDictionary alloc] init];
			NSString* sFile = [[onlyXMLs objectAtIndex:i] path];
			//NSURL* url = [NSURL fileURLWithPath:sFile isDirectory:NO];
			[item setObject:[[sFile lastPathComponent] stringByDeletingPathExtension] forKey:@"Name"];
			[item setObject:sFile forKey:@"URL"];
			[item setObject:@"" forKey:@"ThumbURL"];
			[item setObject:@"" forKey:@"PublisherName"];
			[item setObject:@"" forKey:@"PublisherURL"];
			[item setObject:@"" forKey:@"Authors"];
			[item setObject:@"" forKey:@"AuthorURL"];
			[item setObject:@"" forKey:@"Language"];
			[item setObject:@"" forKey:@"Edition"];
			[item setObject:@"" forKey:@"Description"];
			[item setObject:@"" forKey:@"Review"];
			[item setObject:@"" forKey:@"PrintLength"];
			[item setObject:@"" forKey:@"PublicationDate"];
			[item setObject:@"" forKey:@"Price"];
			[item setObject:@"" forKey:@"CurrencyCode"];
			[item setObject:@"" forKey:@"CatalogDirectory"];
			
			[m_contents setObject:item atIndexedSubscript:i];
			
			int nCount = (int)[m_collectionView numberOfItemsInSection:0];
			for( int i=0; i<nCount; i++)
			{
				CatalogItem* item = (CatalogItem*)[m_collectionView itemAtIndex:i];
				[item setProt:self];
			}
		}
		[m_collectionView setContent:m_contents];
	}
}

- (BOOL)parseXMLFile:(NSString *)pathToFile 
{
	BOOL success;
	NSURL *xmlURL = nil;
	
	xmlURL = [NSURL fileURLWithPath:pathToFile];
	NSXMLParser* myParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	[myParser setDelegate:self];
	[myParser setShouldResolveExternalEntities:YES];
	success = [myParser parse]; // return value not used
	// if not successful, delegate is informed of error
	
	return success;
}

-(void)checkCatalogDirectory:(NSString*)sCatalog
{
	NSString* sCatName = [[sCatalog lastPathComponent] stringByDeletingPathExtension];
	NSString* sCatDir = nil;
	
	if ( m_sCurrentCatalog == nil )
		sCatDir = [[[General catalogDirectory] stringByAppendingPathComponent:sCatName] stringByAppendingPathExtension:@"catdir"];
	else
		sCatDir = [[[m_sCurrentCatalog stringByDeletingLastPathComponent] stringByAppendingPathComponent:sCatName] stringByAppendingPathExtension:@"catdir"];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL bIsDir = NO;
	if ( [fm fileExistsAtPath:sCatDir isDirectory:&bIsDir] == NO )
	{
		[fm createDirectoryAtPath:sCatDir withIntermediateDirectories:YES attributes:nil error:nil];
	}
}


-(BOOL)loadXMLCatalog:(NSString*)sCatalogPath
{
	if ( m_contents != nil )
		[m_contents removeAllObjects];
	m_contents = nil;
	m_sInitialPath = sCatalogPath;
	m_sCurrentCatalog = nil;
	[m_collectionView reloadData];
	//[m_collectionView setContent:nil];
	
	if ( sCatalogPath == nil )
	{
		//show main catalog directory
		[self loadDirectory:[General catalogDirectory]];
		[m_btnBack setEnabled:NO];
		[m_btnDownload setImage:m_imageDownload];
		[m_btnDownload setEnabled:YES];
		[m_txtURL setHidden:NO];
		[m_txtURL setEnabled:YES];
		[[self window] setTitle:@"Catalogs"];
		return YES;
	}
	else
	{
		//open catalog XML file
		[m_btnBack setEnabled:YES];
		//[m_btnDownload setEnabled:NO];
		[m_btnDownload setEnabled:NO];
		[m_btnDownload setImage:m_imageExit];
		[m_txtURL setEnabled:NO];
		[m_txtURL setHidden:YES];

		[[self window] setTitle:[[sCatalogPath lastPathComponent] stringByDeletingPathExtension]];
		m_sCurrentCatalog = sCatalogPath;
		BOOL bRes = [self parseXMLFile:sCatalogPath];
		if ( bRes )
		{
			m_catalogItem = [[CatalogItem alloc] init];
			[m_catalogItem setCatalogDirectory:sCatalogPath];
			[m_catalogItem setProt:self];
			int nCount = (int)[m_collectionView numberOfItemsInSection:0];
			for( int i=0; i<nCount; i++)
			{
				CatalogItem* item = (CatalogItem*)[m_collectionView itemAtIndex:i];
				[item setProt:self];
				//[item setCatalogDirectory:sCatalogPath];
			}			
			//[m_collectionView setContent:m_contents];
			[m_collectionView reloadData];
			
			//check this catalog's directory
			[self checkCatalogDirectory:sCatalogPath];
			
			dispatch_async( dispatch_get_main_queue(), ^{
				[m_collectionView setNeedsDisplay:YES];
				[m_collectionView setNeedsLayout:YES];
				});
		}
		else
		{
			m_sCurrentCatalog = nil;
		}
		return bRes;
	}
}


-(void)loadData:(NSString*)sCatalogPath
{
	//NSNib *itemOneNib = [[NSNib alloc] initWithNibNamed:@"CatalogItem" bundle:nil];
	m_catalogItem = [[CatalogItem alloc] initWithNibName:@"CatalogItem" bundle:nil];
	/*
	 @synthesize Name=m_sName;
	 @synthesize URL=m_sURL;
	 @synthesize ThumbURL=m_sThumbURL;
	 @synthesize PublisherName=m_sPublisherName;
	 @synthesize PublisherURL=m_sPublisherURL;
	 @synthesize Authors=m_sAuthors;
	 @synthesize AuthorURL=m_sAuthorURL;
	 @synthesize Language=m_sLanguage;
	 @synthesize Edition=m_sEdition;
	 @synthesize Description=m_sDescription;
	 @synthesize Review=m_sReview;
	 @synthesize PrintLength=m_sPrintLength;
	 @synthesize PublicationDate=m_sPublicationDate;
	 @synthesize Price=m_sPrice;
	 @synthesize CurrencyCode=m_sCurrencyCode;*/
	m_contents = @[
				   @{@"Name":@"Name 1",
					 @"URL":@"Item 1 URL.drmz",
					 @"ThumbURL":@"Thmb URL1 ",
					 @"PublisherName":@"",
					 @"PublisherURL":@"",
					 @"Authors":@"",
					 @"AuthorURL":@"",
					 @"Language":@"",
					 @"Edition":@"",
					 @"Description":@"",
					 @"Review":@"",
					 @"PrintLength":@"",
					 @"PublicationDate":@"",
					 @"Price":@"",
					 @"CurrencyCode":@"USD"
					 },
				   @{@"Name":@"Name 2",
					 @"URL":@"Item 2 URL",
					 @"ThumbURL":@"Thmb URL2 ",
					 @"PublisherName":@"",
					 @"PublisherURL":@"",
					 @"Authors":@"",
					 @"AuthorURL":@"",
					 @"Language":@"",
					 @"Edition":@"",
					 @"Description":@"",
					 @"Review":@"",
					 @"PrintLength":@"",
					 @"PublicationDate":@"",
					 @"Price":@"",
					 @"CurrencyCode":@"GBP"
					 },
				   @{@"Name":@"Name 3",
					 @"URL":@"Item 3 URL",
					 @"ThumbURL":@"Thmb URL3 ",
					 @"PublisherName":@"",
					 @"PublisherURL":@"",
					 @"Authors":@"",
					 @"AuthorURL":@"",
					 @"Language":@"",
					 @"Edition":@"",
					 @"Description":@"",
					 @"Review":@"",
					 @"PrintLength":@"",
					 @"PublicationDate":@"",
					 @"Price":@"",
					 @"CurrencyCode":@"HRK"
					 },
				   @{@"Name":@"Name 4",
					 @"URL":@"Item 4 URL",
					 @"ThumbURL":@"Thmb URL4 ",
					 @"PublisherName":@"",
					 @"PublisherURL":@"",
					 @"Authors":@"",
					 @"AuthorURL":@"",
					 @"Language":@"",
					 @"Edition":@"",
					 @"Description":@"",
					 @"Review":@"",
					 @"PrintLength":@"",
					 @"PublicationDate":@"",
					 @"Price":@"",
					 @"CurrencyCode":@"HRK"
					 },
				   @{@"Name":@"Name 5",
					 @"URL":@"Item 5 URL",
					 @"ThumbURL":@"Thmb URL5 ",
					 @"PublisherName":@"",
					 @"PublisherURL":@"",
					 @"Authors":@"",
					 @"AuthorURL":@"",
					 @"Language":@"",
					 @"Edition":@"",
					 @"Description":@"",
					 @"Review":@"",
					 @"PrintLength":@"",
					 @"PublicationDate":@"",
					 @"Price":@"",
					 @"CurrencyCode":@"HRK"
					 }
				   
				   
				   ];
	[m_collectionView setItemPrototype:m_catalogItem];
	//[m_collectionView setContent:m_contents];
	
	int nCount = (int)[m_collectionView numberOfItemsInSection:0];
	for( int i=0; i<nCount; i++)
	{
		CatalogItem* item = (CatalogItem*)[m_collectionView itemAtIndex:i];
		[item setProt:self];
	}
}

- (BOOL) openCatalog:(NSString*)sCatalog
{
	NSString* sExt = [[sCatalog pathExtension] lowercaseString];
	if ( [sExt isEqualToString:@"zip"] )
	{
		[self performSelectorOnMainThread:@selector(openZippedCatalog:) withObject:sCatalog waitUntilDone:YES];
		return YES;
	}
	else
	{
		return [self loadXMLCatalog:sCatalog];
	}
}

-(void)openDocumentAndCloseWindow:(NSString*)sDocument
{
	NSString* sExt = [[sDocument pathExtension] lowercaseString];
	if ( [sExt isEqualToString:@"zip"] )
	{
		//[self performSelector:@selector(loadXMLCatalog:) withObject:sCatalog afterDelay:1];
		//[self openZippedCatalog:sDocument];
		//[self performSelector:@selector(openZippedCatalog:) withObject:sDocument afterDelay:0.5];
		[self performSelectorOnMainThread:@selector(openZippedCatalog:) withObject:sDocument waitUntilDone:YES];
	}
	else
	{
		NSURL* url = [NSURL fileURLWithPath:sDocument isDirectory:NO];
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler:
		 ^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) 
		 {
			 if ( error == nil )
			 {
				 NSLog(@"CLOSE");
				 //[NSApp endSheet:[self window] returnCode:0];
				 //[[self window] orderOut: self];
				 //[[self window] close];
			 }
		 }
		 ];
	}
}



-(void)downloadFile:(NSURL*)urlFile toLocation:(NSString*)sDestFIle autoOpen:(BOOL)bOpenFile fromDropbox:(BOOL)bDropbox
{
	//NSURLRequest* theRequest = [NSURLRequest requestWithURL:urlFile];
	
	//m_bDownloadIsIndeterminate = YES;
	//m_fDownloadProgress = 0.0f;
	m_bDownloading = YES;
	if ( bOpenFile )
	{
		[m_progress setHidden:NO];
		[m_progress setIndeterminate:YES];
		[m_progress setUsesThreadedAnimation:YES];
		[m_progress startAnimation:nil];
		[m_btnDownload setImage:m_imageExit];
		[m_btnDownload setEnabled:YES];
		[m_txtURL setEnabled:NO];
	}
	//NSLog(@"--> %@", urlFile);
	//NSLog(@"%@", sDestFIle);
	//NSLog(@"%d", bOpenFile);
	/*	NSURLRequest *theRequest = [NSURLRequest requestWithURL:urlFile
	 cachePolicy:NSURLRequestUseProtocolCachePolicy
	 timeoutInterval:6000.0];*/

	if ( bDropbox )
	{
		//urlFile que
	}

	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:urlFile                                                                        
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:30.0];
	
	//[[NSRunLoop currentRunLoop] run];
	NSURLSession* session = [NSURLSession sharedSession];
	
	m_downloadTask = 
	[session downloadTaskWithURL:urlFile 
			   completionHandler:
	 ^(NSURL *location, NSURLResponse *response, NSError *error) 
	 {
		 if ( bOpenFile )
		 {
			 dispatch_async(dispatch_get_main_queue(), ^(void){
				 //Run UI Updates
				 [m_progress stopAnimation:nil];
				 [m_progress setHidden:YES];
				 [m_btnDownload setEnabled:(m_sCurrentCatalog==nil)];
				 [m_btnDownload setImage:m_imageDownload];
				 [m_txtURL setEnabled:(m_sCurrentCatalog==nil)];
				 [m_txtURL setHidden:(m_sCurrentCatalog!=nil)];
			 });
		 }
		 
		 if (error == nil) 
		 {
			 //NSLog(@"FINISHED: %@", location);
			 m_bDownloading = NO;
			 BOOL bOK = YES;
			 if ( response != nil && [[response MIMEType] isEqualToString:@"text/html"] == YES )
			 {
				 bOK = NO;
				 NSFileManager *fm = [NSFileManager defaultManager];
				 if ( [fm isReadableFileAtPath:[location path]] )
				 {
					 NSURL* url = [location URLByAppendingPathExtension:@"html"];
					 BOOL b = [fm moveItemAtURL:location toURL:url error:nil];
					 
					 if ( b )
						 [[NSWorkspace sharedWorkspace] openURL:url];
				 } 
			 }
			 NSError *err = nil;
			 NSFileManager *fileManager = [NSFileManager defaultManager];
			 
			 if ( bOK && [fileManager isReadableFileAtPath:[location path]] )
			 {
				 dispatch_async(dispatch_get_main_queue(), ^(void){
					 [self doRefresh];
				 });
				 
				 NSURL* urlDest = [NSURL fileURLWithPath:sDestFIle isDirectory:NO];
				 [fileManager removeItemAtURL:urlDest error:nil];
				 BOOL bRes = [fileManager moveItemAtURL:location toURL:urlDest error:&err];
				 //BOOL bRes = [fileManager copyItemAtURL:location toURL:urlDest error:&err];
				 
				 if ( bRes )
				 {
					 NSString* sExt = [[[urlFile absoluteString] pathExtension] lowercaseString]; 
					 if ( bOpenFile )
					 {
						 if ( [sExt isEqualToString:@"zip" ] )
							 [self openZippedCatalog:sDestFIle];
						 else
							 [self openDocumentAndCloseWindow:sDestFIle];
					 }
					 m_bDownloading = NO;
				 }
				 else if ( err != nil )
				 {
					 m_bDownloading = NO;
					 //error while moving the downloaded file
					 dispatch_async(dispatch_get_main_queue(), ^(void){
						 [m_lblError setHidden:NO];
						 [m_lblError setStringValue:[err localizedDescription]];
						 
						 //NSLog(@"1 %@", [err description]);
						 //NSLog(@"2 %d", (int)[err code]);
						 //NSLog(@"3 %@", [err userInfo]);
						 //NSLog(@"4 %@", [err localizedFailureReason]);
						 //NSLog(@"1 %@", [err localizedRecoverySuggestion]);
						 
					 });
				 }
				 else
				 {
					 m_bDownloading = NO;
					 dispatch_async(dispatch_get_main_queue(), ^(void){
						[m_lblError setHidden:NO];
						[m_lblError setStringValue:@"Unknown error occured. Unable to download document."];
						NSLog(@"downloadFile: %@", urlFile);
					 });
				 }
				 
			 }
			 else
				 m_bDownloading = NO;
		 }
		 else
		 {
			 m_bDownloading = NO;
			 dispatch_async(dispatch_get_main_queue(), ^(void){
				 [m_lblError setHidden:NO];
				 [m_lblError setStringValue:[error localizedDescription]];
				 
			/*	 NSLog(@"1 %@", [error description]);
				 NSLog(@"2 %d", (int)[error code]);
				 NSLog(@"3 %@", [error userInfo]);
				 NSLog(@"4 %@", [error localizedFailureReason]);
				 NSLog(@"1 %@", [error localizedRecoverySuggestion]);*/
			 });
		 }
	 }
	 ];
	
	[m_downloadTask resume];
}


-(BOOL)downloadNewCatalog:(NSString*)sURL toDirectory:(NSString*)sDestDir openCatalog:(NSString*)sCatalogPath
{
	if ([sURL rangeOfString:@"://"].location == NSNotFound)
	{
		sURL = [NSString stringWithFormat:@"http://%@", sURL];
	}
	
	NSURL* url = [NSURL URLWithString:sURL];
	
	if ( url == nil || [url scheme] == nil || [url host] == nil || [url path] == nil )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Alert"];
		[alert setInformativeText:[NSString stringWithFormat:@"ERROR: Wrong URL. %@", sURL]];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
	else
	{
		m_bDownloading = YES;
		NSString* sPath = [url path];
		NSString* sExt = [[sPath pathExtension] lowercaseString]; 
		if ( [sExt isEqualToString:@"xml" ] || [sExt isEqualToString:@"zip"] )
		{
			//OK - you can download that
			////////////
			[m_progress setHidden:NO];
			[m_progress setIndeterminate:YES];
			[m_progress setUsesThreadedAnimation:YES];
			[m_progress startAnimation:nil];
			[m_btnDownload setImage:m_imageExit];
			[m_btnDownload setEnabled:YES];
			
			NSURLSession* session = [NSURLSession sharedSession];
			
			NSURLSessionDownloadTask *downloadTask = 
			[session downloadTaskWithURL:url 
					   completionHandler:
			 ^(NSURL *location, NSURLResponse *response, NSError *error) 
			 {
				 dispatch_async(dispatch_get_main_queue(), ^(void){
					 //Run UI Updates
					 [m_progress stopAnimation:nil];
					 [m_progress setHidden:YES];
					 [m_btnDownload setEnabled:(m_sCurrentCatalog==nil)];
					 [m_btnDownload setImage:m_imageDownload];
					 [m_txtURL setEnabled:(m_sCurrentCatalog==nil)];
					 [m_txtURL setHidden:(m_sCurrentCatalog!=nil)];
				 });
				 m_bDownloading = NO;
				 if (error == nil) 
				 {
					 //NSLog(@"FINISHED: %@", location);
					 BOOL bOK = YES;
					 if ( response != nil )
					 {
						 //NSLog(@"%@",[response suggestedFilename]);
						 //NSLog(@"%@",[response MIMEType]);
						 //NSLog(@"%@",[response URL]);
						 if ( [[response MIMEType] isEqualToString:@"text/html"] == YES )
						 {
							 bOK = NO;
							 
							 NSFileManager *fm = [NSFileManager defaultManager];
							 if ( [fm isReadableFileAtPath:[location path]] )
							 {
								 NSURL* url = [location URLByAppendingPathExtension:@"html"];
								 BOOL b = [fm moveItemAtURL:location toURL:url error:nil];
								 
								 if ( b )
									 [[NSWorkspace sharedWorkspace] openURL:url];
							 } 
							 //Didn't get XML file - probably error!
							 dispatch_async(dispatch_get_main_queue(), ^(void){
								 //Run UI Updates
								 [m_lblError setHidden:NO];
								 [m_lblError setStringValue:@"ERROR: Unable to download catalog"];
								 NSLog(@"downloadNewCatalog: %@", url);
							 });
						 }
					 }
					 
					 NSError *err = nil;
					 NSFileManager *fileManager = [NSFileManager defaultManager];
					 
					 if ( [fileManager isReadableFileAtPath:[location path]] && bOK )
					 {
						 NSString* sDestinationFile = sDestDir;
						 sDestinationFile = [sDestinationFile stringByAppendingPathComponent:[sPath lastPathComponent]];
						 NSURL* urlDest = [NSURL fileURLWithPath:sDestinationFile isDirectory:NO];
						 [fileManager removeItemAtURL:urlDest error:nil];
						 BOOL bRes = [fileManager moveItemAtURL:location toURL:urlDest error:&err];
						 sDestinationFile = [[sDestinationFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
						 
						 if ( bRes )
						 {
							 //[self openDocumentAndCloseWindow:sDestFIle];
							 dispatch_async(dispatch_get_main_queue(), ^(void){
								 //[self loadXMLCatalog:sCatalogPath];
								 if ( [sExt isEqualToString:@"zip"] )
								 {
									 //we have a zipped catalog
									 //NSString* sZippedCatalog = [[General catalogDirectory] stringByAppendingPathComponent:[sPath lastPathComponent]];
									 NSString* sZippedCatalog = [[sDestinationFile stringByDeletingPathExtension] stringByAppendingPathExtension:sExt];
									 [self openZippedCatalog:sZippedCatalog];
								 }
								 else if ( [self openCatalog:sCatalogPath] )
								 {
									 //create CATDIR folder for new catalog
									 [fileManager createDirectoryAtPath:sDestinationFile withIntermediateDirectories:YES attributes:nil error:nil];
									 if ( sCatalogPath != nil )
									 {
										// [self addLevel:sCatalogPath];
										 [[General catalogStack] add:sCatalogPath];
									 }
								 }
								 
							 });
						 }
						 else
						 {
							 dispatch_async(dispatch_get_main_queue(), ^(void){
								 [m_lblError setHidden:NO];
								 [m_lblError setStringValue:[err localizedDescription]];
								 
								/* NSLog(@"1 %@", [err description]);
								 NSLog(@"2 %d", (int)[err code]);
								 NSLog(@"3 %@", [err userInfo]);
								 NSLog(@"4 %@", [err localizedFailureReason]);
								 NSLog(@"1 %@", [err localizedRecoverySuggestion]);*/
							 });
							 
						 }
					 }
					 
				 }
				 else
				 {
					 dispatch_async(dispatch_get_main_queue(), ^(void){
						 [m_lblError setHidden:NO];
						 [m_lblError setStringValue:[error localizedDescription]];
						 
						 /*NSLog(@"1 %@", [error description]);
						 NSLog(@"2 %d", (int)[error code]);
						 NSLog(@"3 %@", [error userInfo]);
						 NSLog(@"4 %@", [error localizedFailureReason]);
						 NSLog(@"1 %@", [error localizedRecoverySuggestion]);*/
					 });
				 }
			 }
			 ];
			
			[downloadTask resume];
			////////////
		}
		else
		{
			m_bDownloading = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Error"];
			[alert setInformativeText:[NSString stringWithFormat:@"ERROR: Only catalogs can be downloaded. %@", sURL]];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
	}
}

-(void)deleteItem:(CatalogItem*)pItem
{
	NSURLComponents *components = [[NSURLComponents alloc] initWithString:pItem.URL];
	
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [General catalogDirectory];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sItemURL = pItem.URL;
	BOOL bDropbox = NO;
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[[pItem URL] lastPathComponent]];
	
	if ( components != nil && [components query] != nil )
	{
		sExtension = [[[components path] pathExtension] lowercaseString];
		bDropbox = YES;
		sItemURL = [NSString stringWithFormat:@"%@://%@%@?dl=1", [components scheme], [components host], [components path]];
		sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
	}
	
	if ( [sExtension isEqualToString:@"xml"] || [sExtension isEqualToString:@"zip"] )
	{
		NSLog(@"Delete catalog");
		NSError* err = nil;
		//delete XML
		BOOL bRes = [[NSFileManager defaultManager] removeItemAtPath:sDestFileName error:&err];
		
		//delete CatDir
		NSString* sCatdir = [ [sDestFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
		bRes = [[NSFileManager defaultManager] removeItemAtPath:sCatdir error:&err];
		
		//delete zip file (if exists)
		if ( [sExtension isEqualToString:@"xml"] )
			sCatdir = [ [sDestFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"zip"];
		else
			sCatdir = [ [sDestFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
		bRes = [[NSFileManager defaultManager] removeItemAtPath:sCatdir error:&err];
		
		[self doRefresh];
	}
	else if ( [sExtension isEqualToString:@"pdf"] || [sExtension isEqualToString:@"drmz"] )
	{
		NSError* err = nil;
		//delete document
		BOOL bRes = [[NSFileManager defaultManager] removeItemAtPath:sDestFileName error:&err];
		[self doRefresh];
	}

}

-(void)displayItem:(CatalogItem*)pItem
{
	NSMutableString* s = [[NSMutableString alloc] initWithString:@"--------------\r\n"];
	
	if ( pItem.Name.length > 0 )
		[s appendFormat:@"Name: %@\r\n", pItem.Name];

	if ( pItem.Description.length > 0 )
		[s appendFormat:@"Description: %@\r\n", pItem.Description];

	if ( pItem.URL.length > 0 )
		 [s appendFormat:@"URL: %@\r\n", pItem.URL];

	if ( pItem.Subtitle.length > 0 )
		[s appendFormat:@"Subtitle: %@\r\n", pItem.Subtitle];

	if ( pItem.ISBN.length > 0 )
		[s appendFormat:@"ISBN: %@\r\n", pItem.ISBN];
	
	if ( pItem.PublisherName.length > 0 )
		[s appendFormat:@"Publisher Name: %@\r\n", pItem.PublisherName];

	if ( pItem.PublisherURL.length > 0 )
		[s appendFormat:@"Publisher URL: %@\r\n", pItem.PublisherURL];

	if ( pItem.PublicationDate.length > 0 )
		[s appendFormat:@"Publication Date: %@\r\n", pItem.PublicationDate];

	if ( pItem.Authors.length > 0 )
		[s appendFormat:@"Authors: %@\r\n", pItem.Authors];

	if ( pItem.AuthorURL.length > 0 )
		[s appendFormat:@"Author URL: %@\r\n", pItem.AuthorURL];

	if ( pItem.Language.length > 0 )
		[s appendFormat:@"Language: %@\r\n", pItem.Language];

	if ( pItem.Edition.length > 0 )
		[s appendFormat:@"Edition: %@\r\n", pItem.Edition];


	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"INFO"];
	[alert setInformativeText:s];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
}

-(void)refreshItem:(CatalogItem*)pItem
{
	NSURLComponents *components = [[NSURLComponents alloc] initWithString:pItem.URL];
	
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [General catalogDirectory];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sItemURL = pItem.URL;
	BOOL bDropbox = NO;
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[[pItem URL] lastPathComponent]];
	
	if ( components != nil && [components query] != nil )
	{
		sExtension = [[[components path] pathExtension] lowercaseString];
		bDropbox = YES;
		sItemURL = [NSString stringWithFormat:@"%@://%@%@?dl=1", [components scheme], [components host], [components path]];
		sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
	}
	
	NSURL *url = [NSURL URLWithString:[sItemURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ( [sExtension isEqualToString:@"xml"] || [sExtension isEqualToString:@"zip"] )
	{
		NSLog(@"refresh catalog");
		[self downloadFile:url toLocation:sDestFileName autoOpen:YES fromDropbox:NO];
		[self doRefresh];
	}
	else if ( [sExtension isEqualToString:@"pdf"] || [sExtension isEqualToString:@"drmz"] )
	{
		[self downloadFile:url toLocation:sDestFileName autoOpen:YES fromDropbox:NO];
		//[self doRefresh];
	}
}

-(void)openItemFolder:(CatalogItem*)pItem
{
	NSURLComponents *components = [[NSURLComponents alloc] initWithString:pItem.URL];
	
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [General catalogDirectory];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sItemURL = pItem.URL;
	BOOL bDropbox = NO;
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[[pItem URL] lastPathComponent]];
	
	if ( components != nil && [components query] != nil )
	{
		sExtension = [[[components path] pathExtension] lowercaseString];
		bDropbox = YES;
		sItemURL = [NSString stringWithFormat:@"%@://%@%@?dl=1", [components scheme], [components host], [components path]];
		sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
	}
	if ( [sExtension isEqualToString:@"xml"] || [sExtension isEqualToString:@"zip"] )
	{
		NSString* sDir = [[sDestFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
		[[NSWorkspace sharedWorkspace] openFile:sDir];
	}
	else
	{
		[[NSWorkspace sharedWorkspace] openFile:sCatName];
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertFirstButtonReturn)
	{
		NSLog(@"if (returnCode == NSAlertFirstButtonReturn)");
	}
	else if (returnCode == NSAlertSecondButtonReturn)
	{
		NSLog(@"else if (returnCode == NSAlertSecondButtonReturn)");
	}
	else if (returnCode == NSAlertThirdButtonReturn)
	{
		NSLog(@"else if (returnCode == NSAlertThirdButtonReturn)");
	}
	else
	{
		NSLog(@"All Other return code %ld",(long)returnCode);
	}
}

- (void)alertDidEnd1:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertFirstButtonReturn)
	{
		NSLog(@"if (returnCode == NSAlertFirstButtonReturn)");
		[m_downloadTask cancel];
		[m_lblError setHidden:YES];
		[m_progress setHidden:YES];
		[m_btnDownload setImage:m_imageDownload];
	}
	else if (returnCode == NSAlertSecondButtonReturn)
	{
		NSLog(@"else if (returnCode == NSAlertSecondButtonReturn)");
	}
	else if (returnCode == NSAlertThirdButtonReturn)
	{
		NSLog(@"else if (returnCode == NSAlertThirdButtonReturn)");
	}
	else
	{
		NSLog(@"All Other return code %ld",(long)returnCode);
	}
}

#pragma mark - NSCollectionViewDatasource -

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
	 numberOfItemsInSection:(NSInteger)section {
	
	// We are going to fake it a little.  Since there is only one section
	//NSLog(@"Section: %ld, count: %ld", (long)section, [m_contents count]);
	
	return [m_contents count];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
	 itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
	
	//NSLog(@"IndexPath: %@, Requested one: %ld", indexPath, [indexPath item]);
	//NSLog(@"Identifier: %@", [m_contents objectAtIndex:[indexPath item]]);
	
	CatalogItem *catalogItem = [m_collectionView makeItemWithIdentifier:@"CatalogItem" forIndexPath:indexPath];
	//CatalogItem* catalogItem = [[CatalogItem alloc] initWithNibName:@"CatalogItem" bundle:nil ];
	//CatalogItem* catalogItem = [[CatalogItem alloc] init];
	[catalogItem setCatalogDirectory:m_sCurrentCatalog];
	[catalogItem setRepresentedObject:[m_contents objectAtIndex:[indexPath item]]];
	//[catalogItem setCollectionView:self];
	
	[catalogItem setProt:self];
	[catalogItem redraw];
	//NSLog(@"[%ld] %@", [indexPath item], [catalogItem  Name] );
	//catalogItem.representedObject = [m_contents objectAtIndex:[indexPath item]];
	
	return catalogItem;
}



#pragma mark - NSCollectionViewDelegate -

- (NSSize)collectionView:(NSCollectionView *)collectionView
				  layout:(NSCollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath 
{
	//NSLog(@"%@", indexPath);
	
	NSSize size = NSMakeSize(150, 200);
	NSInteger width = 0;
	NSInteger height = 0;
	NSDictionary* item = [m_contents objectAtIndex:[indexPath item]];
	
	NSRect collectionFrame = [m_collectionView frame];
	
	width = collectionFrame.size.width;
	
	if ( width < 150-10 )
		size = NSMakeSize(width, 200);
	
	return size;
}

- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView 
						layout:(NSCollectionViewLayout *)collectionViewLayout 
		insetForSectionAtIndex:(NSInteger)section
{
	NSEdgeInsets e = NSEdgeInsetsMake(10, 10, 10, 10);
	
	return e;
}

- (CGFloat)collectionView:(NSCollectionView *)collectionView 
				   layout:(NSCollectionViewLayout *)collectionViewLayout 
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	CGFloat p = 5.0;
	
	return p;
}

- (CGFloat)collectionView:(NSCollectionView *)collectionView 
				   layout:(NSCollectionViewLayout *)collectionViewLayout 
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 5.0;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView 
				  layout:(NSCollectionViewLayout *)collectionViewLayout 
referenceSizeForHeaderInSection:(NSInteger)section
{
	return NSMakeSize(1, 1);
}

- (NSSize)collectionView:(NSCollectionView *)collectionView 
				  layout:(NSCollectionViewLayout *)collectionViewLayout 
referenceSizeForFooterInSection:(NSInteger)section
{
	return NSMakeSize(1, 1);
}

#pragma mark -- BUTTON ACTIONS --
-(IBAction) back:(id)sender
{
	if ( m_bDownloading )
		return;
	[m_txtURL setStringValue:@""];
	[m_lblError setHidden:YES];
	NSString* sFile = [[General catalogStack] getAndRemoveTop];
	sFile = [[General catalogStack] getTop];
	[self loadXMLCatalog:sFile];

}

-(IBAction) download:(id)sender
{
	[m_lblError setHidden:YES];

	if ( [[m_txtURL stringValue] length] == 0 && m_bDownloading == NO )
		return;
	
	if ( m_bDownloading )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Cancel download"];
		[alert addButtonWithTitle:@"Continue"];
		[alert setMessageText:@"Download In Progress"];
		[alert setInformativeText:@"Download in progress. Do you want to cancel download?"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd1:returnCode:contextInfo:) contextInfo:nil];
	}
	else
	{
		NSString* sURL = [[m_txtURL stringValue] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		
		if ( sURL.length == 0 )
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Error"];
			[alert setInformativeText:[NSString stringWithFormat:@"ERROR: Please enter a valid URL %@", sURL]];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
			
			return;
		}
		[self downloadNewCatalog:sURL toDirectory:[General catalogDirectory] openCatalog:nil];
	}
}

-(void)loadWithDelay:(NSString*) sCatalog
{
	//[self performSelector:@selector(loadXMLCatalog:) withObject:sCatalog afterDelay:1];
	[self loadXMLCatalog:sCatalog];
	[m_collectionView setHidden:YES];
	[m_collectionView setHidden:NO];
}
-(void)doRefresh
{
	[m_txtURL setStringValue:@""];
	[m_lblError setHidden:YES];
	if ( m_bDownloading )
		return;
	
	NSString* sCatalog = [[General catalogStack] getTop];
	if ( sCatalog == nil )
	{
		[self loadXMLCatalog:nil ];//reload home directory from file system
	}
	else
	{
		NSString* sCat = [m_sCatalogURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		NSURL* url = [NSURL URLWithString:sCat];
		NSString* sExt = [[sCat pathExtension] lowercaseString];
		
		m_bDownloading = YES;
		////////////
		[m_progress setHidden:NO];
		[m_progress setIndeterminate:YES];
		[m_progress setUsesThreadedAnimation:YES];
		[m_progress startAnimation:nil];
		
		NSURLSession* session = [NSURLSession sharedSession];
		
		NSURLSessionDownloadTask *downloadTask = 
		[session downloadTaskWithURL:url 
				   completionHandler:
		 ^(NSURL *location, NSURLResponse *response, NSError *error) 
		 {
			 dispatch_async(dispatch_get_main_queue(), ^(void){
				 //Run UI Updates
				 [m_progress stopAnimation:nil];
				 [m_progress setHidden:YES];
			 });
			 m_bDownloading = NO;
			 if (error == nil) 
			 {
				 //NSLog(@"FINISHED: %@", location);
				 BOOL bOK = YES;
				 if ( response != nil && [[response MIMEType] isEqualToString:@"text/html"] == YES )
					 bOK = NO;
				 
				 NSError *err = nil;
				 NSFileManager *fileManager = [NSFileManager defaultManager];
				 
				 if ( bOK && [fileManager isReadableFileAtPath:[location path]] )
				 {
					 NSURL* urlDest = [NSURL fileURLWithPath:m_sCurrentCatalog isDirectory:NO];
					 [fileManager removeItemAtURL:urlDest error:nil];
					 BOOL bRes = NO;
					 
					 if ( [sExt compare:@"zip"] != NSOrderedSame )
					 {
						 //ordinary file ( not zip )
						 bRes = [fileManager moveItemAtURL:location toURL:urlDest error:&err];
					 }
					 else
					 {
						 //zip file
						 //-(BOOL)unzip:(NSString*)sZipFile toDestinationDir:(NSString*)sDestDir
						 NSString* sDestDir = [[urlDest path] stringByDeletingLastPathComponent];
						 bRes = [self unzip:[location path] toDestinationDir:sDestDir];
					 }
					 
					 if ( bRes )
					 {
						 //[self openDocumentAndCloseWindow:sDestFIle];
						 dispatch_async(dispatch_get_main_queue(), ^(void){
							 [self loadXMLCatalog:m_sCurrentCatalog];
							 //[self loadWithDelay:m_sCurrentCatalog];
						 });
					 }
					 else
					 {
						 dispatch_async(dispatch_get_main_queue(), ^(void){
							 [m_lblError setHidden:NO];
							 [m_lblError setStringValue:[err localizedDescription]];
							 
							/* NSLog(@"1 %@", [err description]);
							 NSLog(@"2 %d", (int)[err code]);
							 NSLog(@"3 %@", [err userInfo]);
							 NSLog(@"4 %@", [err localizedFailureReason]);
							 NSLog(@"1 %@", [err localizedRecoverySuggestion]);*/
						 });
						 
					 }
				 }
				 
			 }
			 else
			 {
				 dispatch_async(dispatch_get_main_queue(), ^(void){
					 [m_lblError setHidden:NO];
					 [m_lblError setStringValue:[error localizedDescription]];
					 
					 /*NSLog(@"1 %@", [error description]);
					 NSLog(@"2 %d", (int)[error code]);
					 NSLog(@"3 %@", [error userInfo]);
					 NSLog(@"4 %@", [error localizedFailureReason]);
					 NSLog(@"1 %@", [error localizedRecoverySuggestion]);*/
				 });
			 }
		 }
		 ];
		
		[downloadTask resume];
		////////////
	}
	

}

-(IBAction) refresh:(id)sender
{
	[self doRefresh];
}

-(BOOL)unzip:(NSString*)sZipFile toDestinationDir:(NSString*)sDestDir
{
	@try
	{
		NSTask *unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		//[unzip setArguments:[NSArray arrayWithObjects:@"-u", @"-d", sDestDir, sZipFile, nil]];
		[unzip setArguments:[NSArray arrayWithObjects:@"-o", @"-d", sDestDir, sZipFile, nil]];
		
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

#pragma mark -- PARSER DELEGATE ----
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	m_sElementName = elementName;
	
	if ( [elementName isEqualToString:@"JavelinCatalog"]) 
	{
		if (!m_contents)
			m_contents = [[NSMutableArray alloc] init];
		else
		{
			for (int i=0; i<[m_contents count]; i++ )
			{
				CatalogItem* item = [m_contents objectAtIndex:i];
				item = nil;
			}
			[m_contents removeAllObjects];
		}
		return;
	}
	
	if ( [elementName isEqualToString:@"Document"] ) 
	{
		m_item = [[NSMutableDictionary alloc] init];
		return;
	}
	
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	if ( m_sElementName != nil )
	{
		if (!m_sCurrentString) {
			// currentStringValue is an NSMutableString instance variable
			m_sCurrentString = [[NSMutableString alloc] initWithCapacity:50];
		}
		[m_sCurrentString appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	if ( [elementName isEqualToString:@"Document"] ) {
		[m_item setValue:m_sCurrentCatalog forKey:@"CatalogDirectory"];
		[m_contents addObject:m_item];
		//[m_item removeAllObjects];
		m_item = nil;
		m_sElementName = nil;
		
		return;
	}
	
	if ( [elementName isEqualToString:@"CatalogURL"] )
	{
		m_sCatalogURL = m_sCurrentString;
		m_sCurrentString = nil;
		m_sElementName = nil;
		
		return;
	}
	
	[m_item setValue:m_sCurrentString forKey:elementName];
	m_sCurrentString = nil;
	m_sElementName = nil;
	return;
}

#pragma mark -- OPEN ITEM --
-(void)openCatalogItem:(CatalogItem*)pItem
{
	NSURLComponents *components = nil;
	
	if ( pItem.URL != nil )
		components = [[NSURLComponents alloc] initWithString:pItem.URL];
	
	/*	if ( components == nil )
	 {
	 NSString* sErr = [NSString stringWithFormat:@"ERROR: Wrong URL %@", pItem.URL];
	 [[Log getLog] addLine:sErr];
	 return;
	 }*/
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [[[General catalogDirectory] stringByAppendingPathComponent:[[pItem.URL lastPathComponent] stringByDeletingPathExtension]] stringByAppendingPathExtension:@"catdir"];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sItemURL = pItem.URL;
	BOOL bDropbox = NO;
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[[pItem URL] lastPathComponent]];
	
	if ( components != nil && [components query] != nil )
	{
		sExtension = [[[components path] pathExtension] lowercaseString];
		bDropbox = YES;
		sItemURL = [NSString stringWithFormat:@"%@://%@%@?dl=1", [components scheme], [components host], [components path]];
		sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
	}
	
	if ( [sExtension isEqualToString:@"xml"] )
	{
		//NSURL* url = [NSURL URLWithString:pItem.URL];
		
		//NSLog(@"Current catalog: %@", m_sCurrentCatalog );
		
		if ( m_sCurrentCatalog == nil )
		{
			//top level
			if ( [self openCatalog:sItemURL] )
			{
				//[self addLevel:pItem.URL];
				[[General catalogStack] add:sItemURL];
			}
		}
		else
		{
			//we're already in a catalog
			if ( [[NSFileManager defaultManager] fileExistsAtPath:sDestFileName] )
			{
				//we got it already
				if ( [self openCatalog:sDestFileName] )
				{
					//[self addLevel:sDestFileName];
					[[General catalogStack] add: sDestFileName];
				}
			}
			else
			{
				//need to download the catalog
				NSString* sUrl = [sItemURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				//NSString* sDest = [[sDestFileName stringByDeletingPathExtension] stringByDeletingPathExtension:@"catdir"];
				sDestFileName = [sDestFileName stringByDeletingLastPathComponent];
				NSString* sCatalogFile = sDestFileName;
				sCatalogFile = [sDestFileName stringByAppendingPathComponent:[sUrl lastPathComponent]];
				
				[self downloadNewCatalog:sUrl toDirectory:sDestFileName openCatalog:sCatalogFile];
			}
		}
	}
	else if ( [sExtension isEqualToString:@"pdf"] || [sExtension isEqualToString:@"drmz"])
	{
		if ( [[NSFileManager defaultManager] fileExistsAtPath:sDestFileName] )
		{
			[self openDocumentAndCloseWindow:sDestFileName];
		}
		else
		{
			NSString* sUrl = sItemURL;
			//download the thumbnail file (if exists)
			sDestFileName = [sCatName stringByAppendingPathComponent:[pItem.ThumbURL lastPathComponent]];
			if ( [[NSFileManager defaultManager] fileExistsAtPath:sDestFileName] == NO )
			{
				sUrl = [pItem.ThumbURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				NSURL* url = [NSURL URLWithString:sUrl];
				if ( url != nil )
				{
					if ( [url host] != nil && [url scheme] != nil && [url path] != nil )
					{
						[self downloadFile:url toLocation:sDestFileName autoOpen:NO fromDropbox:bDropbox];
					}
				}
			}
			
			sUrl = [sItemURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			NSURL* url = [NSURL URLWithString:sUrl];
			if ( url == nil )
			{
				sUrl = [sUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				url = [NSURL URLWithString:sUrl];
			}
			if ( components != nil && [components query] != nil )
				sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
			else
				sDestFileName = [sCatName stringByAppendingPathComponent:[sItemURL lastPathComponent]];
			
			[m_progress setHidden:NO];
			[m_progress setIndeterminate:YES];
			[m_progress setUsesThreadedAnimation:YES];
			[m_progress startAnimation:nil];
			
			[self downloadFile:url toLocation:sDestFileName autoOpen:YES fromDropbox:bDropbox];
		}
	}
	else if ( [sExtension isEqualToString:@"zip"] )
	{
		if ( [[NSFileManager defaultManager] fileExistsAtPath:sDestFileName] )
		{
			[self openZippedCatalog:sDestFileName];
		}
		else
		{
			//no - we don't have this zip file and should download it
			NSString* sUrl = sItemURL;
			//download the thumbnail file (if exists)
			if ( pItem.ThumbURL.length > 0 )
			{
				sDestFileName = [sCatName stringByAppendingPathComponent:[pItem.ThumbURL lastPathComponent]];
				if ( [[NSFileManager defaultManager] fileExistsAtPath:sDestFileName] == NO )
				{
					sUrl = [pItem.ThumbURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSURL* url = [NSURL URLWithString:sUrl];
					if ( url != nil )
					{
						if ( [url host] != nil && [url scheme] != nil && [url path] != nil )
						{
							[self downloadFile:url toLocation:sDestFileName autoOpen:YES fromDropbox:bDropbox];
						}
					}
				}
			}
			
			sUrl = [sItemURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			NSURL* url = [NSURL URLWithString:sUrl];
			if ( url == nil )
			{
				sUrl = [sUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				url = [NSURL URLWithString:sUrl];
			}
			sDestFileName = [sCatName stringByAppendingPathComponent:[sItemURL lastPathComponent]];
			
			[m_progress setHidden:NO];
			[m_progress setIndeterminate:YES];
			[m_progress setUsesThreadedAnimation:YES];
			[m_progress startAnimation:nil];
			
			if ( bDropbox )
			{
				[self downloadFile:url toLocation:sDestFileName autoOpen:YES fromDropbox:bDropbox];
			}
			else
			{
				NSString* sDestCatDir = [[sDestFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
				[self downloadNewCatalog:[url absoluteString] toDirectory:[sDestFileName stringByDeletingLastPathComponent] openCatalog:sDestCatDir];
			}
		}
	}
	else
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Alert"];
		[alert setInformativeText:@"This type of file is not supported. Yet!"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		
	}
}

-(BOOL)openZippedCatalog:(NSString*)sZipFile
{
	//we already have this zip file
	//check if we have the XML file
	NSString* sXmlFile = [[sZipFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:sXmlFile] )
	{
		//the catalog xml file is there - open it
		[self openCatalog:sXmlFile];
		[[General catalogStack] add:sXmlFile];
		return YES;
	}
	else
	{
		//no - we don't have xml catalog file - unzip it
		NSString* sDestDir = [sZipFile stringByDeletingLastPathComponent];
		if ( [self unzip:sZipFile toDestinationDir:sDestDir] )
		{
			//file unzipped OK - open the catalog
			[self openCatalog:sXmlFile];
			
			//[self performSelector:@selector(openCatalog:) withObject:sXmlFile afterDelay:1];
			[[General catalogStack] add:sXmlFile];
			return YES;
		}
	}
	
	return NO;
}

#pragma mark -- CONTEXT MENU --

#pragma mark -- CATALOG DELEGATE ----
-(void)itemClicked:(CatalogItem*)pItem
{
	if ( m_bDownloading )
		return;
	
	[m_txtURL setStringValue:@""];
	[m_lblError setHidden:YES];
	[self openCatalogItem:pItem];
}

-(void)itemRightClicked:(CatalogItem*)pItem withEvent:(NSEvent*)event
{
	NSURLComponents *components = nil;
	
	if ( pItem.URL != nil )
		components = [[NSURLComponents alloc] initWithString:pItem.URL];
	
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [[[General catalogDirectory] stringByAppendingPathComponent:[[pItem.URL lastPathComponent] stringByDeletingPathExtension]] stringByAppendingPathExtension:@"catdir"];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sItemURL = pItem.URL;
	BOOL bDropbox = NO;
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[[pItem URL] lastPathComponent]];
	
	if ( components != nil && [components query] != nil )
	{
		sExtension = [[[components path] pathExtension] lowercaseString];
		bDropbox = YES;
		sItemURL = [NSString stringWithFormat:@"%@://%@%@?dl=1", [components scheme], [components host], [components path]];
		sDestFileName = [sCatName stringByAppendingPathComponent:[[components path] lastPathComponent]];
	}

	m_selectedItem = pItem;
	if ( [sExtension isEqualToString:@"xml"] )
	{
		//catalogs
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
		[theMenu insertItemWithTitle:@"Delete Catalog" action:@selector(deleteCatalog:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItemWithTitle:@"Catalog Info" action:@selector(catalogInfo:) keyEquivalent:@"" atIndex:1];
		[theMenu insertItemWithTitle:@"Refresh Catalog" action:@selector(refreshCatalog:) keyEquivalent:@"" atIndex:2];
		[theMenu insertItemWithTitle:@"Open Catalog Folder" action:@selector(openFolder:) keyEquivalent:@"" atIndex:3];
		[theMenu insertItemWithTitle:@"Open Catalog As Text" action:@selector(openCatalogAsText:) keyEquivalent:@"" atIndex:4];
		
		[NSMenu popUpContextMenu:theMenu withEvent:event forView:m_collectionView];
	}
	else if ( [sExtension isEqualToString:@"pdf"] || [sExtension isEqualToString:@"drmz"])
	{
		//documents
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
		[theMenu insertItemWithTitle:@"Delete Document" action:@selector(deleteDocument:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItemWithTitle:@"Document Info" action:@selector(documentInfo:) keyEquivalent:@"" atIndex:1];
		[theMenu insertItemWithTitle:@"Refresh Document" action:@selector(refreshDocument:) keyEquivalent:@"" atIndex:2];
		[theMenu insertItemWithTitle:@"Open Document Folder" action:@selector(openFolder:) keyEquivalent:@"" atIndex:3];
		if ( pItem.ThumbURL != nil && pItem.ThumbURL.length > 0 )
			[theMenu insertItemWithTitle:@"Refresh Document Image" action:@selector(refreshDocumentImage:) keyEquivalent:@"" atIndex:4];
		[NSMenu popUpContextMenu:theMenu withEvent:event forView:m_collectionView];
	}
	else if ( [sExtension isEqualToString:@"zip"] )
	{
		//zipped catalogs
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
		[theMenu insertItemWithTitle:@"Delete Catalog" action:@selector(deleteCatalog:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItemWithTitle:@"Catalog Info" action:@selector(catalogInfo:) keyEquivalent:@"" atIndex:1];
		[theMenu insertItemWithTitle:@"Refresh Catalog" action:@selector(refreshCatalog:) keyEquivalent:@"" atIndex:2];
		[theMenu insertItemWithTitle:@"Open Catalog Folder" action:@selector(openFolder:) keyEquivalent:@"" atIndex:3];
		[theMenu insertItemWithTitle:@"Open Catalog As Text" action:@selector(openCatalogAsText:) keyEquivalent:@"" atIndex:4];
		
		[NSMenu popUpContextMenu:theMenu withEvent:event forView:m_collectionView];

	}
}

#pragma mark -- CONTEXT MENU ACTIONS --
-(void)openFolder:(id)sender
{
	[self openItemFolder:m_selectedItem];
}

-(void)openCatalogAsText:(id)sender
{
	NSString* sXml = nil;
	
	if ( m_sCurrentCatalog == nil )
		sXml = [General catalogDirectory];
	else
		sXml = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	sXml = [sXml stringByAppendingPathComponent:[[m_selectedItem URL] lastPathComponent]];
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:sXml] == NO )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"File doesn't exist"];
		[alert setInformativeText:sXml];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:[self window] completionHandler:nil];
	}
	else
		[[NSWorkspace sharedWorkspace] openFile:sXml];
}

-(void)deleteCatalog:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Delete catalog?"];
	[alert setInformativeText:(m_selectedItem.Name.length>0?m_selectedItem.Name:m_selectedItem.URL)];
	[alert setAlertStyle:NSCriticalAlertStyle];

	[alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
	 {
		 if (result == NSAlertFirstButtonReturn) 
		 {
			 //OK - delete catalog
			 [self deleteItem:m_selectedItem];
		 }
		 else if ( result == NSAlertSecondButtonReturn )
		 {
			 //Cancel - don't delete
		 }
	 }];
}

-(void)refreshCatalog:(id)sender
{
	[self refreshItem:m_selectedItem];
}

-(void)catalogInfo:(id)sender
{
	[self displayItem:m_selectedItem];
}

-(void)deleteDocument:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Delete document?"];
	[alert setInformativeText:(m_selectedItem.Name.length>0?m_selectedItem.Name:m_selectedItem.URL)];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
	 {
		 if (result == NSAlertFirstButtonReturn) 
		 {
			 //OK - delete catalog
			 [self deleteItem:m_selectedItem];
		 }
		 else if ( result == NSAlertSecondButtonReturn )
		 {
			 //Cancel - don't delete
		 }
	 }];
}

-(void)refreshDocument:(id)sender
{
	[self refreshItem:m_selectedItem];
}

-(void)documentInfo:(id)sender
{
	[self displayItem:m_selectedItem];
}

-(void)refreshDocumentImage:(id)sender
{
	NSString* sCatName = nil;
	if ( m_sCurrentCatalog == nil )
		sCatName = [[[General catalogDirectory] stringByAppendingPathComponent:[[m_selectedItem.URL lastPathComponent] stringByDeletingPathExtension]] stringByAppendingPathExtension:@"catdir"];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];

	NSString* sUrl = m_selectedItem.ThumbURL;
	//download the thumbnail file (if exists)
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[m_selectedItem.ThumbURL lastPathComponent]];
	sUrl = [m_selectedItem.ThumbURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSURL* url = [NSURL URLWithString:sUrl];
	if ( url != nil )
	{
		if ( [url host] != nil && [url scheme] != nil && [url path] != nil )
		{
			[self downloadFile:url toLocation:sDestFileName autoOpen:NO fromDropbox:NO];
		}
	}
}
@end
