//
//  DownloadController.h
//  Javelin
//
//  Created by harry on 26/08/2013.
//
//

#import <Cocoa/Cocoa.h>

@class DownloadTableView;

#define JAVELIN_DOWNLOAD_FILE		@"JavelinDownload.bin"
#define JAVELIN_DOWNLOAD_KEY		@"javelin_download_key"

#define DOWNLOAD_OK					0
#define DOWNLOAD_ERROR_WRONG_URL	(-1)
#define DOWNLOAD_ERROR_GENERAL		(-2)

@interface DownloadController : NSWindowController <NSURLDownloadDelegate, NSTableViewDelegate, NSTableViewDataSource>
{
@private
	IBOutlet		NSWindow			*m_wndDownload;
	IBOutlet		NSTextField			*m_url;
	IBOutlet		NSProgressIndicator	*m_progress;
	IBOutlet		DownloadTableView	*m_table;
	IBOutlet		NSButton			*m_ok;
	IBOutlet		NSButton			*m_cancel;
	IBOutlet		NSTextField			*m_bytes;
	IBOutlet		NSTextField			*m_percentage;
	IBOutlet		NSTextField			*m_time;
	
	
	NSURL								*m_originalURL;
	NSURL								*m_fileURL;
	BOOL								m_downloadIsIndeterminate;
	float								m_downloadProgress;
	BOOL								m_downloading;
	NSURLDownload						*m_download;
	long long							m_expectedLength;
	long long							m_downloadedSoFar;
	
	NSMutableArray						*m_downloads;
	
	NSNumberFormatter					*m_numberFormat;
	NSDate								*m_startTime;
	float								m_old;

}

- (void)showDownload:(NSWindow *)window attributes:(NSDictionary*)attrs;

- (IBAction)closeDownload: (id)sender;
- (IBAction)downloadAFile: (id)sender;
- (IBAction)openFile:(id)sender;
- (IBAction)deleteItem:(id)sender;
- (IBAction)doubleClick:(id)sender;

- (int) startDownloading:(NSString*)strUrl;
- (void) updateUI:(BOOL)bDownloading;

-(BOOL)writeDownloads;
-(void)loadDownloads;
-(void)refreshTable;

-(BOOL)writeToPlistFile:(NSString*)filename;
-(NSArray*)readFromPlistFile:(NSString*)filename;

-(BOOL)writeToFile:(NSString*)filename;
-(NSArray*)readFromFile:(NSString*)filename;

-(BOOL)writeToPlist;
-(NSArray*)readFromPlist;

-(void)openFileFromURL:(NSURL*)url;

//@property (readonly) NSWindow* window;

@end
