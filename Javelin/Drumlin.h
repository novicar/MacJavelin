//
//  Drumlin.h
//  Javelin
//
//  Created by harry on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DocInfo.h"

@interface Drumlin : NSObject {
@private
    PDOCEX_INFO m_pDiex;
	NSWindow	*m_pWindow;
	UINT		m_documentID;
	NSString	*m_sAuthCode;
}

- (NSData*)openDrmxFile: (NSURL*) url error:(NSError**)ppError;
- (NSData*)openDrmxFileFromData: (NSData*) data error:(NSError**)ppError;
- (INT) canOpenDocument: (PDOCEX_INFO)pDocInfo withKey: (BYTE*)pKey error:(NSError**)ppError;
//-(void) callWS;
- (NSDictionary*) getWSResponse: (NSDictionary*)dict;
- (NSString*) getVolumeInfo: (NSString*) sServiceName key:(NSString*)sKey;
//- (bool) getHCKSfromDB: (BYTE*)hcks forDocument: (UINT)dwDocID;
- (bool) getHCKSfromServer:(BYTE*)hcks forDocument:(UINT)dwDocID andCode:(NSString*) sCode error:(NSError**)ppError;
- (unsigned long) authoriseDocument: (UINT)dwDocID OSID:(NSString*)sOSID DiskID:(UINT)nDiskID withCode:(NSString*)sCode get:(BYTE*)hcks error:(NSError**)ppError;
-(INT) doOnlineAuthorisation:(PDOCEX_INFO)pDocInfo getHcks:(BYTE*)pHcks getAuthCode:(char*)szAuthCode error:(NSError**)ppError;

- (void) setWindow: (NSWindow*) pWindow;
- (void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError;
- (PDOCEX_INFO)docInfo;
- (UINT) getDocID;
- (NSString*)getAuthCode;
//- (NSString*) getMACAddress: (BOOL)stripColons;
@end
