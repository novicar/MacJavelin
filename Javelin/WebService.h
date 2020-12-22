//
//  WebService.h
//  Javelin
//
//  Created by harry on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WebService : NSObject {
@private
    
}

+(id)callRestService: (NSString *) methodName : (NSDictionary *) params;
+(NSURL *)getRestUrl: (NSString *) methodName : (NSDictionary *) params;
@end
