//
//  ScannerThread.m
//  Javelin3
//
//  Created by Novica Radonic on 21/03/2018.
//

#import "ScannerThread.h"
@implementation ThreadArgs
@synthesize IntValue = m_nIntValue;
@synthesize Run = m_bRun;
@synthesize BadProcessName = m_bBadProcessRunning;

@end

#pragma mark --ScannerThread

@implementation ScannerThread
-(void)startThread:(ThreadArgs*)args
{
	m_processNames = 
		[NSArray arrayWithObjects:@"com.apple.terminal",@"screengrab",@"grab",@"droplr",@"snip", @"snap", @"capture", @"shot", @"recordit", @"dropshare", @"xnapper", @"gifox", @"capto", @"movavi", @"skitch", @"snagit", @"cloudapp", @"setapp", @"gimp", nil];
	m_args = args;
	[m_args setRun:YES];
	
	[NSThread detachNewThreadSelector:@selector(entryPoint) toTarget:self
						   withObject:[NSArray arrayWithObjects:@"Second",@"1",nil]];
}

-(void)stopThread
{
	[m_args setRun:NO];
}

-(void)entryPoint
{
	NSTimeInterval interval = 5;//seconds
	NSString* sBadProcessName = @"";
	
	while( [m_args Run] )
	{
		//NSLog(@"Thread func");
		
		sBadProcessName = [self scanProcesses];
		[m_args setBadProcessName:sBadProcessName];
		if ( sBadProcessName.length > 0 )
			[[NSNotificationCenter defaultCenter] postNotificationName:@"terminal_running" object:nil];
		
		[NSThread sleepForTimeInterval:interval];
	}
	
	//NSLog(@"Thread func ENDED");
}

-(NSString*)scanProcesses
{
	NSString *uniqueName = nil;
	
	for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) 
	{
		uniqueName = [app.bundleIdentifier lowercaseString];

//		if ( uniqueName != nil && [uniqueName rangeOfString:@"com.apple.Terminal"].location != NSNotFound )
//		{
//			//NSLog(@"TERMINAL!!");
//			return YES;
//		}
		
		if ( uniqueName != nil )
		{
			NSString* sName = @"";
			
			for( int i=0; i<m_processNames.count; i++ )
			{
				sName = [m_processNames objectAtIndex:i];
				if ([uniqueName rangeOfString:sName].location != NSNotFound)
				{
					//NSLog(@"BAD PROCESS %@ %@\n", app.description, app.bundleIdentifier);
					return app.bundleIdentifier;
				}
			}
		}
		
		//NSLog(@"%@ %@\n", app.description, app.bundleIdentifier);
	}
	return nil;
}

- (NSString*) isBadGuyRunning
{
	if ( m_args != nil )
	{
		return [m_args BadProcessName];
	}
	return nil;
}
@end
