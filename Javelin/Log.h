//
//  Log.h
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Log : NSObject {
@private
	NSMutableArray* parray;
	NSDateFormatter* formatter;
}

+ (id)getLog;
+ (id)hiddenAlloc;
- (void)addLine:(NSString*)sText;
- (void)writeToLogFile:(NSString*)sFile;
@end
