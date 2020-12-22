//
//  Log.m
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Log.h"

@implementation Log

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		parray = nil;
    }
    
    return self;
}

- (id)alloc
{
	return nil;//SINGLETON - unable to inialise!
}

+ (id)hiddenAlloc
{
	return [super alloc];
}

+ (id) new
{
	return [self alloc];
}
/*
- (void)dealloc
{
	[parray release];
    [super dealloc];
}
*/

+ (id)getLog {
    static Log *sharedLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLog = [[self alloc] init];
    });
    return sharedLog;
}
/*
+ (id)getLog
{
	static Log *myInstance = nil;
	
	if ( myInstance == nil )
	{
		NSBundle *myBundle = [NSBundle mainBundle];
		NSDictionary *info = [myBundle infoDictionary];
		NSString *className = [info objectForKey:@"LogClass"];
		Class *myClass = (Class*)NSClassFromString(className);
		
		if ( !myClass )
		{
			myClass = (Class*)self;
		}
		
		myInstance = [[myClass hiddenAlloc] init];
	}
	
	return myInstance;
}
*/
- (void)addLine:(NSString*)sText
{
	if ( parray == nil )
	{
		parray = [[NSMutableArray alloc] init];
		formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeStyle:NSDateFormatterMediumStyle];
		[formatter setDateStyle:NSDateFormatterShortStyle];
	}
	
	NSDate *now = [NSDate date];

	[parray addObject:[NSString stringWithFormat:@"%@: %@", [formatter stringFromDate:now], sText]];
}

- (void)writeToLogFile:(NSString*)sFile
{
	FILE *fp;
	
	fp = fopen([sFile UTF8String], "w");
	if ( fp != NULL )
	{
		for( int i=0; i<[parray count]; i++ )
		{
			//NSLog( @"%@", [parray objectAtIndex:i] );
			//fwrite( [[parray objectAtIndex:i] UTF8String], 
			fprintf( fp, "%s\n", [[parray objectAtIndex:i] UTF8String] );
		}
		
		fclose( fp );
	}
}
@end
