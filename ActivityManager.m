//
//  ActivityManager.m
//  Javelin3
//
//  Created by Novica Radonic on 12.03.2024..
//
#import "XmlParser.h"
#import "ActivityManager.h"
#import "Version.h"

@implementation ActivityManager

+(NSString*)timeNow
{
	NSDate *currDate = [NSDate date];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"YYYY-MM-dd\'T\'HH:mm:ssZZZZZ"];
	return [dateFormat stringFromDate:currDate];
}

/* <soap:Body>
 <AddActivityEx xmlns="http://drumlinsecurity.co.uk/">
   <dt>dateTime</dt>
   <nUserID>int</nUserID>
   <nProUserID>int</nProUserID>
   <nOrgID>int</nOrgID>
   <nDocID>int</nDocID>
   <nActivityID>int</nActivityID>
   <sDesc>string</sDesc>
   <sText>string</sText>
   <sVersion>string</sVersion>
 </AddActivityEx>
</soap:Body>*/
+(NSString*)addActivityWithDocID:(int)nDocID activityID:(int)nActivityID description:(NSString*)sDesc text:(NSString*)sText error:(NSError**)ppError
{
	//NSString *sTemp = nil;
	
	NSMutableString *sRequest = [[NSMutableString alloc]init];
	NSString* sTime = [ActivityManager timeNow];
	
	//create soap envelope
	[sRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
	[sRequest appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
	[sRequest appendString:@"<soap:Body>"];
	[sRequest appendString:@"<AddActivityEx xmlns=\"http://drumlinsecurity.co.uk/\">"];
	
	[sRequest appendString:[NSString stringWithFormat:@"<dt>%@</dt>", [ActivityManager timeNow]]];
	[sRequest appendString:@"<nUserID>-1</nUserID>"];
	[sRequest appendString:@"<nProUserID>-1</nProUserID>"];
	[sRequest appendString:@"<nOrgID>-1</nOrgID>"];
	[sRequest appendString:[NSString stringWithFormat:@"<nDocID>%d</nDocID>", nDocID]];
	[sRequest appendString:[NSString stringWithFormat:@"<nActivityID>%d</nActivityID>", nActivityID]];
	[sRequest appendString:[NSString stringWithFormat:@"<sDesc>%@</sDesc>", sDesc]];
	[sRequest appendString:[NSString stringWithFormat:@"<sText>%@</sText>", sText]];
	[sRequest appendString:[NSString stringWithFormat:@"<sVersion>JM %@</sVersion>", [Version version]]];
	
	[sRequest appendString:@"</AddActivityEx>"];
	[sRequest appendString:@"</soap:Body>"];
	[sRequest appendString:@"</soap:Envelope>"];
	
	NSURL *myWebserverURL = [NSURL URLWithString:@"http://www.drumlinsecurity.co.uk/Service.asmx"];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL]; 
	
	[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request addValue:@"http://drumlinsecurity.co.uk/AddActivityEx" forHTTPHeaderField:@"SOAPAction"];
	
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
	
	XmlParser *xmlParser = [[XmlParser alloc] initWithName:@"AddActivityExResponse"];
	
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
	
	NSString* sResult = [res objectForKey:@"AddActivityExResult"];
	NSString* sError = [res objectForKey:@"sError"];
	
	if ( sResult != nil && sError != nil )
	{
		return @"OK";
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

+(void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError
{	if (ppError != NULL) 
	{
	   NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
	   [errorDetail setValue:sText forKey:NSLocalizedDescriptionKey];
	   *ppError = [NSError errorWithDomain:@"Javelin" code:nErrorCode userInfo:errorDetail];
   }
}

@end
