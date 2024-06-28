//
//  General.h
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CatalogStack.h"
#import "DocumentList.h"

@interface General : NSObject {
@private
    
}

+ (void) convertUnicode:(const unsigned char*)sUni toChar:(char*)sChar maxLen:(int)nMaxLen;
+ (void) displayAlert:(NSString*)sTitle message:(NSString*)sMessage;
+ (NSString *) stringFromWchar:(const wchar_t *)charText length:(int)nLen;
+ (int) getWcharLenInBytes:(const char*)charText length:(int)nLen;
+ (NSString *)getID;
+ (NSString *)convertDomainError:(long)nError;
+ (NSURL*)applicationDataDirectory;
+ (NSString*)catalogDirectory;
+ (CatalogStack*)catalogStack;
+ (CatalogStack*)catalogStackNames;
+ (DocumentList*)documentList;

+ (NSString*)getUserValue:(NSString*)sKey;
+ (void)setUserValue:(NSString*)sValue key:(NSString*)sKey;
@end
