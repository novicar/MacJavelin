//
//  Version.m
//  Javelin
//
//  Created by harry on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Version.h"

#define JAVELIN_VERSION		@"3.05.02"
#define DATE_BUILT			@"2020-12-23"
#define APP_NAME			@"Javelin"
#define COMPANY				@"Drumlin Security Ltd."
#define COMPANY_URL			@"http://www.drumlinsecurity.co.uk"


@implementation Version

- (id)init
{
    self = [super init];
    if (self) 
	{

    }
    
    return self;
}
/*
- (void)dealloc
{
    [super dealloc];
}
*/

+ (NSString*)version
{
	return JAVELIN_VERSION;
}

+ (NSString*)date
{
	return DATE_BUILT;
}

+ (NSString*)appName
{
	return APP_NAME;
}

+ (NSString*)company
{
	return COMPANY;
}

+ (NSString*)companyURL
{
	return COMPANY_URL;
}
@end
