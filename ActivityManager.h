//
//  ActivityManager.h
//  Javelin3
//
//  Created by Novica Radonic on 12.03.2024..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ActivityManager : NSObject
{}

+(NSString*)addActivityWithDocID:(int)nDocID activityID:(int)nActivityID description:(NSString*)sDesc text:(NSString*)sText error:(NSError**)ppError;
+(NSDictionary*) getWSResponse: (NSDictionary*)dict;
+(void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError;
+(NSString*)timeNow;
@end



NS_ASSUME_NONNULL_END
