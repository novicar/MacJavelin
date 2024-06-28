//
//  CatalogWindowController.h
//  Javelin3
//
//  Created by Novica Radonic on 14/05/2018.
//

#import <Cocoa/Cocoa.h>
#import "CatalogItem.h"
#import "CatalogProtocol.h"
#import "SingleLineTextView.h"
#import "MyGrid.h"
#import "MyTextField.h"

@interface CatalogWindowController : NSWindowController </*NSCollectionViewDelegate,*/ NSCollectionViewDataSource, CatalogProtocol, NSXMLParserDelegate, NSURLSessionDownloadDelegate>
{
	IBOutlet MyGrid* m_collectionView;
	NSMutableArray*				m_contents;
	//NSMutableArray*				m_stackOfCatalogs;
	NSString*					m_sInitialPath;
	CatalogItem*				m_catalogItem;
	
	IBOutlet NSButton*			m_btnRefresh;
	IBOutlet NSButton*			m_btnDownload;
	IBOutlet NSButton*			m_btnBack;
	IBOutlet MyTextField*		m_txtURL;
	IBOutlet NSTextField*		m_lblError;
	IBOutlet NSProgressIndicator*	m_progress;
	IBOutlet NSTextField*		m_lblPercent;
	IBOutlet NSTextField*		m_lblBytes;
	
	NSString*					m_sElementName;
	NSMutableDictionary*		m_item;
	NSMutableString*			m_sCurrentString;
	NSString*					m_sCurrentCatalog;
	NSString*					m_sCatalogURL;
	BOOL						m_bDownloading;
	NSURLDownload* 				m_download;
	NSURLSessionDownloadTask*	m_downloadTask;
	
	NSImage*					m_imageDownload;
	NSImage*					m_imageExit;
	NSImage*					m_imageBack;
	
	CatalogItem*				m_selectedItem;
	
	//NSString*					m_sInitialCatalogName;
	BOOL						m_bAskToRefresh;
	BOOL						m_bOpenFile;
	NSString*					m_sDestFile;
	NSURL*						m_urlFile;
}

- (id)initWithDirectory:(NSString*)sDirectory;

-(void)loadData:(NSString*)sCatalogPath;
-(BOOL)loadXMLCatalog:(NSString*)sCatalogPath;
-(void)loadWithDelay:(NSString*) sCatalog;
-(void)loadDirectory:(NSString*)sPath;
- (BOOL)parseXMLFile:(NSString *)pathToFile;
-(void)checkCatalogDirectory:(NSString*)sCatalog;
- (BOOL) openCatalog:(NSString*)sCatalog;
-(void)openCatalogItem:(CatalogItem*)pItem;
-(void)openDocumentAndCloseWindow:(NSString*)sDocument;
-(BOOL)downloadNewCatalog:(NSString*)sURL toDirectory:(NSString*)sDestDir openCatalog:(NSString*)sCatalogPath;
-(void)downloadFile:(NSURL*)urlFile toLocation:(NSString*)sDestFIle autoOpen:(BOOL)bOpenFile fromDropbox:(BOOL)bDropbox;
-(void)downloadIcon:(NSURL*)urlFile toLocation:(NSString*)sDestFIle fromDropbox:(BOOL)bDropbox;
-(void)deleteItem:(CatalogItem*)pItem;
-(void)refreshItem:(CatalogItem*)pItem;
-(void)displayItem:(CatalogItem*)pItem;
-(void)openItemFolder:(CatalogItem*)pItem;

-(IBAction) back:(id)sender;
-(IBAction) download:(id)sender;
-(IBAction) refresh:(id)sender;

-(void)setMyTitle:(NSString*)sTitle;
-(void)doRefresh;
-(BOOL)unzip:(NSString*)sZipFile toDestinationDir:(NSString*)sDestDir;
-(BOOL)openZippedCatalog:(NSString*)sZipFile title:(NSString*)sTitle;

-(void)deleteCatalog:(id)sender;
-(void)refreshCatalog:(id)sender;
-(void)catalogInfo:(id)sender;
-(void)deleteDocument:(id)sender;
-(void)refreshDocument:(id)sender;
-(void)documentInfo:(id)sender;
-(void)openFolder:(id)sender;
-(void)openCatalogAsText:(id)sender;
-(void)refreshDocumentImage:(id)sender;
-(void)removeAuthorization:(id)sender;

-(void)removeAuthorizationFromItem:(CatalogItem*)pItem withPrompt:(BOOL)bPrompt;

-(void)openDocument:(NSString*) sDocument withDelay:(NSTimeInterval)seconds;
@end
