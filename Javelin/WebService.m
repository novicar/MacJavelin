//
//  WebService.m
//  Javelin
//
//  Created by harry on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WebService.h"
#import "XmlParser.h"


@implementation WebService

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
+(id)callRestService: (NSString *) methodName : (NSDictionary *) params
{
	NSURL *url=[WebService getRestUrl: methodName : params];
	XmlParser *xmlParser = [[XmlParser alloc] init];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:xmlParser];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	//[parser release];
	return xmlParser.result;
}

+(NSURL *)getRestUrl: (NSString *) methodName : (NSDictionary *) params
{
	NSString *url=@"http://www.drumlinsecurity.co.uk/Service.asmx/";
	url=[url stringByAppendingString:methodName];
	
	BOOL firstKey=TRUE;
	for (NSString *key in params)
	{
		NSString *value=[params objectForKey:key];
		if (firstKey) url=[url stringByAppendingString:@"?"]; else url=[url stringByAppendingString:@"&"];
		url=[url stringByAppendingString:key];
		url=[url stringByAppendingString:@"="];
		url=[url stringByAppendingString:value];
		firstKey=FALSE;
	}
	return [NSURL URLWithString:url];
}
@end
