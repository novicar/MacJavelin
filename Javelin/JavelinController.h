//
//  JavelinController.h
//  Javelin
//
//  Created by harry on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "JavelinPdfView.h"
#import "DocInfo.h"
#import "NoteProtocol.h"
#import "NoteViewProtocol.h"
//#import "NewThumbsView.h"

#define kPDFViewXDelta			0
#define kPDFViewYDelta			80

#define kURLLink				0
#define kDestinationLink		1

//@class JavelinApplication;
@class PropertiesController;
@class Note;
@class FreeNoteWindow;
@class FreeNoteController;
@class SearchController;
@class MyThumbnailView;
@class JavelinNotes;

//@interface JavelinController : NSWindowController <NSToolbarDelegate,NSOutlineViewDelegate,NSOutlineViewDataSource,NSWindowDelegate, NoteProtocol, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>
@interface JavelinController : NSWindowController <NSToolbarDelegate,NSOutlineViewDelegate,NSOutlineViewDataSource,NSWindowDelegate, NoteProtocol>
{
	Note*	m_pNote;
    IBOutlet JavelinPdfView         *_pdfView;
    PDFOutline                      *_outline;					// Outline
    IBOutlet NSOutlineView			*_outlineView;				//    "
    BOOL							_ignoreNotification;		//    "
    IBOutlet NSDrawer				*_drawer;
	IBOutlet MyThumbnailView			*_thumbs;					//thumbnail view
    
    IBOutlet NSSegmentedControl		*_backForwardView;			// Toolbar: Back-Forward.
	NSToolbarItem					*_toolbarBackForwardItem;	//    "
    
    IBOutlet NSSegmentedControl		*_navigationView;			// Toolbar: Navigation.
	NSToolbarItem					*_toolbarNavigationItem;	//    "

    IBOutlet NSTextField			*_pageNumberView;			// Toolbar: Page number.
	NSToolbarItem					*_toolbarPageNumberItem;	//    "
	
	IBOutlet NSTextField			*_pageCount;
	NSToolbarItem					*_toolbarPageCountItem;	//    "
	
    IBOutlet NSSearchField			*_searchFieldView;			// Toolbar: Search Field.
	IBOutlet NSSearchFieldCell		*_searchFieldCell;			//
	NSToolbarItem					*_toolbarSearchFieldItem;	//    "

    IBOutlet NSSegmentedControl		*_viewModeView;				// Toolbar: View Mode.
	NSToolbarItem					*_toolbarViewModeItem;		//    "

	IBOutlet id						_pageNumberPanel;			//    "
	IBOutlet NSTextField			*_pageNumberPanelText;		//    "
	IBOutlet NSTextField			*_pageNumberPanelRange;		//    "

    IBOutlet NSToolbar              *_toolbar;                  //    "
	
	IBOutlet NSSegmentedControl		*_zoomInOutView;			// Toolbar: zoom-in/zoom-out
	NSToolbarItem					*_toolbarZoomInOutItem;		//    "

    
    NSMutableArray					*_searchResults;			// Searching
	NSMutableArray					*_sampleStrings;			// Searching
	NSDate							*_searchTime;
    IBOutlet NSTableView			*_searchResultsTable;
    
    IBOutlet NSSplitView			*_splitView;

	IBOutlet NSMenuItem*			m_print;
	
	UINT							m_documentID;
	NSURL							*m_docUrl;
	PropertiesController			*m_properties;
	
	FreeNoteWindow*					m_wndFreeNote;
	FreeNoteController*				m_ctrlNote;
	PDFDisplayMode					m_oldDisplayMode;
    
//	IBOutlet JavelinApplication*	m_app;

	IBOutlet NSButton*	m_btnFind;
	
	SearchController*				m_searchController;
    
    IBOutlet JavelinNotes*          m_notes;
	BOOL m_bWarningDisplayed;
	
	//IBOutlet NewThumbsView*			m_newThumbs;
	
}
-(void)checkCode:(NSString*)sCode docID:(NSString*)sDocID;
-(NSDictionary*) getWSResponse: (NSDictionary*)dict;
-(void)closeAndDisplayCodeWarning:(unsigned int)docID;

//PDF file opening
- (BOOL)openPdfFile: (NSURL*) url;
- (BOOL)openPdfDocumentFromData: (NSData*)data;

//DRMX file
- (BOOL) openDrmxFile:(NSURL *)url;
- (BOOL) openDrmxDocumentFromData: (NSData*)data error:(NSError**)ppError;

- (BOOL) openDoc:(PDFDocument*)pdfDoc 
	 withDocInfo:(PDOCEX_INFO)pDocInfo 
		authCode:(NSString*)authCode;

- (IBAction) printJavelinDocument: (id) sender;

- (void) updateOutlineSelection;

- (void) setupDocumentNotifications;
- (void) setupToolbarForWindow: (NSWindow *) window;

//- (void)doLoad;

- (IBAction) doSearch: (id) sender;
- (IBAction) doFindText: (id) sender;

- (void) setSearchResultsViewHeight: (float) height;
- (NSAttributedString *) getContextualStringFromSelection: (PDFSelection *) instance;

- (void) updateBackForwardState: (NSNotification *) notification;
- (void) updatePageNumberField: (NSNotification *) notification;
- (void) updateViewMode: (NSNotification *) notification;

- (void) toggleDrawer: (id) sender;
- (void) downloadFile: (id) sender;

- (IBAction) doGoBackForward: (id) sender;

- (IBAction) doGoToPage: (id) sender;
- (IBAction) doNavigate: (id) sender;
- (IBAction) doChangeMode: (id) sender;

- (IBAction) doZoomInOut: (id) sender;

- (int) getPageIndexFromLabel: (NSString *) label;

//- (JavelinPdfView*)javelinView;

- (IBAction) showProperties: (id)sender;

-(IBAction) dummyPrint: (id)sender;
-(IBAction) openAboutPanel:(id)sender;
-(IBAction) doCloseMe:(id)sender;
-(IBAction) doSaveMe:(id)sender;

-(void)closeDrawer;
-(void)setupMyView:(PDOCEX_INFO)pDocInfo withAuthCode:(NSString*)authCode;
-(void)setupNewThumbs;
-(void) windowWillClose:(NSNotification*)notification;
//- (IBAction) removeAuthorisation:(id)sender;

-(void)noteDidResize:(id)sender;
-(void)noteDidResignMain:(id)sender;

- (IBAction)doFullScreen:(id)sender;

- (BOOL) isEdited;
- (void) receivedNotificationTerminalRunning:(NSNotification *) notification;
- (void) terminalWarning;
@end
