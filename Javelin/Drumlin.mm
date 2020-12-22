//
//  Drumlin.mm
//  Javelin
//
//  Created by harry on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Drumlin.h"
#import "Filer.h"
//#import "Counters.h"
#import "Global.h"
#import "General.h"

#import "KeyGen.h"
#import "md5.h"
//#import "WebService.h"
#import "XmlParser.h"
#import "Base64.h"
#import "DocumentRecord.h"
#import "DocumentDB.h"
#import "AuthController.h"
#import "SheetRunner.h"
#import "Version.h"
#import "Log.h"
#import "VarSystemInfo.h"

//#import <SCNetworkConfiguration.h>


@implementation Drumlin
/*
+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	NSLog(@"registered %@", defaultValues);
}
*/
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		m_pWindow = nil;
		m_pDiex = NULL;
		m_documentID = 0;
    }
    
    return self;
}
/*
- (void)dealloc
{
	if ( m_pDiex ) delete m_pDiex;
	m_pDiex = NULL;
    [super dealloc];
}
*/
- (UINT)getDocID
{
	return m_documentID;
}

- (PDOCEX_INFO)docInfo
{
	return m_pDiex;
}

- (void) setWindow:(NSWindow *)pWindow
{
	m_pWindow = pWindow;
}

- (NSData*) openDrmxFile: (NSURL*)url error:(NSError**)ppError
{
    NSFileManager *fm;
    NSData *data;
    
    fm = [NSFileManager defaultManager];
    
    if ( [fm isReadableFileAtPath:[url path]] == YES )
    {
        data = [fm contentsAtPath:[url path]];
        NSData* resData = [self openDrmxFileFromData:data error:ppError];
        //[data release];
        
        return resData;
    }
	
	if ( ppError != NULL )
	{
		[self createError:@"ERROR: Unable to read file." errorCode:-20 error:ppError];
	}
 
    return nil;
}

-(NSData*) openDrmxFileFromData:(NSData *)data error:(NSError**)ppError
{
	CFiler Filer;
	PDOCEX_INFO pdiex = new DOCEX_INFO;//Document information structure
	ENCRYP	enc;
    
	char key[32];
	char iv[32];
	char keySPLIT[32];
	
	//set header and data decryption keys
	CKeyGen::Iv( iv );
	CKeyGen::Key( key );
    
	enc.nBlockSize = 32;
	enc.nKeyLen = 32;
	enc.pHeaderIV = (BYTE*)iv;
	enc.pHeaderKey = (BYTE*)key;
	enc.pDataIV = (BYTE*)iv;
	enc.pDataKey = (BYTE*)key;
	
	unsigned int uLen = 0;
	int nOffset = 0;
	int nPDKVer = 0;
	int nSimple = 0;
	pdiex->dwDocID = 0;    
    
		
    //load DRMX file header
	int fh = Filer.LoadHeaderFromData( pdiex, (BYTE*)[data bytes], (UINT)[data length], &uLen, &nOffset, &nPDKVer, &enc );
	
	if ( fh <= 0 )
	{
		//try with "SIMPLE" encryption
		nSimple = 1;
		[[Log getLog] addLine:@"DBG: openDrmxFileFromData - trying with simple encryption"];
		fh = Filer.LoadHeaderFromData( pdiex, (BYTE*)[data bytes], (UINT)[data length], &uLen, &nOffset, &nPDKVer, NULL );
	}

	if ( fh > 0 )
	{
		//get document part of the encryption key for decryption of document data
		BYTE* keyHCKS = new BYTE[16];
		for( int i=0; i<16; i++ ) keyHCKS[i] = 0;

		//see if I can open this document.
		//the document will be authorised if not already in local DB
		INT nRes = [self canOpenDocument:pdiex withKey:keyHCKS error:ppError ];
		
		// Check counters in header, expiration date etc.
		if ( nRes < 0 )
		{
			[[Log getLog] addLine:@"DBG: openDrmxFileFromData - Cannot open document [counters/expiration]"];
			delete [] keyHCKS;
			delete pdiex;
			return nil;
		}

		//if HCKS is defined - use it for opening
		if ( (keyHCKS[0] != 0 || keyHCKS[1] != 0 || keyHCKS[2] != 0 || keyHCKS[3] != 0 || keyHCKS[4] != 0 || 
			keyHCKS[5] != 0) && pdiex->byAdditional[0] != 0x01)
		{
			for( int i=0; i<16; i++ )
			{
				keySPLIT[i] = pdiex->byAdditional[i+1];
				keySPLIT[i+16] = keyHCKS[i];
			}
			enc.pDataKey = (BYTE*)keySPLIT;
		}
		delete [] keyHCKS;
        
		//document is decrypted - load it
		BYTE* pData = new BYTE[ uLen ];
		int nR = 0;
		bool bSelfAuth = (pdiex->byAdditional[127] == 80);
		
		[[Log getLog] addLine:@"DBG: openDrmxFileFromData - Loading document"];
		if ( nSimple )
			nR = Filer.LoadDocumentFromData( (BYTE*)[data bytes], (UINT)[data length], nOffset, pData, uLen, NULL, bSelfAuth );
		else
			nR = Filer.LoadDocumentFromData( (BYTE*)[data bytes], (UINT)[data length], nOffset, pData, uLen, &enc, bSelfAuth );
			
		if ( 0 != nR )
		{
			//wsprintf( szTemp, _T("%s (%d)"), g_pLingua->GetText( _T("UNABLE_2_LOAD"), _T("ERROR: Unable to load document.") ), nR );
			[[Log getLog] addLine:@"DBG: openDrmxFileFromData - unable to load document"];
			if ( ppError != NULL )
			{
				[self createError:@"ERROR: Unable to load document." errorCode:-10 error:ppError];
			}
			delete pdiex;
			delete [] pData;
			return nil;
		}
		
		//do we have a real PDF document after decryption?
		if ( pData[0] != '%' || pData[1] != 'P' || pData[2] != 'D' || pData[3] != 'F' )
		{
			[[Log getLog] addLine:@"DBG: openDrmxFileFromData - Unable to decrypt (Wrong key?)"];
			
			//No - it's probably a decryption problem. (Wrong key?)
			if ( ppError != NULL )
			{
				[self createError:@"ERROR: Unable to decrypt document. (Wrong key?)" errorCode:-11 error:ppError];
			}
			delete pdiex;
			delete [] pData;
			return nil;
		}
		
		//save document information about currently opened document
		if ( m_pDiex != NULL ) delete m_pDiex;
			m_pDiex = pdiex;
		
		[[Log getLog] addLine:@"DBG: openDrmxFileFromData - Document loaded OK"];
		//store document data in NSData object that will be returned to the caller
		NSData *dataNew = [NSData dataWithBytes:pData length:uLen];
		
		delete [] pData;
		
		return dataNew;
	}
	
	if ( ppError != NULL )
	{
		[[Log getLog] addLine:@"DBG: openDrmxFileFromData - unable to load document header"];
		[self createError:[NSString stringWithFormat:@"ERROR: Unable to load document header. (Err:%d)", fh] errorCode:-15 error:ppError];
	}
	return nil;
}

/*
	Opens DB and searches for HCKS of DocID document
 */
//-(bool) getHCKSfromDB: (BYTE*)hcks forDocument: (UINT)dwDocID
//{
	//TO-DO
//	return NO;
//}

/*
	Authorises document (dwDocID) and returns HCKS
	for this document.
	Otherwise returns false.
 */
-(bool) getHCKSfromServer:(BYTE*)hcks forDocument:(UINT)dwDocID andCode:(NSString*) sCode error:(NSError**)ppError
{
	char szID[512];
	
	//get disk ID
	NSString *sService = @"AppleAHCIDiskDriver";
	NSString *sKey = @"Serial Number";
	NSString *sDiskID = [self getVolumeInfo:sService key:sKey];

	//convert it to char* and then to UINT
	[sDiskID getCString:szID maxLength:256 encoding:NSUTF8StringEncoding];
	DWORD dwDiskID = (DWORD)CGlobal::Hash( szID, (DWORD)strlen(szID ) );
	//NSLog( @"DiskID:%@ [%u]", sDiskID, dwDiskID );
	
	//get OS ID
	char szOSID[256];
	CGlobal::GetSerialNumber(szOSID, 256 );
	//NSLog( @"SerialID: %s", szOSID );

	NSString *sOSID = [NSString stringWithUTF8String:szOSID];
	unsigned long dwServerHash = [self authoriseDocument:dwDocID OSID:sOSID DiskID:dwDiskID withCode:sCode get:hcks error:ppError];

	if ( dwServerHash != 0 )
	{
		//call to WS was successful
		//Calculate Hash code
		sprintf( szID, "@%s]%x#%x!%s_", szOSID, dwDiskID, dwDocID, [sCode UTF8String]);
		//CString ss = szID;
		CGlobal::Scramble( szID );
		
		DWORD dwHash = CGlobal::Hash( szID, (DWORD)strlen(szID ) );
		if ( dwServerHash == dwHash )
		{
			return YES;
		}
		else
		{
			//Hashes don't match - authorisation error!
			[self createError:@"Authorisation didn't succeed - hash codes don't match" errorCode:-222 error:ppError];
		}
	}

	return NO;
	//"2jFtAtVADjFnzf7qK3Yg"
}

-(unsigned long) authoriseDocument: (UINT)dwDocID OSID:(NSString*)sOSID DiskID:(UINT)nDiskID withCode:(NSString*)sCode get:(BYTE*)hcks error:(NSError **)ppError
{
	NSString *sTemp = nil;
	
	NSMutableString *sRequest = [[NSMutableString alloc]init];

	//create soap envelope
	[sRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[sRequest appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
	[sRequest appendString:@"<soap:Body>"];
	[sRequest appendString:@"<Auth_O xmlns=\"http://drumlinsecurity.co.uk/\">"];
	
	sTemp = [NSString stringWithFormat:@"<s1>%@</s1>", sOSID ];
	[sRequest appendString:sTemp];
	
	sTemp = [NSString stringWithFormat:@"<dw1>%u</dw1>", nDiskID ];
	[sRequest appendString:sTemp];
	
	sTemp = [NSString stringWithFormat:@"<dw2>%u</dw2>", dwDocID ];
	[sRequest appendString:sTemp];

//	[sRequest appendString:@"<dw2>12780</dw2>"];

	sTemp = [NSString stringWithFormat:@"<sCode>%@</sCode>", sCode ];
	[sRequest appendString:sTemp];

	VarSystemInfo* v = [[VarSystemInfo alloc] init];
	sTemp = [NSString stringWithFormat:@"<sVersion>JM_%@ [%@] %@ SN:%@</sVersion>", [Version version], [v sysOSVersion], [v sysModelID], [v sysSerialNumber]];
	[sRequest appendString:sTemp];
	//[v release];
	
//	[sRequest appendString:@"<sCode>2jFtAtVADjFnzf7qK3Yg</sCode>"];
	[sRequest appendString:@"</Auth_O>"];
	[sRequest appendString:@"</soap:Body>"];
	[sRequest appendString:@"</soap:Envelope>"];
	
	//NSLog(@"%@", sRequest);
	NSURL *myWebserverURL = [NSURL URLWithString:@"http://www.drumlinsecurity.co.uk/Service.asmx"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL]; 
	
	[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"http://drumlinsecurity.co.uk/Auth_O" forHTTPHeaderField:@"SOAPAction"];//this is default tempuri.org, I changed mine in the project
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%ld", (unsigned long)[sRequest length]];
	
	[request addValue:contentLengthStr forHTTPHeaderField:@"Content-Length"];
    // Set the action to Post
    [request setHTTPMethod:@"POST"];
    // Set the body
    [request setHTTPBody:[sRequest dataUsingEncoding:NSUTF8StringEncoding]];
    // Create the connection
//    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//	NSMutableData *myMutableData;
    // Check the connection object
  //  if(conn)
//    {
//		myMutableData=[[NSMutableData data] retain];
//    }
    // Make this class the delegate so that the other connection events fire here.
    //[NSURLConnection connectionWithRequest:request delegate:self];
	
    NSError *WSerror;
    NSURLResponse *WSresponse;
    // Execute the asp.net Service and return the data in an NSMutableData object
    NSData *d = [NSURLConnection sendSynchronousRequest:request returningResponse:&WSresponse error:&WSerror]; 
	
	//convert the mutabledata to an nsstring so I can see it with the debugger
//	NSString *theXml = [[NSString alloc]initWithBytes:[d bytes] length:[d length] encoding:NSUTF8StringEncoding];
//	NSLog( @"%@", theXml );
	
	XmlParser *xmlParser = [[XmlParser alloc] initWithName:@"Auth_OResponse"];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:d];
	[parser setDelegate:xmlParser];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	//[parser release];
	
	if ( xmlParser.result == nil )
	{
		//error while calling the WS
		if (ppError != NULL) 
		{
			[self createError:@"Unable to retrieve data from the server!" errorCode:-200 error:ppError];
		}
		return 0;
	}
	
	NSMutableDictionary *res1 = xmlParser.result;
	
	NSDictionary *res = [self getWSResponse:res1];
	
	//NSLog( @"WS Response: %@", res );
	
	NSString* sHCKS = [res objectForKey:@"Auth_OResult"];
	NSString* sHash = [res objectForKey:@"nHash"];
	if ( sHCKS != nil && sHash != nil )
	{
		//copy HCKS bytes to output buffer
		CBase64::Decode([sHCKS UTF8String], hcks, 16);
		
		//returns HASH calculated on server
		//should be compared with the hash calculated locally
		//do that in caller
		char s[128];
		[sHash getCString:s maxLength:128 encoding:NSASCIIStringEncoding];//NSUTF8StringEncoding];
		unsigned long mul = 1;
		unsigned long nRes = 0;
		for( int k=(int)strlen(s)-1; k>=0; k-- )
		{
			nRes += ((int)(s[k])-48) * mul;
			mul *= 10;
		}
		return nRes;
	}
	
	//there was an error during ws call
	if (ppError != NULL) 
	{
		NSString* sError = [res objectForKey:@"sError"];

		if ( sError == nil ) sError = @"Unable to call Drumlin server!";
		[self createError:sError errorCode:1 error:ppError];
	}
	return 0;
}

-(NSDictionary*) getWSResponse: (NSDictionary*)dict
{
	NSEnumerator *e = [dict keyEnumerator];
	for( NSString* s in e )
	{
		id node = [dict objectForKey: s];
		if ( [node isKindOfClass:[NSDictionary class]] )
		{
			NSDictionary* d = (NSDictionary*)node;
			return [self getWSResponse: d];
		}
		return dict;
	}
	
	return nil;
}

-(NSString*) getVolumeInfo: (NSString*) sServiceName key:(NSString*)sKey
{
	kern_return_t   kr;
	io_iterator_t   io_objects;
	io_service_t    io_service;
	
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault,
									  IOServiceNameMatching([sServiceName UTF8String]),//"AppleAHCIDiskDriver"), 
									  &io_objects);
	
	if(kr != KERN_SUCCESS) return nil;
	
	while((io_service= IOIteratorNext(io_objects)))
	{
		CFMutableDictionaryRef service_properties;
		kr = IORegistryEntryCreateCFProperties(
				   io_service, &service_properties, kCFAllocatorDefault, kNilOptions);
		if(kr == KERN_SUCCESS)
		{
/*			{
				const char*  pText = (const char*)CFDictionaryGetValue (
												   service_properties,
												   (const void *)[sKey UTF8String]
												   );
				int iii=100;
				iii++;
			}*/
			
//			__CFDictionary* dict = (__CFDictionary*)service_properties;

/******
			NSString* ss = [service_properties objectForKey:sKey];
			NSString *sRes = [[NSString alloc] initWithString:ss];
			//[sRes autorelease];
			CFRelease(service_properties);
			IOObjectRelease(io_service);
			IOObjectRelease(io_objects);
			
			return sRes;******/
			
			return @"";
		}
		
		IOObjectRelease(io_service);
	}
	
	IOObjectRelease(io_objects);
	return nil;
}


/*-(void) callWS
{
	NSString* sURL = [NSString stringWithString:@"http://www.drumlinsecurity.co.uk/service.asmx"];
	
	NSURL* url = [NSURL URLWithString:sURL];
	NSURLRequest *urlReq = [NSURLRequest requestWithURL:url
											cachePolicy:NSURLRequestReturnCacheDataElseLoad
										timeoutInterval:30];
	
	NSData* urlData = nil;
	NSURLResponse* response = nil;
	NSError* error = nil;
	
	urlData = [NSURLConnection sendSynchronousRequest:urlReq
									returningResponse:&response
												error:&error];
	
	if ( !urlData )
	{
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	
	UINT nLen = [urlData length];
	char* p = (char*)[urlData bytes];
	
	NSString *sss = [NSString stringWithCString:p encoding:NSASCIIStringEncoding];
	
	NSLog( sss );
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithData:urlData
													 options:0
													   error:&error];
	
	if ( !doc )
	{
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
}*/

-(INT) doOnlineAuthorisation:(PDOCEX_INFO)pDocInfo 
					 getHcks:(BYTE*)pHcks 
				 getAuthCode:(char*)szAuthCode 
					   error:(NSError**)ppError
{
//	char* s = (char*)malloc(64);
//	memset( s, 0, 64 );
		
	//NSString* ss1 = [General stringFromWchar:pDocInfo->szDocName];
	//CUnicodeString::ToChr(pDocInfo->szDocName, s, 64 );
	//NSString *str = [NSString stringWithUTF8String:s];
	//NSString *str = [NSString stringWithCString:(const char*)pDocInfo->szDocName encoding:NSUTF8StringEncoding];
	//NSString *sDoc = [NSString stringWithFormat:@"%@ [DocID:%d]", str, pDocInfo->dwDocID];
	
	
	NSString* str = [General stringFromWchar:pDocInfo->szDocName length:128];
	/*
	////TEST
	const char* p = (const char*)pDocInfo->szDocName;
	NSString *sLog = [NSString stringWithFormat:@"%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x",
		0x000000ff&(p[0]), 0x000000ff&(p[1]), 0x000000ff&(p[2]), 0x000000ff&(p[3]), 0x000000ff&(p[4]),
		0x000000ff&(p[5]), 0x000000ff&(p[6]), 0x000000ff&(p[7]), 0x000000ff&(p[8]), 0x000000ff&(p[9]),
		0x000000ff&(p[10]), 0x000000ff&(p[11]), 0x000000ff&(p[12]), 0x000000ff&(p[13]), 0x000000ff&(p[14]),
		0x000000ff&(p[15]), 0x000000ff&(p[16]), 0x000000ff&(p[17]), 0x000000ff&(p[18]), 0x000000ff&(p[19])
	];
	[[Log getLog] addLine:@"----"];
	//[[Log getLog] addLine:sLog];
	//[[Log getLog] addLine:str];
	[[Log getLog] addLine:@"----"];
	////END_TEST
	*/
	//free( s );

//	[ss1 release];
	
	BOOL bSelfAuth = (pDocInfo->byAdditional[127] == 80);
	
	if ( bSelfAuth == NO )
	{
		//Ask user for auth code
		AuthController* ac = [[AuthController alloc] init];

		[ac setDocInfo:str docID:pDocInfo->dwDocID];
		[ac showAuthPanel1:[NSApp keyWindow]];
		
		if ( [ac isOK] )
		{
			NSString *sCode = [ac getCode];
			if ( sCode != nil )
			{
				//call server and get HCKS
				[[Log getLog] addLine:sCode];
				if (YES == [self getHCKSfromServer:pHcks forDocument:pDocInfo->dwDocID andCode:sCode error:ppError] )
				{
					//SUCCESS!!
					if ( szAuthCode != NULL )
					{
						[sCode getCString:szAuthCode maxLength:32 encoding:NSASCIIStringEncoding];
					}
					//[str release];
					return 0;
				}
			}
		}

		//ERROR - unable to authorise!!
		//user has dismissed the panel
		if ( ppError != NULL && *ppError == nil )
			[self createError:@"Authorisation process terminated by user!" errorCode:-1 error:ppError];
		return -1;
	}
	else
	{
		//eslf-auth document
		[[Log getLog] addLine:@"Self-auth doc"];
		return 0;
	}
}

////////////////////////////////////////
//
//	After header has been loaded and Document info structure populated, this function
//	checks various items (like expiration date) and does the authorisation if necessary.
//
//	Return values:
//		>=0	- OK
//		-1	- expired
//		-2	- too early to open
//		-3	- cannot open anymore (counter is zero)
//		-4	- error while saving counters
//		-5  - error with counters (somebody moaidifed plist file)
//		-6	- corruped pList file
//		-110- expired (after successful authorisation)
//		-113- counters exhausted
//		-114- unable to save counters
//		
////////////////////////////////////////
-(INT) canOpenDocument: (PDOCEX_INFO)pDocInfo withKey: (BYTE*)pKey error:(NSError**)ppError
{
	if ( pDocInfo->dwDocID == 0 ) return 2;//this is the initial document!
	if ( pDocInfo->nAllowedUsers == 2 ) return 2;//no autorisation required
	
	//INT nRes = [DocumentDB setDocument:pDocInfo withHCKS:nil];
	m_documentID = pDocInfo->dwDocID;
	NSString *sCode = nil;
	BOOL	bNewDocument = NO;
	DocumentRecord *docRec = nil;
	//try to read document record from the DB
	@try
	{
		[[Log getLog] addLine:@"DBG: canOpenDocument - "];
		//NSKeyUnarchiver can raise exception - be ready!
		docRec = [DocumentDB getDocument:pDocInfo->dwDocID];
	}
	@catch( NSException *ex)
	{
		//probably - corrupted plist!
		if ( ppError != NULL )
		{
			[[Log getLog] addLine:@"DBG: canOpenDocument - Corrupted document counters"];
			[self createError:@"Corrupted document counters!" errorCode:-6 error:ppError];
		}
		[[Log getLog] addLine:[ex description]];
		return -6;
	}
	
	unsigned int y,m,d;
	
	if ( docRec == nil )
	{
		[[Log getLog] addLine:@"DBG: canOpenDocument - Doc needs to be authorised"];
		[[Log getLog] addLine:[NSString stringWithFormat:@"DocID: %u", pDocInfo->dwDocID]];
		
		CGlobal::GetDate( pDocInfo->dwPubDate, &y, &m, &d );
		[[Log getLog] addLine:[NSString stringWithFormat:@"Pub.date: %x [%04d-%02d-%02d]", pDocInfo->dwPubDate, y, m, d]];
		
		CGlobal::GetDate( pDocInfo->dwUploadDate, &y, &m, &d );
		[[Log getLog] addLine:[NSString stringWithFormat:@"Upload date: %x [%04d-%02d-%02d]", pDocInfo->dwUploadDate, y, m, d]];
		
		[[Log getLog] addLine:[NSString stringWithFormat:@"OwnerID: %u", pDocInfo->dwOwnerID]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"CreatorID: %u", pDocInfo->dwCreatorID]];
		
		CGlobal::GetDate( pDocInfo->dwExpires, &y, &m, &d );
		[[Log getLog] addLine:[NSString stringWithFormat:@"Expires: %x [%04d-%02d-%02d]", pDocInfo->dwExpires, y, m, d]];
		
		CGlobal::GetDate( pDocInfo->dwStartDate, &y, &m, &d );
		[[Log getLog] addLine:[NSString stringWithFormat:@"Start Date: %x [%04d-%02d-%02d]", pDocInfo->dwStartDate, y, m, d]];
		
		CGlobal::GetDate( pDocInfo->dwExpiryDate, &y, &m, &d );
		[[Log getLog] addLine:[NSString stringWithFormat:@"Expiry Date: %x [%04d-%02d-%02d]", pDocInfo->dwExpiryDate, y, m, d]];
		
		[[Log getLog] addLine:[NSString stringWithFormat:@"Opening#: %u", pDocInfo->dwOpeningCount]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"Printing#: %u", pDocInfo->dwPrintingCount]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"Pages#: %u", pDocInfo->dwPagesToPrint]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"Expires after: %d", pDocInfo->nExpiresAfter]];
		[[Log getLog] addLine:[NSString stringWithFormat:@"time_t size: %ld", sizeof(time_t)]];
		
		//document needs to be authorised, i.e. document record not in DB
		bNewDocument = YES;
		
		//first check if doc can be authorised at all because of the expiration date
		DWORD dwExpiry = 0xffffffff;
		
		if ( pDocInfo->nExpiresAfter == -1 )
		{
			dwExpiry = pDocInfo->dwExpiryDate;
		}
		else
		{
			//"expires after" is set
			//calculate expiry date from today + "expires after"
			DWORD dw = CGlobal::GetCurrentDate();
			dwExpiry = CGlobal::AddDays(dw, pDocInfo->nExpiresAfter);
			
			CGlobal::GetDate( dwExpiry, &y, &m, &d );
			NSString *s = [[NSString alloc] initWithFormat:@"DBG: canOpenDocument - Doc expires on: %04d-%02d-%02d [0x%x]\r\n", y, m, d, dwExpiry ];
			[[Log getLog] addLine:s];
			
			//NSLog( @"%@", s );
			pDocInfo->nExpiresAfter = -1;//don't need it anymore - calculated above
			pDocInfo->dwExpiryDate = dwExpiry;
			pDocInfo->dwExpires = dwExpiry;
		}
		
		//check expiry date
		if ( dwExpiry != 0xffffffff && CGlobal::IsAfter( dwExpiry ) )
		{
			if ( ppError != NULL )
			{
				CGlobal::GetDate( dwExpiry, &y, &m, &d );
				NSString *s = [[NSString alloc] initWithFormat:@"ERROR:Document expired on:  %04d-%02d-%02d [0x%x]\r\n", y, m, d, dwExpiry];
				
				[self createError:s errorCode:-1 error:ppError];
			}
			NSString *s = [[NSString alloc] initWithFormat:@"DBG: canOpenDocument - Doc expired on: %04d-%02d-%02d [0x%x]", y, m, d, dwExpiry ];
			[[Log getLog] addLine:s];
			//Document has expired - unable to authorise!
			return -1;//expired
		}

		if ( pDocInfo->dwStartDate != 0xffffffff && CGlobal::IsBefore( pDocInfo->dwStartDate ) )
		{
			if ( ppError != NULL )
			{

				CGlobal::GetDate( pDocInfo->dwStartDate, &y, &m, &d );
				NSString *s = [[NSString alloc] initWithFormat:@"ERROR:Unable to authorise before: %04d-%02d-%02d\r\n", y, m, d];
				
				[self createError:s errorCode:-2 error:ppError];
			}
			
			[[Log getLog] addLine:@"DBG: canOpenDocument - Too early to open"];
			return -2;//too early to open
		}

		if ( pDocInfo->nAllowedUsers == 1 )
		{
			//off-line authorisation
			//To-do!!!
			
			return 0;
		}
		else
		{
			//on-line authorisation
			char szAuthCode[32];
			[[Log getLog] addLine:@"DBG: canOpenDocument - About to do online authorisation"];
			if ( pDocInfo->byAdditional[127] == 80 )
			{
				strcpy( szAuthCode, "self_auth");
			}
			INT nRes = [self doOnlineAuthorisation:pDocInfo getHcks:pKey getAuthCode:szAuthCode error:ppError];
			if ( nRes < 0 )
			{
				[[Log getLog] addLine:[NSString stringWithFormat:@"DBG: canOpenDocument - Auth error: %d", nRes]];
				return nRes;//error during authorisation
			}
			
			docRec = [[DocumentRecord alloc] init];
			//[docRec retain];
			sCode = [NSString stringWithCString:szAuthCode encoding:NSASCIIStringEncoding];
			[docRec initWithDocExInfo:pDocInfo hcks:pKey andAuthCode:sCode];
		}
	}
	else
	{
		[[Log getLog] addLine:@"DBG: canOpenDocument - Doc already authorised. Checking hash code."];
		//docRec already exists in the plist
		//must check its hash code to verify if somebody has modified it
		DWORD hashSaved = [docRec hashCode];
		DWORD hashCalc  = [DocumentDB calcHashWithHwID:docRec];
		if ( hashSaved != hashCalc )
		{
			//try once again with old style hash calculation
			hashCalc = [DocumentDB calcHash:docRec];
			if ( hashSaved != hashCalc )
			{
				if ( ppError != NULL )
				{
					[self createError:@"Corrupted counters!" errorCode:-5 error:ppError];
				}
				[[Log getLog] addLine:@"DBG: canOpenDocument - Wrong counters in documentDB"];
				return -5;
			}
		}
	}

	//Document IS authorised!
	//Check counters.
	DWORD dwExpiry = 0xffffffff;
	
	//NSLog( @"AuthCode:%@", [docRec authCode] );
	dwExpiry = [docRec expires];
	CGlobal::GetDate( dwExpiry, &y, &m, &d );
	NSString *s1 = [[NSString alloc] initWithFormat:@"DBG:Document in DB expires on: %04d-%02d-%02d [0x%x]", y, m, d, dwExpiry];
	[[Log getLog] addLine:s1];
	
	//check expiry date
	if ( dwExpiry != 0xffffffff && CGlobal::IsAfter( dwExpiry ) )
	{
		NSString *s = [[NSString alloc] initWithFormat:@"ERROR:Document in DB expired on %04d-%02d-%02d [0x%x]\r\n", y, m, d, dwExpiry];

		if ( ppError != NULL )
			[self createError:s errorCode:-110 error:ppError];
		
		[[Log getLog] addLine:s];
		//[docRec release];
		return -110;//expired
	}
	
	//handle opening counter
	INT openCount = [docRec openCount];
	if ( openCount != 0xffffffff )
	{
		openCount --;
		if ( openCount < 0 )
		{
			if ( ppError != NULL )
			{
				[self createError:@"ERROR: Unable to open anymore!" errorCode:-113 error:ppError];
			}
			[[Log getLog] addLine:@"DBG: canOpenDocument - Doc open count exceeded"];
			//[docRec release];
			return -113;//cannot open anymore!
		}
	}
	
	//copy HCKS for the caller
	BYTE* hcks = [docRec byteHcks];
	if ( pKey != nil )
		for( int i=0; i<16; i++ ) pKey[i] = hcks[i];
	
	//save updated counters
	pDocInfo->dwOpeningCount = openCount;
	INT nRes = 0;
	
	if ( bNewDocument == NO )
	{
		//save previous printing counters
		[docRec setOpenCount:openCount];
		[DocumentDB saveDocRec:docRec];
	}
	else
	{
		//new document
		nRes = [DocumentDB setDocument:pDocInfo withHCKS:hcks andAuthCode:sCode];
	}

	if ( nRes == 0 )
	{
		if ( [docRec authCode] != nil )
			m_sAuthCode = [[NSString alloc] initWithString:[docRec authCode]];
		//[docRec release];
		return 10;//OK with HCKS
	}
	else
	{
		if ( ppError != NULL )
		{
			[self createError:@"ERROR: Unable to save counters!" errorCode:-114 error:ppError];
		}
		
		[[Log getLog] addLine:@"DBG: canOpenDocument - Unable to save counters"];
		//[docRec release];
		return -114;//ERROR while saving counters
	}
}

- (void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError
{
	if (ppError != NULL) 
	{
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:sText forKey:NSLocalizedDescriptionKey];
		*ppError = [NSError errorWithDomain:@"Javelin" code:nErrorCode userInfo:errorDetail];
	}
}

- (NSString*)getAuthCode
{
	return m_sAuthCode;
}
/*
- (NSString*) getMACAddress: (BOOL)stripColons
{
    NSMutableString			*macAddress		= nil;
    NSArray					*allInterfaces	= (NSArray*)SCNetworkInterfaceCopyAll();
    NSEnumerator			*interfaceWalker= [allInterfaces objectEnumerator];
    SCNetworkInterfaceRef	curInterface	= nil;
	
    while ( curInterface = (SCNetworkInterfaceRef)[interfaceWalker nextObject] )
    {
        if ( [(NSString*)SCNetworkInterfaceGetBSDName(curInterface) isEqualToString: LocalString(@"kEthernetBSDName")] )
        {
			macAddress = [(NSString*)SCNetworkInterfaceGetHardwareAddressString(curInterface) mutableCopy];
			
			if ( stripColons == YES )
			{
				[macAddress replaceOccurrencesOfString: @":" withString: @"" options: NSLiteralSearch range: NSMakeRange(0, [macAddress length])];
			}
			
			break;
        }
    }
	
    return [[macAddress copy] autorelease];
}
*/
@end
