//
//  DocumentDB.h
//  Javelin
//
//  Created by harry on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DocInfo.h"
#import "DrumlinTypes.h"
#import "DocumentRecord.h"


@interface DocumentDB : NSObject
{
@private
}

+ (DocumentRecord*) getDocument:(UINT)docID;
+ (INT) setDocument:(PDOCEX_INFO)pDocInfo withHCKS:(BYTE*)hcks andAuthCode:(NSString*)sAuthCode;
+ (INT) saveDocRec: (DocumentRecord*)docRec;
+ (DWORD) calcHash: (DocumentRecord*)data;
+ (DWORD) calcHashWithHwID: (DocumentRecord*)data;
+ (BOOL) checkHash: (DocumentRecord*)docRec;
+ (BOOL) deleteDocument:(UINT)docID;
+ (void) displayEntries;
@end
