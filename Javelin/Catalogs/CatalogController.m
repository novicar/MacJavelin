//
//  CatalogController.m
//  Javelin3
//
//  Created by Novica Radonic on 04/05/2018.
//

#import "CatalogController.h"
#import "General.h"

@interface CatalogController ()

@end

@implementation CatalogController

-(void) windowWillClose:(NSNotification*)notification
{
	[NSApp endSheet:[self window] returnCode:0];
	[[self window] orderOut: self];
}

-(BOOL)windowShouldClose:(NSWindow*)sender
{
	if ( m_bDownloading )
		return NO;
	
	return YES;
}

//@synthesize prot;
@synthesize catalogURL=m_sCatalogURL;

- (int) addLevel:(NSString*)sFile
{
	[m_stackOfCatalogs addObject:sFile];
	return (int)[m_stackOfCatalogs count];
}

- (NSString*) removeLevel
{
	int nCount = (int)[m_stackOfCatalogs count];
	
	if ( nCount > 0 )
	{
		NSString* sFile = [m_stackOfCatalogs objectAtIndex:(nCount-1)];
		[m_stackOfCatalogs removeLastObject];
		nCount = (int)[m_stackOfCatalogs count];
		
		if ( nCount > 0 )
			sFile = [m_stackOfCatalogs objectAtIndex:(nCount-1)];
		else
			sFile = nil;
		return sFile;
	}
	else
	{
		return nil;
	}
}

- (NSString*) getTopLevel
{
	int nCount = (int)[m_stackOfCatalogs count];
	
	if ( nCount > 0 )
	{
		NSString* sFile = [m_stackOfCatalogs objectAtIndex:(nCount-1)];
		return sFile;
	}
	else
	{
		return nil;
	}
}


-(void)openCatalogItem:(CatalogItem*)pItem
{
	NSString* sExtension = [[pItem.URL pathExtension] lowercaseString];
	NSString* sCatName = nil;
	
	if ( m_sCurrentCatalog == nil )
		sCatName = [[[General catalogDirectory] stringByAppendingPathComponent:[[pItem.URL lastPathComponent] stringByDeletingPathExtension]] stringByAppendingPathExtension:@"catdir"];
	else
		sCatName = [[m_sCurrentCatalog stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
	
	
	NSString* sDestFileName = [sCatName stringByAppendingPathComponent:[pItem.URL lastPathComponent]]; 
	
	
	if ( [sExtension isEqualToString:@"xml"] )
	{
		//NSURL* url = [NSURL URLWithString:pItem.URL];
		
		NSLog(@"Current catalog: %@", m_sCurrentCatalog );
		
		if ( m_sCurrentCatalog == nil )
		{
			//top level
			if ( [self openCatalog:pItem.URL] )
			{
				//[self addLevel:pItem.URL];
				[[General catalogStack] add: pItem.URL];
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
					[[General catalogStack] add: pItem.URL];
				}
			}
			else
			{
				//need to download the catalog
				NSString* sUrl = [pItem.URL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
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
			NSString* sUrl = pItem.URL;
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
						[self downloadFile:url toLocation:sDestFileName autoOpen:NO];
					}
				}
			}
			
			sUrl = [pItem.URL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
			NSURL* url = [NSURL URLWithString:sUrl];
			if ( url == nil )
			{
				sUrl = [sUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				url = [NSURL URLWithString:sUrl];
			}
			sDestFileName = [sCatName stringByAppendingPathComponent:[pItem.URL lastPathComponent]];
			
			[m_progress setHidden:NO];
			[m_progress setIndeterminate:YES];
			[m_progress setUsesThreadedAnimation:YES];
			[m_progress startAnimation:nil];
			
			[self downloadFile:url toLocation:sDestFileName autoOpen:YES];
		}
	}
	else if ( [sExtension isEqualToString:@"zip"] )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Alert"];
		[alert setInformativeText:@"Zip files are not supported. Yet!"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
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


- (BOOL) openCatalog:(NSString*)sCatalog
{
	return [self loadXMLCatalog:sCatalog];
}

-(void)openDocumentAndCloseWindow:(NSString*)sDocument
{
	NSURL* url = [NSURL fileURLWithPath:sDocument isDirectory:NO];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES completionHandler:
		 ^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) 
		 {
			 if ( error == nil )
			 {
				 NSLog(@"CLOSE");
				 [NSApp endSheet:[self window] returnCode:0];
				 [[self window] orderOut: self];
			 }
		 }
	 ];
}

-(void)itemClicked:(CatalogItem *)pItem
{
	if ( m_bDownloading )
		return;
	
	[m_lblError setHidden:YES];
	[self openCatalogItem:pItem];
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
		m_catalogItem = [[CatalogItem alloc] init];
		[m_collectionView setItemPrototype:m_catalogItem];
		
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
			[m_collectionView setContent:m_contents];
			
			int nCount = (int)[m_collectionView numberOfItemsInSection:0];
			for( int i=0; i<nCount; i++)
			{
				CatalogItem* item = (CatalogItem*)[m_collectionView itemAtIndex:i];
				[item setProt:self];
			}
		}
	}
}
-(BOOL)loadXMLCatalog:(NSString*)sCatalogPath
{
	m_contents = nil;
	m_sInitialPath = sCatalogPath;
	m_sCurrentCatalog = nil;

	if ( sCatalogPath == nil )
	{
		//show main catalog directory
		[self loadDirectory:[General catalogDirectory]];
		[m_btnBack setEnabled:NO];
		[m_btnDownload setEnabled:YES];
		
		return YES;
	}
	else
	{
		//open catalog XML file
		[m_btnBack setEnabled:YES];
		[m_btnDownload setEnabled:NO];
		m_sCurrentCatalog = sCatalogPath;
		BOOL bRes = [self parseXMLFile:sCatalogPath];
		if ( bRes )
		{
			m_catalogItem = [[CatalogItem alloc] init];
			[m_catalogItem setCatalogDirectory:sCatalogPath];
			[m_catalogItem setProt:self];
			[m_collectionView setItemPrototype:m_catalogItem];
			[m_collectionView setContent:m_contents];
			
			//check this catalog's directory
			[self checkCatalogDirectory:sCatalogPath];

			int nCount = (int)[m_collectionView numberOfItemsInSection:0];
			for( int i=0; i<nCount; i++)
			{
				CatalogItem* item = (CatalogItem*)[m_collectionView itemAtIndex:i];
				[item setProt:self];
				//[item setCatalogDirectory:sCatalogPath];
			}
		}
		else
		{
			m_sCurrentCatalog = nil;
		}
		return bRes;
	}
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

-(void)loadDataOLD:(NSString*)sCatalogPath
{
	m_catalogItem = [CatalogItem new];
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
					 @"URL":@"Item 1 URL",
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
	[m_collectionView setContent:m_contents];

}

- (void)windowDidLoad {
    [super windowDidLoad];
/*    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[NSBundle loadNibNamed: @"CatalogController" owner: self];
	
	NSNib *itemOneNib = [[NSNib alloc] initWithNibNamed:@"CatalogItem" bundle:nil];
	[m_collectionView registerNib:itemOneNib forItemWithIdentifier:@"CatalogItem"];
	//[m_collectionView setDelegate:self];
	//[m_collectionView setDataSource:self];
	
	m_contents = nil;
	m_stackOfCatalogs = [[NSMutableArray alloc] init];
	m_sInitialPath = nil;
	[self loadXMLCatalog:nil];
	[m_progress setHidden:YES]; 
	[m_lblError setHidden:YES];
	[m_window setContentMinSize:NSMakeSize(850, 750)];

*/
}

- (void) showPanel:(NSString*)sCatalogPath
{
	[NSBundle loadNibNamed: @"CatalogController" owner: self];
	
	NSNib *itemOneNib = [[NSNib alloc] initWithNibNamed:@"CatalogItem" bundle:nil];
	[m_collectionView registerNib:itemOneNib forItemWithIdentifier:@"CatalogItem"];
	//[m_collectionView setDelegate:self];
	//[m_collectionView setDataSource:self];
	
	m_contents = nil;
	m_stackOfCatalogs = [[NSMutableArray alloc] init];
	m_sInitialPath = sCatalogPath;
	[self loadXMLCatalog:sCatalogPath];
	[m_progress setHidden:YES]; 
	[m_lblError setHidden:YES];
	[m_window setContentMinSize:NSMakeSize(850, 750)];
	[NSApp runModalForWindow: m_window];
}

-(IBAction) close:(id)sender
{
	//if ( prot )
	//	[prot catalogWindowClosed];
	if ( m_bDownloading && m_downloadTask != nil )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Cancel download and exit"];
		[alert addButtonWithTitle:@"Continue"];
		[alert setMessageText:@"Download In Progress"];
		[alert setInformativeText:@"Download in progress. Do you want to cancel download?"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd1:returnCode:contextInfo:) contextInfo:nil];

	}
	else
	{
		[NSApp endSheet:[sender window] returnCode:[sender tag]];
		[[sender window] orderOut: self];
	}
}

- (void)alertDidEnd1:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn)
	{
		NSLog(@"(returnCode == first button)");
		[m_downloadTask cancel];
		[NSApp endSheet:[self window] returnCode:0];
		[[self window] orderOut: self];
	}
	else if (returnCode == NSAlertSecondButtonReturn)
	{
		NSLog(@"(returnCode == NSSecondButton)");
	}
	else if (returnCode == NSAlertThirdButtonReturn)
	{
		NSLog(@"else if (returnCode == NSAlertThirdButtonReturn)");
	}
	else
	{
		NSLog(@"All Other return code %d",returnCode);
	}
}

-(IBAction) back:(id)sender
{
	[m_lblError setHidden:YES];
	NSString* sFile = [self removeLevel];
	[self loadXMLCatalog:sFile];
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
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
	else
	{
		NSString* sPath = [url path];
		if ( [[[sPath pathExtension] lowercaseString] isEqualToString:@"xml" ] )
		{
			//OK - you can download that
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
								 if ( [self openCatalog:sCatalogPath] )
								 {
									 //create CATDIR folder for new catalog
									 [fileManager createDirectoryAtPath:sDestinationFile withIntermediateDirectories:YES attributes:nil error:nil];
									 if ( sCatalogPath != nil )
										 [self addLevel:sCatalogPath];
								 }

							 });
						 }
						 else
						 {
							 dispatch_async(dispatch_get_main_queue(), ^(void){
								 [m_lblError setHidden:NO];
								 [m_lblError setStringValue:[err localizedDescription]];
								 
								 NSLog(@"1 %@", [err description]);
								 NSLog(@"2 %d", (int)[err code]);
								 NSLog(@"3 %@", [err userInfo]);
								 NSLog(@"4 %@", [err localizedFailureReason]);
								 NSLog(@"1 %@", [err localizedRecoverySuggestion]);
							 });
							 
						 }
					 }
					 
				 }
				 else
				 {
					 dispatch_async(dispatch_get_main_queue(), ^(void){
						 [m_lblError setHidden:NO];
						 [m_lblError setStringValue:[error localizedDescription]];
						 
						 NSLog(@"1 %@", [error description]);
						 NSLog(@"2 %d", (int)[error code]);
						 NSLog(@"3 %@", [error userInfo]);
						 NSLog(@"4 %@", [error localizedFailureReason]);
						 NSLog(@"1 %@", [error localizedRecoverySuggestion]);
					 });
				 }
			 }
			 ];
			
			[downloadTask resume];
			////////////
		}
		else
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Error"];
			[alert setInformativeText:[NSString stringWithFormat:@"ERROR: Only catalogs can be downloaded. %@", sURL]];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
	}

}

-(IBAction) download:(id)sender
{
	NSString* sURL = [[m_txtDownload string] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		NSLog(@"(returnCode == NSOKButton)");
	}
	else if (returnCode == NSCancelButton)
	{
		NSLog(@"(returnCode == NSCancelButton)");
	}
	else if(returnCode == NSAlertFirstButtonReturn)
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
		NSLog(@"All Other return code %d",returnCode);
	}
}

-(IBAction) refresh:(id)sender
{
	NSString* sCatalog = [self getTopLevel];
	if ( sCatalog == nil )
	{
		[self loadXMLCatalog:nil];//reload home directory from file system
	}
	else
	{
		NSString* sCat = [m_sCatalogURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		NSURL* url = [NSURL URLWithString:sCat];

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
					 BOOL bRes = [fileManager moveItemAtURL:location toURL:urlDest error:&err];
					 
					 if ( bRes )
					 {
						 //[self openDocumentAndCloseWindow:sDestFIle];
						 dispatch_async(dispatch_get_main_queue(), ^(void){
							 [self loadXMLCatalog:m_sCurrentCatalog];
						});
					 }
					 else
					 {
						 dispatch_async(dispatch_get_main_queue(), ^(void){
							 [m_lblError setHidden:NO];
							 [m_lblError setStringValue:[err localizedDescription]];
							 
							 NSLog(@"1 %@", [err description]);
							 NSLog(@"2 %d", (int)[err code]);
							 NSLog(@"3 %@", [err userInfo]);
							 NSLog(@"4 %@", [err localizedFailureReason]);
							 NSLog(@"1 %@", [err localizedRecoverySuggestion]);
						 });
						 
					 }
				 }
				 
			 }
			 else
			 {
				 dispatch_async(dispatch_get_main_queue(), ^(void){
					 [m_lblError setHidden:NO];
					 [m_lblError setStringValue:[error localizedDescription]];
					 
					 NSLog(@"1 %@", [error description]);
					 NSLog(@"2 %d", (int)[error code]);
					 NSLog(@"3 %@", [error userInfo]);
					 NSLog(@"4 %@", [error localizedFailureReason]);
					 NSLog(@"1 %@", [error localizedRecoverySuggestion]);
				 });
			 }
		 }
		 ];
		
		[downloadTask resume];
		////////////
	}
		
	
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
	int i = 100;
	i++;
}

- (void)collectionView:(NSCollectionView *)collectionView willDisplayItem:(NSCollectionViewItem *)item 
							forRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	int i = 100;
	i++;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return 2;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	NSCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"Slide" forIndexPath:indexPath];
	//AAPLImageFile *imageFile = [self imageFileAtIndexPath:indexPath];
	//item.description = @"koko";
	item.title = @"title";
	NSString* s = @"mkonji";
	item.representedObject = s;
	
	return item;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	m_sElementName = elementName;
	
	if ( [elementName isEqualToString:@"JavelinCatalog"]) 
	{
		if (!m_contents)
			m_contents = [[NSMutableArray alloc] init];
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
	
/*	if ( [elementName isEqualToString:@"Name"] ) 
	{
		[m_catalogItem setName:m_sCurrentString];
		m_sCurrentString = nil;
		return;
	}
	
	if ( [elementName isEqualToString:@"URL"] ) 
	{
		[m_catalogItem setURL:m_sCurrentString];
		m_sCurrentString = nil;
		return;
	}*/
	

	/*	NSString*				m_sSubtitle;
	 NSString*				m_sISBN;
	 NSString*				m_sPublisherName;
	 NSString*				m_sPublisherURL;
	 NSString*				m_sAuthors;
	 NSString*				m_sAuthorURL;
	 NSString*				m_sLanguage;
	 NSString*				m_sEdition;
	 NSString*				m_sDescription;
	 NSString*				m_sReview;
	 NSString*				m_sPrintLength;
	 NSString*				m_sPublicationDate;
	 NSString*				m_sPrice;
	 NSString*				m_sCurrencyCode;
*/
/*	NSString *prop = [self currentProperty];
	
	// ... here ABMultiValue objects are dealt with ...
	
	if (( [prop isEqualToString:kABLastNameProperty] ) ||
		( [prop isEqualToString:kABFirstNameProperty] )) {
		[currentPerson setValue:(id)currentStringValue forProperty:prop];
	}
	// currentStringValue is an instance variable
	[currentStringValue release];
	currentStringValue = nil;*/
}

-(void)downloadFile:(NSURL*)urlFile toLocation:(NSString*)sDestFIle autoOpen:(BOOL)bOpenFile
{
	//NSURLRequest* theRequest = [NSURLRequest requestWithURL:urlFile];
	
	m_bDownloadIsIndeterminate = YES;
	m_fDownloadProgress = 0.0f;
	m_bDownloading = YES;
	if ( bOpenFile )
	{
		[m_progress setHidden:NO];
		[m_progress setIndeterminate:YES];
		[m_progress setUsesThreadedAnimation:YES];
		[m_progress startAnimation:nil];
	}
	NSLog(@"--> %@", urlFile);
	NSLog(@"%@", sDestFIle);
	NSLog(@"%d", bOpenFile);
/*	NSURLRequest *theRequest = [NSURLRequest requestWithURL:urlFile
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:6000.0];*/
	
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
				});
			}

			if (error == nil) 
			{
				NSLog(@"FINISHED: %@", location);
				BOOL bOK = YES;
				if ( response != nil && [[response MIMEType] isEqualToString:@"text/html"] == YES )
					bOK = NO;
				
				NSError *err = nil;
				NSFileManager *fileManager = [NSFileManager defaultManager];
				
				if ( bOK && [fileManager isReadableFileAtPath:[location path]] )
				{
					NSURL* urlDest = [NSURL fileURLWithPath:sDestFIle isDirectory:NO];
					[fileManager removeItemAtURL:urlDest error:nil];
					BOOL bRes = [fileManager moveItemAtURL:location toURL:urlDest error:&err];
					//BOOL bRes = [fileManager copyItemAtURL:location toURL:urlDest error:&err];
				
					if ( bRes )
					{
						if ( bOpenFile )
						{
							[self openDocumentAndCloseWindow:sDestFIle];
							m_bDownloading = NO;
						}
					}
					else if ( err != nil )
					{
						m_bDownloading = NO;
						//error while moving the downloaded file
						dispatch_async(dispatch_get_main_queue(), ^(void){
							[m_lblError setHidden:NO];
							[m_lblError setStringValue:[err localizedDescription]];
							
							NSLog(@"1 %@", [err description]);
							NSLog(@"2 %d", (int)[err code]);
							NSLog(@"3 %@", [err userInfo]);
							NSLog(@"4 %@", [err localizedFailureReason]);
							NSLog(@"1 %@", [err localizedRecoverySuggestion]);

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
					
					NSLog(@"1 %@", [error description]);
					NSLog(@"2 %d", (int)[error code]);
					NSLog(@"3 %@", [error userInfo]);
					NSLog(@"4 %@", [error localizedFailureReason]);
					NSLog(@"1 %@", [error localizedRecoverySuggestion]);
				});
			}
		}
	 ];
	
	[m_downloadTask resume];
/*	dispatch_async(dispatch_get_main_queue(), ^{
		//[self.progressView setHidden:YES];
		//[self.imageView setImage:[UIImage imageWithData:data]];
		m_download = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
	});
	*/
	//[m_download setDestination:sDir allowOverwrite:NO];
}

#pragma mark -- DOWNLOAD DELEGATE ----
- (void)downloadDidBegin:(NSURLDownload *)download
{
	NSLog(@"Download begin");
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"Download didreceive");
	m_expectedContentLength = [response expectedContentLength];
	if (m_expectedContentLength > 0.0) 
	{
		m_bDownloadIsIndeterminate = NO;
		m_downloadedSoFar = 0;
		m_startTime = [[NSDate alloc] init];
		[m_progress setMaxValue:100];
		[m_progress setMinValue:0];
	}
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	NSLog(@"Download didreceivedata length");
	m_downloadedSoFar += length;
	if (m_downloadedSoFar >= m_expectedContentLength) 
	{
		// the expected content length was wrong as we downloaded more than expected
		// make the progress indeterminate
		m_bDownloadIsIndeterminate = YES;
	} 
	else 
	{
		m_fDownloadProgress = 100.0f * (float)m_downloadedSoFar / (float)m_expectedContentLength;
		
		NSString *soFarString = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:m_downloadedSoFar]];
		NSString *expected = [m_numberFormat stringFromNumber: [NSNumber numberWithLongLong:m_expectedContentLength]];
		//[bytes setStringValue:[NSString stringWithFormat:@"%@/%@", soFarString, expected]];
		//[percentage setStringValue:[NSString stringWithFormat:@"%d%%", (int)downloadProgress]];
		NSDate* now = [NSDate date];
		NSTimeInterval elapsed = [now timeIntervalSinceDate:m_startTime];
		
		if ( elapsed > 0 )
		{
			long seconds;// = lroundf(elapsed); // Modulo (%) operator below needs int or long
			
			float fBytesPerSecond = (float)(m_downloadedSoFar / elapsed);//bytes per second
			float f1 = (float)((m_expectedContentLength-m_downloadedSoFar) / fBytesPerSecond);
			
			if ( fabs(f1-m_old) > 1 )
			{
				seconds = lroundf(f1);
				//		int hour = seconds / 3600;
				int mins = (int)(seconds / 60);
				int secs = seconds % 60;
				//NSLog(@"bps:%f f1:%f s:%lu", fBytesPerSecond, f1, seconds);
				//if ( mins > 99 )
				//	[time setStringValue:@"100+ min"];
				//else
				//	[time setStringValue:[NSString stringWithFormat:@"%02dmin %02ds", mins, secs]];
				
				m_old = f1;
			}
		}
	}
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
	NSLog(@"Download decide");
	//NSURL *urlHome = [NSURL fileURLWithPath:NSHomeDirectory()];
	NSString* s = [General catalogDirectory];//[urlHome absoluteString];
	NSString* path = [s stringByAppendingPathComponent:filename];
	NSString* urlTextEscaped = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL* url = [NSURL URLWithString:urlTextEscaped];
	path = [url path];

	m_urlLocalFile = [[NSURL alloc] initFileURLWithPath:path isDirectory:NO];
	[download setDestination:path allowOverwrite:NO];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	NSLog(@"Download did finish");
	int i = 100;
	i++;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	NSRunAlertPanel(@"Download Error", [General convertDomainError:[error code]], @"OK", nil, nil);
}
@end
