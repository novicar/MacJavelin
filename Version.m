//
//  Version.m
//  Javelin
//
//  Created by harry on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Version.h"

//#define JAVELIN_VERSION		@"3.05.02"

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
	//return JAVELIN_VERSION;
	NSString* s = [NSString stringWithFormat:@"%d.%02d.%02d", MAJOR_VER, MINOR_VER, REVISION];
	return s;
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

//return YES if server version is newer
+ (BOOL)isServerVersionNewer:(int)nServerMaj serverMin:(int)nServerMin serverRev:(int)nServerRev
{
	if ( nServerMaj > MAJOR_VER )
		return YES;
	
	if ( nServerMin > MINOR_VER )
		return YES;
	
	if ( nServerRev > REVISION )
		return YES;
	
	return NO;
}

+ (NSString*)getAppNameAndVersion
{
	return [NSString stringWithFormat:@"%@3 v%@", APP_NAME, [self version]];
}
@end
