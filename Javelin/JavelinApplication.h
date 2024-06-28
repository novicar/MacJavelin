//
//  JavelinApplication.h
//  Javelin
//
//  Created by MacMini on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DownloadProtocol.h"
//#import "Catalogs/CatalogProtocol.h"
#import "ScannerThread.h"
#import "CatalogWindowController.h"
#import "WarningController.h"
#import "FirstOne.h"

@class DownloadDocument;
@class CatalogController;

@interface JavelinApplication : NSApplication <NSApplicationDelegate, DownloadProtocol/*, CatalogProtocol*/>
{
	//NSWindow* m_download;
	DownloadDocument* m_downloads;
	CatalogController* m_catalogs;
	CatalogWindowController* m_catalogWindowController;
	WarningController* m_controllerWarning;
	FirstOne*	m_firstOne;
	
	IBOutlet	NSMenuItem*	m_menuRemoveAuth;
	IBOutlet NSView *m_customView;
	
	unsigned int	m_currentDocumentID;
	
	BOOL m_bFullScreen;
	NSApplicationPresentationOptions m_nPresentationModeNormal;
	ScannerThread* m_thread;
}

@property (readwrite,atomic) unsigned int currentDocumentID;
- (IBAction)openAboutPanel:(id)sender;
- (IBAction)writeLogFile: (id) sender;
- (IBAction)showDrumlinHelp: (id) sender;
- (IBAction)gotoDrumlinWeb:(id)sender;
- (IBAction)downloadFile:(id)sender;
- (IBAction)catalog:(id)sender;
- (IBAction)test:(id)sender;
- (IBAction)doFullScreenChange:(id)sender;
- (IBAction)checkNewVersion:(id)sender;
- (IBAction)autoRefreshCatalog:(id)sender;

- (void)enableRemovingAuth:(BOOL)bEnable;

- (IBAction)removeAuthorisation:(id)sender;
- (void)removeCurrentDocumentAuthorization;

- (void) removeDocument:(unsigned int)docID;
- (void) doRemoveDocument:(unsigned int)docID;

- (int) removeAuthOnline:(unsigned int)docID code:(NSString*)sCode;
- (NSDictionary*) getWSResponse: (NSDictionary*)dict;

- (NSString *)runCommand:(NSString *)commandToRun;
- (void) checkCatalogDir;

- (NSString*)isBadProcessRunning;
- (BOOL)isTerminalRunning;
- (void)displayTerminalWarning;
- (void)hideWarning;
- (void)displayCodeWarning:(unsigned int)docID;
- (void)loadDocumentList;
- (void)saveDocumentList;
- (void)doCheckVersion:(BOOL)bSilent;

- (void) openFirstWindow;

@end
