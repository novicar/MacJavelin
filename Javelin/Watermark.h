//
//  Watermark.h
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DocInfo.h"

@interface Watermark : NSObject {
@private
	NSString*	m_sWatermark;
	int			m_nType;
	int			m_nDirection;
	int			m_nHor;
	int			m_nVert;
	int			m_nStartPage;
	int			m_nEndPage;
	short		m_sFontSize;
	NSColor		*m_Color;
	NSFont		*m_Font;
	NSMutableAttributedString *m_sText;
	BOOL		m_bPrintWatermark;
}
/*
- (void)setWatermark:(const unsigned char*)szWatermarkUnicodeText 
			  ofType:(int)type
		 forDocument:(const unsigned char*)szDocName 
			   DocID:(unsigned int)docID
			authCode:(NSString*)authCode;
*/
- (void)setWatermark:(PDOCEX_INFO)pDocInfo
			authCode:(NSString*)sAuthCode;

- (NSString*)watermark;
- (void)expand:(NSString*)sName docID:(unsigned int)docid authCode:(NSString*)authCode;
- (int)type;
- (void)drawFixedAt:(NSPoint)point rect:(NSRect)rect;
- (void)drawAt:(NSPoint)point rect:(NSRect)rect;
- (void)printAt:(NSPoint)point rect:(NSRect)rect;
//- (void) createImage:(NSSize)aSize;
- (BOOL) isPrint;
- (BOOL) isScreen;
- (BOOL) printToPage:(int)nPage;
- (void) allowPrint:(BOOL)bAllow;
- (NSString*) prepareAuthCode:(NSString*)authCode;
@end
