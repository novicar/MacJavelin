//
//  Version.h
//  Javelin
//
//  Created by harry on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#define MAJOR_VER			3
#define MINOR_VER			5
#define REVISION			30
#define APP_NAME			@"Javelin"
#define DATE_BUILT			@"2024-07-01"
#define COMPANY				@"Drumlin Security Ltd."
#define COMPANY_URL			@"https://www.drumlinsecurity.co.uk"


@interface Version : NSObject {
@private
}

+ (NSString*)version;
+ (NSString*)date;
+ (NSString*)appName;
+ (NSString*)company;
+ (NSString*)companyURL;
+ (BOOL)isServerVersionNewer:(int)nServerMaj serverMin:(int)nServerMin serverRev:(int)nServerRev;
+ (NSString*)getAppNameAndVersion;
@end
