//
//  VersionChecker.h
//  Javelin3
//
//  Created by Novica Radonic on 01.04.2021..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VersionChecker : NSObject
{
}

+(NSString*)getLatestVersion:(int*)pMaj minor:(int*)pMin rev:(int*)pRev error:(NSError**)ppError;
+(NSDictionary*) getWSResponse: (NSDictionary*)dict;
+(void) createError:(NSString*)sText errorCode:(int)nErrorCode error:(NSError**)ppError;
+(BOOL)checkLatestVersion:(int*)pMaj minor:(int*)pMin rev:(int*)pRev error:(NSError**)ppError;
@end

NS_ASSUME_NONNULL_END
