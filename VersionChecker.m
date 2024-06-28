//
//  VersionChecker.m
//  Javelin3
//
//  Created by Novica Radonic on 01.04.2021..
//

#import "VersionChecker.h"
#import "XmlParser.h"
#import "Version.h"

@implementation VersionChecker

+(void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError
{
	if (ppError != NULL) 
	{
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:sText forKey:NSLocalizedDescriptionKey];
		*ppError = [NSError errorWithDomain:@"Javelin" code:nErrorCode userInfo:errorDetail];
	}
}

+(NSDictionary*) getWSResponse: (NSDictionary*)dict
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

//2021-04-01
//returns YES if there is a newer version on the server
+(BOOL)checkLatestVersion:(int*)pMaj minor:(int*)pMin rev:(int*)pRev error:(NSError**)ppError
{
	NSString* sVer = [VersionChecker getLatestVersion:pMaj minor:pMin rev:pRev error:ppError];
	
	if ( sVer != nil )
	{
		BOOL bNewVersion = [Version isServerVersionNewer:*pMaj serverMin:*pMin serverRev:*pRev];
		
		return bNewVersion;
	}
	return NO;
}

+(NSString*)getLatestVersion:(int*)pMaj minor:(int*)pMin rev:(int*)pRev error:(NSError**)ppError
{
	NSString *sTemp = nil;
	*pMaj = 0; *pMin=0; *pRev=0;
	
	NSMutableString *sRequest = [[NSMutableString alloc]init];

	//create soap envelope
	[sRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[sRequest appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
	[sRequest appendString:@"<soap:Body>"];
	[sRequest appendString:@"<GetLatestVersion xmlns=\"http://drumlinsecurity.co.uk/\">"];
	
	[sRequest appendString:@"<sAppID>JM3</sAppID>"];
	
	[sRequest appendString:@"</GetLatestVersion>"];
	[sRequest appendString:@"</soap:Body>"];
	[sRequest appendString:@"</soap:Envelope>"];
	
	NSURL *myWebserverURL = [NSURL URLWithString:@"http://www.drumlinsecurity.co.uk/Service.asmx"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL]; 
	
	[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request addValue:@"http://drumlinsecurity.co.uk/GetLatestVersion" forHTTPHeaderField:@"SOAPAction"];
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%ld", (unsigned long)[sRequest length]];
	
	[request addValue:contentLengthStr forHTTPHeaderField:@"Content-Length"];
	// Set the action to Post
	[request setHTTPMethod:@"POST"];
	// Set the body
	[request setHTTPBody:[sRequest dataUsingEncoding:NSUTF8StringEncoding]];

	NSError *WSerror;
	NSURLResponse *WSresponse;
	// Execute the asp.net Service and return the data in an NSMutableData object
	NSData *d = [NSURLConnection sendSynchronousRequest:request returningResponse:&WSresponse error:&WSerror]; 
	
	//convert the mutabledata to an nsstring so I can see it with the debugger
	//NSString *theXml = [[NSString alloc]initWithBytes:[d bytes] length:[d length] encoding:NSUTF8StringEncoding];
	//NSLog( @"%@", theXml );
	
	XmlParser *xmlParser = [[XmlParser alloc] initWithName:@"GetLatestVersionResponse"];
	
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
		return nil;
	}
	
	NSMutableDictionary *res1 = xmlParser.result;
	
	NSDictionary *res = [self getWSResponse:res1];
	
	//NSLog( @"WS Response: %@", res );
	
	NSString* sMajor = [res objectForKey:@"Major"];
	NSString* sMinor = [res objectForKey:@"Minor"];
	NSString* sRev = [res objectForKey:@"Revision"];
	
	if ( sMajor != nil && sMinor != nil && sRev != nil )
	{
		*pMaj = [sMajor intValue];
		*pMin = [sMinor intValue];
		*pRev = [sRev intValue];
		
		NSString* s = [NSString stringWithFormat:@"%d.%02d.%02d", *pMaj, *pMin, *pRev];
		return s;
	}
	
	//there was an error during ws call
	if (ppError != NULL) 
	{
		NSString* sError = [res objectForKey:@"sError"];

		if ( sError == nil ) sError = @"Unable to call Drumlin server!";
		[self createError:sError errorCode:1 error:ppError];
	}
	return nil;//some error occured
}

@end
