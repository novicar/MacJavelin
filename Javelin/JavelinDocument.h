//
//  JavelinDocument.h
//  Javelin
//
//  Created by harry on 8/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "DocInfo.h"

@class JavelinController;
@class JAnnotations;

@interface JavelinDocument : NSDocument {
@private
    NSAttributedString *_fileContents;
	PDOCEX_INFO			_pDocInfo;
	NSString*			m_authCode;
	NSURL*				m_docURL;
	PDFDocument			*m_document;
	BOOL				isClosed;
	JavelinController*	m_controller;
	unsigned int		m_documentID;
	BOOL				m_boolDrm;
    JAnnotations*       m_annotations;
	NSUInteger			m_nFileSize;
}

@property (readonly) PDFDocument* pdfDocument;
@property (readonly) NSString* authCode;
@property (readonly) JAnnotations* annotations;
@property (readonly) NSURL* DocumentURL;
@property (readonly) NSUInteger fileSize; 

- (NSAttributedString*) getFileContents;

//extra DRMX file document info
- (void) setDocumentInfo: (PDOCEX_INFO)pDocInfo;
- (PDOCEX_INFO) docInfo;

- (BOOL) openPDF:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError;
- (BOOL) openDRMX:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError;
- (BOOL) openDRMZ:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError;

- (BOOL)openDrmxDocumentFromData:(NSData*)data error:(NSError**)ppError;

- (BOOL) isClosed;

- (JavelinController*)mainWindowController;

- (BOOL) saveDocument;
- (BOOL) saveAnnotations;
- (void) readAnnotations;
- (BOOL) isDrm;
- (unsigned int) documentID;
- (BOOL) printingEnabled;

- (NSURL*)getNtsUrl:(NSURL*)docURL;

- (BOOL)isEdited;
@end
