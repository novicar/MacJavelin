//
//  CatalogController.h
//  Javelin3
//
//  Created by Novica Radonic on 04/05/2018.
//

#import <Cocoa/Cocoa.h>
#import "CatalogProtocol.h"
#import "CatalogItem.h"

@interface CatalogController : NSWindowController </*NSCollectionViewDelegate, NSCollectionViewDataSource, */CatalogProtocol, NSXMLParserDelegate/*, NSURLDownloadDelegate*/>
{
	IBOutlet NSCollectionView* m_collectionView;
	IBOutlet NSButton* 		m_btnClose;
	IBOutlet NSWindow*		m_window;
	IBOutlet NSButton*		m_btnBack;
	IBOutlet NSProgressIndicator* m_progress;
	IBOutlet NSTextField*	m_lblError;
	IBOutlet NSTextView*	m_txtDownload;
	IBOutlet NSButton*		m_btnDownload;
	IBOutlet NSButton*		m_btnRefresh;
	
	CatalogItem*			m_catalogItem;
	NSMutableDictionary*	m_item;
	NSMutableArray*			m_contents;
	
	NSString*				m_sInitialPath;
	NSString*				m_sCatalogURL;
	
	NSMutableString*		m_sCurrentString;
	NSString*				m_sElementName;
	
	NSMutableArray*			m_stackOfCatalogs;
	NSString*				m_sCurrentCatalog;
	
	long long				m_expectedContentLength;
	BOOL					m_bDownloadIsIndeterminate;
	long long				m_downloadedSoFar;
	NSDate*					m_startTime;
	float 					m_fDownloadProgress;
	NSNumberFormatter*		m_numberFormat;
	float					m_old;
	NSURL* 					m_urlLocalFile;
	BOOL					m_bDownloading;
	NSURLDownload* 			m_download;
	NSURLSessionDownloadTask*	m_downloadTask;
}

//@property (nonatomic, assign, readwrite) id <CatalogProtocol> prot;
@property (nonatomic, readwrite, copy) NSString* catalogURL;

-(IBAction) close:(id)sender;
-(IBAction) back:(id)sender;
-(IBAction) download:(id)sender;
-(IBAction) refresh:(id)sender;

- (void) showPanel:(NSString*)sCatalogPath;
- (BOOL) loadXMLCatalog:(NSString*)sCatalogPath;
- (BOOL) parseXMLFile:(NSString *)pathToFile;
- (void) loadDirectory:(NSString*)sPath;
- (BOOL) openCatalog:(NSString*)sCatalog;
- (void) openCatalogItem:(CatalogItem*)pItem;
- (int) addLevel:(NSString*)sFile;
- (NSString*) removeLevel;
- (NSString*) getTopLevel;
- (void) checkCatalogDirectory:(NSString*)sCatalog;
-(void)downloadFile:(NSURL*)urlFile toLocation:(NSString*)sDestFIle autoOpen:(BOOL)bOpenFile;
- (void) openDocumentAndCloseWindow:(NSString*)sDocument;
-(BOOL)downloadNewCatalog:(NSString*)sURL toDirectory:(NSString*)sDestDir openCatalog:(NSString*)sCatalogPath;

@end
