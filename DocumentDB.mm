//
//  DocumentDB.m
//  Javelin
//
//  Created by harry on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DocumentDB.h"
#import "DocumentRecord.h"
#import "Global.h"


@implementation DocumentDB

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}
/*
- (void)dealloc
{
    [super dealloc];
}
*/
+ (DocumentRecord*) getDocument:(UINT)docID
{
	NSString *sKey = [NSString stringWithFormat:@"JavelinDoc_%d", docID];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *data1 = [defaults objectForKey:sKey];
	DocumentRecord *docRec = nil;
		
	if ( data1 != nil )//if record is in the registry - use it.
	{
		docRec = [NSKeyedUnarchiver unarchiveObjectWithData:data1];
		if ( docRec == nil ) return nil;
		if ( [docRec docID] != docID ) 
			return nil;
		return docRec;
	}
	
	return nil;//no document in the DB
}

+ (BOOL) deleteDocument:(UINT)docID
{
	NSString *sKey = [NSString stringWithFormat:@"JavelinDoc_%d", docID];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *data = [defaults objectForKey:sKey];

	if ( data != nil )//if record is in the registry - delete it.
	{
		[defaults removeObjectForKey:sKey];
		return YES;
	}
	
	return NO;
}

+ (void) displayEntries
{
/*	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [defaults dictionaryRepresentation];
	NSArray *arr = [dict allKeys];
	
	for( int i=0; i<[arr count]; i++ )
	{
		NSLog( @"%@", [arr objectAtIndex:i] );
	}*/
}
/*
 - (NSColor *)tableBgColor
 {
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 NSData *colorAsData = [defaults objectForKey:BNRTableBgColorKey];
 return [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];
 } */

+ (INT) setDocument:(PDOCEX_INFO)pDocInfo withHCKS:(BYTE*)hcks andAuthCode:(NSString*)sAuthCode
{
	NSString *sKey = [NSString stringWithFormat:@"JavelinDoc_%d", pDocInfo->dwDocID];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *data1 = [defaults objectForKey:sKey];
	DocumentRecord *docRec = nil;
	
	if ( data1 == nil )
	{
		//no document record - create one
		docRec = [[DocumentRecord alloc] init];
		
	}
	else
	{
		//document record is already in the DB - update it with new values
		docRec = [NSKeyedUnarchiver unarchiveObjectWithData:data1];
		if ( [docRec docID] != pDocInfo->dwDocID )
		{
			docRec = [[DocumentRecord alloc] init ];
		}
		//but first check hash code and if it doesn't match - return error
		BOOL b = [DocumentDB checkHash:docRec];
		if ( b == NO ) return -1;//hashes don't match!
	}
	
	[docRec setOpenCount:pDocInfo->dwOpeningCount];
	[docRec setPrintCount:pDocInfo->dwPrintingCount];
	[docRec setPagesCount:pDocInfo->dwPagesToPrint];
	[docRec setDocID:pDocInfo->dwDocID];
	[docRec setViewMode:0];
	[docRec setZoomLevel:0];
	[docRec setExpires:pDocInfo->dwExpiryDate];
	if (sAuthCode != nil)
		[docRec setAuthCode:sAuthCode];
	
	if ( hcks != nil )
	{
		//set HCKS if not nil
		//[docRec setHCKSBytes:hcks];
		[docRec setByteHcks:hcks];
	}
	else
	{
		BYTE bytes[16];
		for( int i=0; i<16; i++) bytes[i] = '\x0';
		//NSMutableData *ppp = [NSMutableData dataWithBytes:bytes length:16];
		//[docRec setHCKSBytes:bytes];
		[docRec setByteHcks:bytes];
		//[docRec setHcks:ppp];
	}
	
	return [self saveDocRec:docRec];
}	
	

+ (INT) saveDocRec: (DocumentRecord*)docRec
{
	NSString *sKey = [NSString stringWithFormat:@"JavelinDoc_%d", [docRec docID] ];
	
	//recalc hash
	DWORD newHash = [DocumentDB calcHashWithHwID:docRec];
	[docRec setHashCode:newHash];//update
	
	//finally - save DocumentRecord
	NSData *theData=[NSKeyedArchiver archivedDataWithRootObject:docRec];
	[[NSUserDefaults standardUserDefaults] setObject:theData forKey:sKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	//[theData release];
	return 0;
}

+(BOOL) checkHash: (DocumentRecord*)docRec
{
	DWORD calcHash = [DocumentDB calcHashWithHwID:docRec];

	if ( calcHash != (DWORD)[docRec hashCode] )
	{
		//try calculating hash "old style" without HardwareID
		calcHash = [DocumentDB calcHash:docRec];
		if ( calcHash != (DWORD)[docRec hashCode] )
			return NO;
	}
	
	return YES;
}

+(DWORD) calcHash: (DocumentRecord*)docRec
{
	BYTE* buffer = (BYTE*)malloc(16);
	INT openCount = [docRec openCount];
	INT printCount= [docRec printCount];
	INT pagesCount= [docRec pagesCount];
	UINT expires  = [docRec expires];
	
	memcpy( buffer, &printCount, 4 );
	memcpy( buffer+4, &expires, 4 );
	memcpy( buffer+8, &pagesCount, 4 );
	memcpy( buffer+12, &openCount, 4 );
	
	for( int i=0; i<16; i++ )
	{
		buffer[i] ^= (' ' + (char)i);
	}
	
	DWORD calcHash = CGlobal::Hash(buffer, 16);
	
	free( buffer );
	
	return calcHash;
}

+(DWORD) calcHashWithHwID: (DocumentRecord*)docRec
{
	char szSerial[128];
	CGlobal::GetSerialNumber(szSerial, 128);
szSerial[4] = 'F';
	//NSLog( @"Serial:%s", szSerial );
	int nLen = 16 + (int)strlen(szSerial);
	BYTE* buffer = (BYTE*)malloc(nLen+1);
	INT openCount = [docRec openCount];
	INT printCount= [docRec printCount];
	INT pagesCount= [docRec pagesCount];
	UINT expires  = [docRec expires];
	
	memcpy( buffer, &printCount, 4 );
	memcpy( buffer+4, &expires, 4 );
	memcpy( buffer+8, &pagesCount, 4 );
	memcpy( buffer+12, &openCount, 4 );
	memcpy( buffer+16, szSerial, strlen(szSerial) );
	
	for( int i=0; i<nLen; i++ )
	{
		buffer[i] ^= (' ' + (char)i);
	}
	
	DWORD calcHash = CGlobal::Hash(buffer, nLen);
	
	free( buffer );
	
	return calcHash;
}
@end

