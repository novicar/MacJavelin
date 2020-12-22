//
//  DocumentRecord.h
//  Javelin
//
//  Created by harry on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DrumlinTypes.h"
#import "DocInfo.h"

@interface DocumentRecord : NSObject <NSCoding>
{
@private
	UINT		docID;
	INT			openCount;
	INT			printCount;
	INT			pagesCount;
	UINT		expires;
	INT			viewMode;
	float		zoomLevel;
	DWORD		hashCode;
	NSString	*authCode;
	//NSMutableData		*hcks;
	INT			extraInt;
	float		extraFloat;
	NSString	*extraString;
	NSMutableData		*extraData;
	BYTE		*byteHcks;
	BOOL		bRelaxedPrinting;
}

@property (readwrite) UINT docID;
@property (readwrite) INT openCount;
@property (readwrite) INT printCount;
@property (readwrite) INT pagesCount;
@property (readwrite) UINT expires;
@property (readwrite) INT viewMode;
@property (readwrite) float zoomLevel;
@property (readwrite) DWORD hashCode;
@property (readwrite, copy) NSString* authCode;
//@property (readwrite, copy) NSMutableData* hcks;
@property (readwrite) INT extraInt;
@property (readwrite) float extraFloat;
@property (readwrite, copy) NSString* extraString;
@property (readwrite, copy) NSMutableData* extraData;
@property (readwrite, assign) BOOL relaxedPrinting;

- (NSString*) expiresString;
//-(void) setHCKSBytes: (BYTE*)hcks1;
//-(void) setHcks: (NSMutableData*)data;
//-(NSMutableData*) hcks;

-(void) setByteHcks: (BYTE*)hcks1;
-(BYTE*) byteHcks;

-(void) initWithDocExInfo:(PDOCEX_INFO)pDocInfo;
-(void) initWithDocExInfo:(PDOCEX_INFO)pDocInfo hcks:(BYTE*)pHcks andAuthCode:(NSString*)sAuthCode;
@end
