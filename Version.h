//
//  Version.h
//  Javelin
//
//  Created by harry on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Version : NSObject {
@private
}

+ (NSString*)version;
+ (NSString*)date;
+ (NSString*)appName;
+ (NSString*)company;
+ (NSString*)companyURL;
@end
