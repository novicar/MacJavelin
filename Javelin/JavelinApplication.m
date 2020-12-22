//
//  JavelinApplication.m
//  Javelin
//
//  Created by MacMini on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JavelinApplication.h"
#import "Version.h"
#import "Log.h"
#import "DownloadController.h"
#import "DownloadDocument.h"
#import "DocumentDB.h"
#import "JavelinDocument.h"
#import "EnterDocID.h"
#import "XmlParser.h"
#import "General.h"
#import "VarSystemInfo.h"
#import "CatalogDocument.h"
#import "CatalogController.h"
#import "CatalogViewNew.h"
#import "DocumentList.h"



//#import "JavelinDocumentController.h"

@implementation JavelinApplication

@synthesize currentDocumentID=m_currentDocumentID;

-(void) finishLaunching
{
//	If you want to assign JavelinDocumentController - uncomment these lines
//	JavelinDocumentController *cntrl = [[JavelinDocumentController alloc] init];
//	[self setDelegate:cntrl];

	[super finishLaunching];
	
	//hide catalogs menu item for macOS versions < v10.12.4
	NSOperatingSystemVersion ver = [[NSProcessInfo processInfo] operatingSystemVersion];
	//ver.majorVersion = 10;
	//ver.minorVersion = 12;
	//ver.patchVersion = 19;
	
	if ( ver.majorVersion <= 10 )
	{
		if ( ver.majorVersion < 10 || ver.minorVersion <= 12 )
		{
			if ( ver.majorVersion < 10 || ver.minorVersion < 12 || ver.patchVersion < 4 )
			{
				NSMenu* pMenu = [[NSApplication sharedApplication] mainMenu];
				NSMenuItem* pFile = [pMenu itemAtIndex:1];
				NSMenu* sSub = [pFile submenu];
				NSMenuItem* pCatalogs = [sSub itemWithTag:999];
				[pCatalogs setHidden:YES];
			}
		}
	}
	[self loadDocumentList];
	[self setDelegate:self];
	[self checkCatalogDir];
}

-(void)checkCatalogDir
{
	NSString* sCatalogPath = [General catalogDirectory];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL bRes = [fm createDirectoryAtPath:sCatalogPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	if ( bRes )
	{
		NSString* catalogFromResources = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/catalog.xml"];
		NSString* sDest = [sCatalogPath stringByAppendingPathComponent:@"catalog.xml"];
		
		if ( [fm fileExistsAtPath:sDest] == NO )
			bRes = [fm copyItemAtPath:catalogFromResources toPath:sDest error:nil];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	VarSystemInfo* v = [[VarSystemInfo alloc] init];
	NSString* sTemp = [NSString stringWithFormat:@"STARTING - JM_%@ [%@] %@ SN:%@", [Version version], [v sysOSVersion], [v sysModelID], [v sysSerialNumber]];
	[[Log getLog] addLine:sTemp];
	

	m_bFullScreen = NO;
	[[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
	m_nPresentationModeNormal = [[NSApplication sharedApplication] currentSystemPresentationOptions];
	
	//take care of SANDBOX directory!!
	NSURL* uurl = [General applicationDataDirectory];
	
	//make sure the sandbox directory exists
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	if (![fileManager fileExistsAtPath:[uurl path]])
		[fileManager createDirectoryAtURL:uurl withIntermediateDirectories:NO attributes:nil error:nil];
	
	//NSURL *appFolder = [[[NSBundle mainBundle] bundleURL] URLByDeletingLastPathComponent];
	
	m_thread = [[ScannerThread alloc] init];
	ThreadArgs* args = [[ThreadArgs alloc] init];
	[args setIntValue:10];
	[m_thread startThread:args];
}

-(void)loadDocumentList
{
	DocumentList* dl = [General documentList];
	[dl loadMe];
}

-(void)saveDocumentList
{
	DocumentList* dl = [General documentList];
	[dl saveMe];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	//NSLog(@"DidBecomeActive");
}

- (IBAction)openAboutPanel:(id)sender
{
	
/*	NSArray* apps = [[NSWorkspace sharedWorkspace] runningApplications];
	for (int i = 0; i<[apps count]; i++) 
	{
		NSRunningApplication app = (NSRunningApplication) [apps objectAtIndex:i];
		NSString *uniqueName = app.bundleIdentifier;
		BOOL hasWindow = (app.activationPolicy == NSApplicationActivationPolicyRegular)?YES:NO;
	}*/
	/*
	for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		NSString *uniqueName = app.bundleIdentifier;
		BOOL hasWindow = (app.activationPolicy == NSApplicationActivationPolicyRegular)?YES:NO;
		
		NSLog(@"APP:%@ hasWindow:%d", uniqueName, hasWindow );
	}
	*/
/*	NSString* sss = [self runCommand:@"ls -la"];
	NSLog(@"%@", sss);
	*/
    NSDictionary *options;
    //NSImage *img;
	
    //img = [NSImage imageNamed: @"Picture 1"];
    options = [NSDictionary dictionaryWithObjectsAndKeys:
			   [Version date], @"Version",
			   [Version appName], @"ApplicationName",
			   //img, @"ApplicationIcon",
			   [NSString stringWithFormat:@"Copyright 2020, %@",[Version company]], @"Copyright",
			   [NSString stringWithFormat:@"%@ v%@",[Version appName],[Version version]], @"ApplicationVersion",
			   nil];
	
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}

- (NSString *)runCommand:(NSString *)commandToRun
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/sh"];
	
	NSArray *arguments = [NSArray arrayWithObjects:
						  @"-c" ,
						  [NSString stringWithFormat:@"%@", commandToRun],
						  nil];
	NSLog(@"run command:%@", commandToRun);
	[task setArguments:arguments];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data = [file readDataToEndOfFile];
	
	NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return output;
}

-(IBAction) writeLogFile: (id) sender
{
	NSSavePanel *sp;
	//int runResult;
	
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	
	/* set up new attributes */		[sp setAccessoryView:nil];
	//[sp setRequiredFileType:@"txt"];
	NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"txt", @"TXT", nil];
	[sp setAllowedFileTypes:fileTypes];
	
	/* display the NSSavePanel */
	//runResult = (int)[sp runModal];
	
	/* if successful, save file under designated name */
/*	if (runResult == NSOKButton)
	{
		//[[Log getLog] writeToLogFile:[sp filename]];
		NSString* s = [[sp URL] path];
		[[Log getLog] writeToLogFile:[[sp URL] path]];
//		if (![textData writeToFile:[sp filename] atomically:YES])
//			NSBeep();
	}
	
//	[sp release];
*/
	[sp beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            //NSURL*  theFile = [sp URL];
			//NSString* s = [[sp URL] path];
			[[Log getLog] writeToLogFile:[[sp URL] path]];
            // Write the contents in the new format.
        }
    }];
}

-(IBAction) showDrumlinHelp: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.drumlinsecurity.com/help.html"]];
}

- (IBAction)gotoDrumlinWeb:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.drumlinsecurity.com/"]];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[Log getLog] addLine:@"DownloadController: didEndSheet called"];
    [sheet orderOut:self];
	//[NSApp endSheet:m_download];
}

-(IBAction)downloadFile:(id)sender
{
	if ( m_downloads == nil )
	{
		NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString * documentsDirectory = [paths objectAtIndex:0];
		NSString * fullPath = [documentsDirectory stringByAppendingPathComponent:DWN_FILENAME];
		NSURL* url = [NSURL fileURLWithPath:fullPath isDirectory:NO];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		
		if ( [fm fileExistsAtPath:fullPath] )
		{
			m_downloads = [[DownloadDocument alloc] initWithContentsOfURL:url ofType:DwnDocumentUTI error:nil];
		}
		else
		{
			m_downloads = [[DownloadDocument alloc] initWithType:DwnDocumentUTI error:nil];
			[m_downloads setFileURL:url];
			[m_downloads setFileType:DwnDocumentUTI];
		}
		[m_downloads makeWindowControllers];
		[m_downloads setProt:self];
	}
	[m_downloads showWindows];
}

-(void) hideWarning
{
	if ( m_controllerWarning != nil )
	{
		[m_controllerWarning close];
		m_controllerWarning = nil;
	}

}

-(void) displayTerminalWarning
{
	if ( m_controllerWarning == nil )
	{
		m_controllerWarning = [[WarningController alloc] initWindow];
	}
	[m_controllerWarning setLabels:@"Your document was automatically closed" second:@"because Terminal app is running." third:@"Please close Terminal app and re-open the document."];
	[m_controllerWarning showWindow:self];
}

-(void) displayCodeWarning:(unsigned int)docID
{
	if ( m_controllerWarning == nil )
	{
		m_controllerWarning = [[WarningController alloc] initWindow];
	}
	//[self doRemoveDocument:docID];
	[DocumentDB deleteDocument:docID];

	[m_controllerWarning setLabels:@"Your document was automatically closed" second:@"because the authorization code was suspended." third:@"Please contact the publisher and re-authorize the document with new code."];
	[m_controllerWarning showWindow:self];
}

- (IBAction)test:(id)sender
{
	if ( m_catalogWindowController == nil )
	{
		m_catalogWindowController = [[CatalogWindowController alloc] initWithDirectory:nil];
	}
	[m_catalogWindowController showWindow:self];
}

- (IBAction)catalog:(id)sender
{
/*	if ( m_catalogs == nil )
	{
		NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString * documentsDirectory = [paths objectAtIndex:0];
		NSString * fullPath = [documentsDirectory stringByAppendingPathComponent:CATALOG_FILENAME];
		NSURL* url = [NSURL fileURLWithPath:fullPath isDirectory:NO];
		
		NSFileManager* fm = [NSFileManager defaultManager];

		NSURL* myURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
		NSURL* urlCatalogs = [myURL URLByAppendingPathComponent:@"Catalogs"];
		NSString* sss = [myURL absoluteString];
		sss = [myURL path];
		
		if ( [fm fileExistsAtPath:fullPath] )
		{
			//m_downloads = [[DownloadDocument alloc] initWithContentsOfURL:url ofType:DwnDocumentUTI error:nil];
			m_catalogs = [[CatalogDocument alloc] initWithContentsOfURL:url ofType:CatDocumentUTI error:nil];
		}
		else
		{
			m_catalogs = [[CatalogDocument alloc] initWithType:DwnDocumentUTI error:nil];
			[m_catalogs setFileURL:url];
			[m_catalogs setFileType:CatDocumentUTI];
		}
		[m_catalogs makeWindowControllers];
		[m_catalogs setProt:self];
	}*/
	
/*	if ( m_catalogs == nil )
	{
		NSString* sCat = [[General catalogDirectory] stringByAppendingPathComponent:@"catalog.xml"];
		NSURL* url = [NSURL URLWithString:sCat];
		m_catalogs = [[CatalogDocument alloc] initWithContentsOfURL:url ofType:CatDocumentUTI error:nil];
		[m_catalogs makeWindowControllers];
		[m_catalogs setProt:self];
	}
	
	[m_catalogs showWindows];*/
	
	CatalogController* cat = [[CatalogController alloc] init];
	[cat showPanel:nil];

//	CatalogController* cat = [[CatalogController alloc] initWithWindowNibName:@"CatalogController"];
//	[cat showWindow:self];
	
/*	NSRect frame = NSMakeRect(100, 100, 200, 200);
	NSUInteger styleMask =    NSBorderlessWindowMask;
	NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
	NSWindow * window =  [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered    defer:false];
	[window setBackgroundColor:[NSColor blueColor]];
	[window makeKeyAndOrderFront: window];*/
}

/*-(IBAction)downloadFile:(id)sender
{
	@try
	{
		[[Log getLog] addLine:@"About to allocation DownloadController"];
		
		DownloadController *dc = [[DownloadController alloc] init];

		[[Log getLog] addLine:@"About to show DownloadController"];
		m_download = [dc window];
		
	   [NSApp beginSheet: m_download
	   modalForWindow: [NSApp mainWindow]
		modalDelegate: self
	   didEndSelector: nil//@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
		
		//[NSApp runModalForWindow:win];
		//[NSApp endSheet:win];
		//[dc showWindow:nil];
		//[dc showDownload:nil attributes:nil];
		//[win orderOut:self];
	}
	@catch( NSException* ex )
	{
		[[Log getLog] addLine:@"Unable to display DownloadController"];
		[[Log getLog] addLine:[ex name]];
		[[Log getLog] addLine:[ex reason]];
	}
	
}*/

- (void) sendEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
                if ([self sendAction:@selector(cut:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
                if ([self sendAction:@selector(copy:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
                if ([self sendAction:@selector(paste:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"z"]) {
                if ([self sendAction:@selector(undo:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
                if ([self sendAction:@selector(selectAll:) to:nil from:self])
                    return;
            }
        }
        else if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"Z"]) {
                if ([self sendAction:@selector(redo:) to:nil from:self])
                    return;
            }
        }
    }
    [super sendEvent:event];
}


-(void)windowClosed
{
	m_downloads = nil;
}

-(void)catalogWindowClosed
{
	//NSLog(@"CLOSE IN APP");
	m_catalogs = nil;
}

- (void)enableRemovingAuth:(BOOL)bEnable
{
	[m_menuRemoveAuth setEnabled:bEnable];
}

- (BOOL)isTerminalRunning
{
	if ( m_thread != nil )
	{
		return [m_thread isTerminalRunning];
	}
	
	return NO;
}

- (IBAction)removeAuthorisation:(id)sender
{
	NSArray* docs = [self orderedDocuments];
	if ( docs != nil && docs.count > 0 )
	{
		JavelinDocument* doc = (JavelinDocument*)[docs objectAtIndex:0];
		unsigned int docID = [doc documentID];
		[self removeDocument:docID];
		return;
	}
	
	EnterDocID* ent = [[EnterDocID alloc] init];
	[ent showPanel:120];
	
	if ( [ent documentID] != 0 )
	{
		[self removeDocument:[ent documentID]];
	}
}

- (void) removeDocument:(unsigned int)docID
{
	if ( docID != 0 )
	{
		NSAlert *theAlert = [NSAlert alertWithMessageText:@"Remove authorisation?"
											defaultButton:@"Yes"
										  alternateButton:@"No"
											  otherButton:nil
								informativeTextWithFormat:
							 @"%@", [NSString stringWithFormat:@"Are you sure you want to remove authorisation of current document?\nDocumentID: %d\r\n\r\nNote that removal of authorization clears your local authorization settings but will not reset or re-enable your authorization code", 
									 docID] ];
		int nRes = (int)[theAlert runModal];
		if (nRes == NSAlertDefaultReturn)
		{
			[self doRemoveDocument:docID];
		}
	}
}

-(void)doRemoveDocument:(unsigned int)docID
{
	DocumentRecord* dr = [DocumentDB getDocument:docID];
	[DocumentDB deleteDocument:docID];
	
	if ( dr != nil )
		[self removeAuthOnline:docID code:dr.authCode];
	else
		[self removeAuthOnline:docID code:nil];
	
	//close doc (if opened)
	NSArray* docs = [self orderedDocuments];
	if ( docs != nil && docs.count > 0 )
	{
		for( int i=0; i<[docs count]; i++ )
		{
			JavelinDocument* doc = (JavelinDocument*)[docs objectAtIndex:i];
			if ( [doc documentID] == docID )
			{
				[doc close];
				return;
			}
		}
	}
}

- (IBAction)doFullScreenChange:(id)sender
{
	if ( m_bFullScreen )
	{
		//exit full screen mode
		m_bFullScreen = NO;
		[[NSApplication sharedApplication] setPresentationOptions:m_nPresentationModeNormal];
	}
	else
	{
		//Enter full screen mode
		m_bFullScreen = YES;
		m_nPresentationModeNormal = [[NSApplication sharedApplication] currentSystemPresentationOptions];
		[[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
		
	}
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

- (int) removeAuthOnline:(unsigned int)docID code:(NSString *)sCode
{
	NSString *sTemp = nil;
	
	NSMutableString *sRequest = [[NSMutableString alloc]init];

	//create soap envelope
	[sRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[sRequest appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
	[sRequest appendString:@"<soap:Body>"];
	[sRequest appendString:@"<AuthRemoved xmlns=\"http://drumlinsecurity.co.uk/\">"];
	
	sTemp = [NSString stringWithFormat:@"<nDocID>%d</nDocID>", docID ];
	[sRequest appendString:sTemp];
	
	if ( sCode == nil )
		sTemp = [NSString stringWithFormat:@"<sDesc>Mac auth removed: DocID=%d</sDesc>", docID ];
	else
		sTemp = [NSString stringWithFormat:@"<sDesc>Mac auth removed: DocID=%d, Code=%@</sDesc>", docID, sCode ];
	[sRequest appendString:sTemp];
	
	[sRequest appendString:@"</AuthRemoved>"];
	[sRequest appendString:@"</soap:Body>"];
	[sRequest appendString:@"</soap:Envelope>"];
	
	//NSLog(@"%@", sRequest);
	NSURL *myWebserverURL = [NSURL URLWithString:@"http://www.drumlinsecurity.co.uk/Service.asmx"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL]; 
	
	[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"http://drumlinsecurity.co.uk/AuthRemoved" forHTTPHeaderField:@"SOAPAction"];//this is default tempuri.org, I changed mine in the project
	
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
	
	XmlParser *xmlParser = [[XmlParser alloc] initWithName:@"AuthRemovedResponse"];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:d];
	[parser setDelegate:xmlParser];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	
	if ( xmlParser.result == nil )
	{
		return 0;
	}
	
	NSMutableDictionary *res1 = xmlParser.result;
	
	NSDictionary *res = [self getWSResponse:res1];
	
	//NSLog( @"WS Response: %@", res );
	
	NSString* sError = [res objectForKey:@"sError"];

	return 1;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	/*enum {
   NSTerminateCancel = 0,
   NSTerminateNow    = 1,
   NSTerminateLater  = 2
}
	*/
	
	[m_thread stopThread];
	
	NSArray* docs = [self orderedDocuments];
	if ( docs != nil && docs.count > 0 )
	{
		NSString* sMsg = nil;
		for( int i=0; i<docs.count; i++)
		{
			JavelinDocument* doc = (JavelinDocument*)[docs objectAtIndex:i];
			if ( [doc isEdited])
			{
				sMsg = [NSString stringWithFormat:@"%@ has been modified.", [doc displayName]];
				NSAlert *alert = [[NSAlert alloc] init];
					[alert addButtonWithTitle:@"Save"];
					[alert addButtonWithTitle:@"Do not save"];
					[alert addButtonWithTitle:@"Cancel"];
					[alert setMessageText:sMsg];
					[alert setInformativeText:@"Do you want to save the document?"];
					[alert setAlertStyle:NSWarningAlertStyle];

					NSModalResponse res = [alert runModal];
					if ( res == NSAlertFirstButtonReturn) {
						// OK clicked, delete the record
						//NSLog(@"Save");
						[doc saveDocument];
					} else if ( res == NSAlertSecondButtonReturn ){
						//NSLog(@"Do not save");
						//return YES;//close - don't save
					} else {
						//NSLog(@"Cancel");
						return NSTerminateCancel;//don't close
					}
			}
		}
	}


	return NSTerminateNow;
}

@end
