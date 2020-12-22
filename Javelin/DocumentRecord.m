//
//  DocumentRecord.m
//  Javelin
//
//  Created by harry on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DocumentRecord.h"


@implementation DocumentRecord

@synthesize docID;
@synthesize openCount;
@synthesize pagesCount;
@synthesize printCount;
@synthesize expires;
@synthesize viewMode;
@synthesize zoomLevel;
//@synthesize hcks;
@synthesize extraInt;
@synthesize extraFloat;
@synthesize extraData;
@synthesize extraString;
@synthesize hashCode;
@synthesize authCode;
@synthesize relaxedPrinting = bRelaxedPrinting;

- (id)init
{
    self = [super init];
    if (self) {
		
		docID = 0;
		expires = 0;
		openCount = 0;
		pagesCount = 0;
		printCount = 0;
		viewMode = 0;
		zoomLevel = 1.0;
		extraInt = 0;
		extraFloat = 0.0;
		hashCode = 0;
		authCode = nil;
		bRelaxedPrinting = NO;
		
//		BYTE d[16];
//		for( int i=0; i<16; i++ ) d[i] = '\x0';
        //hcks = [NSMutableData dataWithLength:16];
		extraData = [NSMutableData data];
//		extraData = [[NSMutableData alloc ] initWithBytes:d length:16];
		extraString = nil;
		
		byteHcks = (BYTE*)malloc(16);
    }
    
    return self;
}
/*
- (void)dealloc
{
	free( byteHcks );
	//[hcks release];
	//if ( extraData != nil ) [extraData release];
	//if ( extraString != nil ) [extraString release];
    [super dealloc];
}
*/
/*
-(void) setHCKSBytes: (BYTE*)hcks1
{
	//[hcks release];
//	hcks = [NSMutableData dataWithBytes:hcks1 length:16];
	NSRange range = NSMakeRange(0, 16);
	NSLog( @"hcks len=%lu", [hcks length] );
	for( int i=0; i<16; i++ )
	{
		NSLog( @"byte[%d]=%x", i, (0x000000ff&hcks1[i]) );
	}
	[hcks replaceBytesInRange:range withBytes:hcks1];
}

-(void) setHcks: (NSMutableData*)data
{
//	[hcks release];
//	hcks = [NSMutableData dataWithData:data];
//	[hcks setData:data];
	[data retain];
	[hcks release];
	hcks = data;
}

-(NSMutableData*) hcks
{
	return hcks;
}
*/
-(void) setByteHcks: (BYTE*)hcks1
{
	if ( byteHcks == nil ) byteHcks = (BYTE*)malloc(16);
	for( int i=0; i<16; i++ ) byteHcks[i] = hcks1[i];
}

-(BYTE*) byteHcks
{
	return byteHcks;
}

/*-(void) hcks1: (BYTE*)data
{
//	[hcks getBytes:data length:16];
}
 */


//// NSCoder implementation //////
-(id) initWithCoder:(NSCoder *)aDecoder
{
	//[super init];
	
	//NSKeyedArchiver / NSKeyedUnarchiver
	openCount	= [aDecoder decodeIntForKey:@"openCount"];
	printCount	= [aDecoder decodeIntForKey:@"printCount"];
	pagesCount	= [aDecoder decodeIntForKey:@"pagesCount"];
	viewMode	= [aDecoder decodeIntForKey:@"viewMode"];
	docID		= [aDecoder decodeIntForKey:@"docID"];
	expires		= [aDecoder decodeIntForKey:@"expires"];
	zoomLevel	= [aDecoder decodeFloatForKey:@"zoomLevel"];
//	hcks		= [aDecoder decodeObjectForKey:@"hcks"];
	hashCode	= [aDecoder decodeIntForKey:@"hashCode"];
	extraInt	= [aDecoder decodeIntForKey:@"extraInt"];
	extraFloat	= [aDecoder decodeFloatForKey:@"extraFloat"];
	extraString	= [aDecoder decodeObjectForKey:@"extraString"];
	//authCode	= [NSString stringWithString:(NSString *)[aDecoder decodeObjectForKey:@"authCode"]];
	[self setAuthCode:(NSString *)[aDecoder decodeObjectForKey:@"authCode"]];
	//NSLog( @"AuthCode loaded:%@", self.authCode );
	//extraData	= [aDecoder decodeObjectForKey:@"extraData"];
	
	NSUInteger nLen = 0;
	const uint8_t* bytes	= [aDecoder decodeBytesForKey:@"byteHcks" returnedLength:&nLen];
	if ( nLen > 16 )
	{
		free( byteHcks );
		byteHcks = (BYTE*)malloc( nLen );
	}
	if ( byteHcks == nil )
	{
		byteHcks = (BYTE*)malloc( nLen );
	}
	for( int i=0; i<nLen; i++ ) byteHcks[i] = bytes[i];
	
/*		NSArchiver / NSUnarchiver
	[aDecoder decodeValueOfObjCType: @encode(UINT) at: &docID];
	[aDecoder decodeValueOfObjCType: @encode(INT) at: &openCount];
	[aDecoder decodeValueOfObjCType: @encode(INT) at: &printCount];
	[aDecoder decodeValueOfObjCType: @encode(INT) at: &pagesCount];
	[aDecoder decodeValueOfObjCType: @encode(UINT) at: &expires];
	[aDecoder decodeValueOfObjCType: @encode(INT) at: &viewMode];
	[aDecoder decodeValueOfObjCType: @encode(float) at: &zoomLevel];
*/
//	[hcks initWithCoder:aDecoder];
	
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	//[super encodeWithCoder:aCoder];
	//NSArchiver / NSUnarchiver
/*	[aCoder encodeValueOfObjCType: @encode(UINT) at: &docID];
	[aCoder encodeValueOfObjCType: @encode(INT) at: &openCount];
	[aCoder encodeValueOfObjCType: @encode(INT) at: &printCount];
	[aCoder encodeValueOfObjCType: @encode(INT) at: &pagesCount];
	[aCoder encodeValueOfObjCType: @encode(UINT) at: &expires];
	[aCoder encodeValueOfObjCType: @encode(INT) at: &viewMode];
	[aCoder encodeValueOfObjCType: @encode(float) at: &zoomLevel];
*/
	//NSKeyedArchiver / NSKeyedUnarchiver
	[aCoder encodeInt:openCount forKey:@"openCount"];
	[aCoder encodeInt:printCount forKey:@"printCount"];
	[aCoder encodeInt:pagesCount forKey:@"pagesCount"];
	[aCoder encodeInt:viewMode forKey:@"viewMode"];
	[aCoder encodeInt:docID forKey:@"docID"];
	[aCoder encodeInt:expires forKey:@"expires"];
	[aCoder encodeFloat:zoomLevel forKey:@"zoomLevel"];
//	[aCoder encodeObject:hcks forKey:@"hcks"];
	[aCoder encodeInt:hashCode forKey:@"hashCode"];
	[aCoder encodeInt:extraInt forKey:@"extraInt"];
	[aCoder encodeFloat:extraFloat forKey:@"extraFloat"];
	if ( extraString != nil )
		[aCoder encodeObject:extraString forKey:@"extraString"];
	if ( authCode != nil )
	{
		[aCoder encodeObject:authCode forKey:@"authCode"];
		//NSLog( @"AuthCode saved:%@", authCode );
	}
	//	if ( extraData != nil )
//		[aCoder encodeObject:extraData forKey:@"extraData"];
	if ( byteHcks != nil )
		[aCoder encodeBytes:byteHcks length:16 forKey:@"byteHcks"];
//	[hcks encodeWithCoder:aCoder];
}

-(void) initWithDocExInfo:(PDOCEX_INFO)pDocInfo hcks:(BYTE*)pHcks andAuthCode:(NSString*)sAuthCode
{
	[self initWithDocExInfo:pDocInfo];
	
	if ( pHcks != nil )
	{
		[self setByteHcks:pHcks];
	}
	
	if ( sAuthCode != nil )
	{
//		self.authCode = [[NSString alloc] initWithString:sAuthCode];
		[self setAuthCode:sAuthCode];
		//NSLog( @"AuthCode:%@", authCode );
	}
}

-(void) initWithDocExInfo:(PDOCEX_INFO)pDocInfo
{
	[self setOpenCount:pDocInfo->dwOpeningCount];
	[self setPrintCount:pDocInfo->dwPrintingCount];
	[self setPagesCount:pDocInfo->dwPagesToPrint];
	[self setDocID:pDocInfo->dwDocID];
	[self setViewMode:0];
	[self setZoomLevel:0];
	
	DWORD dwExpiry = 0;
	if ( pDocInfo->nExpiresAfter == -1 )
	{
		dwExpiry = pDocInfo->dwExpiryDate;
	}
	else
	{
		NSCalendarDate *date = [NSCalendarDate calendarDate];
		unsigned int nYear = (unsigned int)[date yearOfCommonEra];
		unsigned int nMonth= (unsigned int)[date monthOfYear];
		unsigned int nDay  = (unsigned int)[date dayOfMonth];
		
		nYear <<= 16;
		nMonth <<= 8;
		DWORD dwNow = nYear + nMonth + nDay;	
		dwExpiry = dwNow + pDocInfo->nExpiresAfter;
	}
	[self setExpires:dwExpiry];
}

- (NSString*) expiresString
{
	UINT nYear = (expires & 0xffff0000) >> 16;
	UINT nMonth = (expires & 0x0000ff00) >> 8;
	UINT nDay = (expires & 0x000000ff);
	
	return [NSString stringWithFormat:@"%04d-%02d-%02d", nYear, nMonth, nDay ];
}
@end
