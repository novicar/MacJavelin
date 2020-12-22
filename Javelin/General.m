//
//  General.m
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "General.h"

@implementation General

static CatalogStack* g_catalogStack = nil;
static DocumentList* g_documentList = nil;

+ (DocumentList*)documentList
{
	if ( g_documentList == nil )
		g_documentList = [[DocumentList alloc] init];
	
	return g_documentList;
}

+ (CatalogStack*)catalogStack
{
	if ( g_catalogStack == nil )
		g_catalogStack = [[CatalogStack alloc] init];
	
	return g_catalogStack;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
/*
- (void)dealloc
{
    [super dealloc];
}
*/
+ (void) convertUnicode:(const unsigned char*)sUni toChar:(char*)sChar maxLen:(int)nMaxLen;
{
	//BOOL bFirstZero = NO;
	
	for( int i=0, j=0; i<nMaxLen*2 && j<nMaxLen; i+=2, j++ )
	{
/*		if ( sUni[i] == '\x0' )
		{
			if ( bFirstZero == NO )
				bFirstZero = YES;
			else
				break;
		}
		else bFirstZero = NO;*/
		
		if ( sUni[i] == '\x0' && sUni[i+1] == '\x0' )
		{
			sChar[j] = '\x0';
			break;
		}
		
		sChar[j] = sUni[i];
		sChar[j+1] = '\x0';
	}

}

+(int)getWcharLenInBytes:(const char*)charText length:(int)nLen
{
	for( int i=0; i<nLen; i++ )
	{
		if (charText[i] == '\x0' && charText[i+1] == '\x0')
		{
			return i;
		}
	}
	
	return nLen;
}

+(NSString *)stringFromWchar:(const wchar_t *)charText length:(int)nLen
{
    //used ARC
	//size_t len = wcslen(charText);
	//len *= 2;
	int len = [General getWcharLenInBytes:(const char*)charText length:nLen];
	len += 2;//double zero at the end
	//wcslen(charText)*sizeof(*charText)
	
    return [[NSString alloc] initWithBytes:charText length:len encoding:NSUTF16LittleEndianStringEncoding];
	//NSUTF32LittleEndianStringEncoding];
}

+ (void)displayAlert:(NSString*)sTitle message:(NSString*)sMessage
{
	NSAlert *theAlert = [NSAlert alertWithMessageText:sTitle 
										defaultButton:nil 
									  alternateButton:nil 
										  otherButton:nil 
							informativeTextWithFormat:@"%@", sMessage];
	[theAlert setAlertStyle:NSAlertStyleWarning];
	[theAlert runModal];
}

+ (NSString *)getID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert)
        return nil;

    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    if (!serialNumberAsCFString)
        return nil;

    IOObjectRelease(platformExpert);
    return (__bridge NSString *)(serialNumberAsCFString);;
}

+(NSString*)convertDomainError:(long)nError
{
	switch(nError)
	{
	case NSURLErrorUnknown:// = -1,
		return @"Unknown error";
		break;
	case 	NSURLErrorCancelled:// = -999,
		return @"Cancelled";
		break;
	case 	NSURLErrorBadURL:// = -1000,
		return @"Bad URL";
		break;
	case 	NSURLErrorTimedOut:// = -1001,
		return @"Timed out";
		break;
	case 	NSURLErrorUnsupportedURL:// = -1002,
		return @"Unsupported URL";
		break;
	case 	NSURLErrorCannotFindHost:// = -1003,
		return @"Cannot find host";
		break;
	case 	NSURLErrorCannotConnectToHost:// = -1004,
		return @"Cannot connect to host";
		break;
	case 	NSURLErrorDataLengthExceedsMaximum:// = -1103,
		return @"Data Length Exceeds Maximum";
		break;
	case 	NSURLErrorNetworkConnectionLost:// = -1005,
		return @"Network Connection Lost";
		break;
	case 	NSURLErrorDNSLookupFailed:// = -1006,
		return @"DNS Lookup Failed";
		break;
	case 	NSURLErrorHTTPTooManyRedirects:// = -1007,
		return @"HTTP: Too many redirects";
		break;
	case 	NSURLErrorResourceUnavailable:// = -1008,
		return @"Resource Unavailable";
		break;
	case 	NSURLErrorNotConnectedToInternet:// = -1009,
		return @"Not Connected to Internet";
		break;
	case 	NSURLErrorRedirectToNonExistentLocation:// = -1010,
		return @"Redirect to Non-existent Location";
		break;
	case 	NSURLErrorBadServerResponse:// = -1011,
		return @"Bad Server Response";
		break;
	case 	NSURLErrorUserCancelledAuthentication:// = -1012,
		return @"User Cancelled Authentication";
		break;
	case 	NSURLErrorUserAuthenticationRequired:// = -1013,
		return @"User Authentication Required";
		break;
	case 	NSURLErrorZeroByteResource:// = -1014,
		return @"Zero Byte Resource";
		break;
	case 	NSURLErrorCannotDecodeRawData:// = -1015,
		return @"Cannot Decode Raw Data";
		break;
	case 	NSURLErrorCannotDecodeContentData:// = -1016,
		return @"Cannot Decode Content Data";
		break;
	case 	NSURLErrorCannotParseResponse:// = -1017,
		return @"Cannot Parse Response";
		break;
	case 	NSURLErrorInternationalRoamingOff:// = -1018,
		return @"International Roaming Off";
		break;
	case 	NSURLErrorCallIsActive:// = -1019,
		return @"Call Is Active";
		break;
	case 	NSURLErrorDataNotAllowed:// = -1020,
		return @"Data Not Allowed";
		break;
	case 	NSURLErrorRequestBodyStreamExhausted:// = -1021,
		return @"Request Body Stream Exhausted";
		break;
	case 	NSURLErrorFileDoesNotExist:// = -1100,
		return @"File Does Not Exist";
		break;
	case 	NSURLErrorFileIsDirectory:// = -1101,
		return @"File is Directory";
		break;
	case 	NSURLErrorNoPermissionsToReadFile:// = -1102,
		return @"No Permissions To Read File";
		break;
	case 	NSURLErrorSecureConnectionFailed:// = -1200,
		return @"Secure Connection Failed";
		break;
	case 	NSURLErrorServerCertificateHasBadDate:// = -1201,
		return @"Server Certificate Has Bad Date";
		break;
	case 	NSURLErrorServerCertificateUntrusted:// = -1202,
		return @"Server Certificate Untrusted";
		break;
	case 	NSURLErrorServerCertificateHasUnknownRoot:// = -1203,
		return @"Server Certificate Has Unknown Root";
		break;
	case 	NSURLErrorServerCertificateNotYetValid:// = -1204,
		return @"Server Certificate Not Yet Valid";
		break;
	case 	NSURLErrorClientCertificateRejected:// = -1205,
		return @"Client Certificate Rejected";
		break;
	case 	NSURLErrorClientCertificateRequired:// = -1206,
		return @"Client Certificate Required";
		break;
	case 	NSURLErrorCannotLoadFromNetwork:// = -2000,
		return @"Cannot Load From Network";
		break;
	case 	NSURLErrorCannotCreateFile:// = -3000,
		return @"Cannot Create File";
		break;
	case 	NSURLErrorCannotOpenFile:// = -3001,
		return @"Cannot Open File";
		break;
	case 	NSURLErrorCannotCloseFile://= -3002,
		return @"Cannot Close File";
		break;
	case 	NSURLErrorCannotWriteToFile:// = -3003,
		return @"Cannot Write To File";
		break;
	case 	NSURLErrorCannotRemoveFile:// = -3004,
		return @"Cannot Remove File";
		break;
	case 	NSURLErrorCannotMoveFile:// = -3005,
		return @"Cannot Move File";
		break;
	case 	NSURLErrorDownloadDecodingFailedMidStream:// = -3006,
		return @"Download Decoding Failed MidStream";
		break;
	case 	NSURLErrorDownloadDecodingFailedToComplete:// = -3007
		return @"Download Decoding Failed To Complete";
		break;
	default:
		return @"Unknown Error";
	}
}

+ (NSURL*)applicationDataDirectory
{
	NSFileManager* sharedFM = [NSFileManager defaultManager];
	NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
								 inDomains:NSUserDomainMask];
	NSURL* appSupportDir = nil;
	NSURL* appDirectory = nil;

	if ([possibleURLs count] >= 1)
	{
		// Use the first directory (if multiple are returned)
		appSupportDir = [possibleURLs objectAtIndex:0];
	}

	// If a valid app support directory exists, add the
	// app's bundle ID to it to specify the final directory.
	if (appSupportDir)
	{
		NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
		appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
	}

	return appDirectory;
}

+ (NSString*)catalogDirectory
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSURL* urlAppSupport = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	NSString* sCatalogPath = [[urlAppSupport path] stringByAppendingPathComponent:@"/Catalogs"];
	
	return sCatalogPath;
}

@end
