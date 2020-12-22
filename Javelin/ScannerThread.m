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
@synthesize TerminalRunning = m_bTerminalRunning;

@end

#pragma mark --ScannerThread

@implementation ScannerThread
-(void)startThread:(ThreadArgs*)args
{
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
	BOOL bTerminalRunning = NO;
	
	while( [m_args Run] )
	{
		//NSLog(@"Thread func");
		
		bTerminalRunning = [self scanProcesses];
		[m_args setTerminalRunning:bTerminalRunning];
		if ( bTerminalRunning )
			[[NSNotificationCenter defaultCenter] postNotificationName:@"terminal_running" object:nil];
		
		[NSThread sleepForTimeInterval:interval];
	}
	
	//NSLog(@"Thread func ENDED");
}

-(BOOL)scanProcesses
{
	NSString *uniqueName = nil;
	
	for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		uniqueName = app.bundleIdentifier;
		//.location == NSNotFound
		if ( uniqueName != nil && [uniqueName rangeOfString:@"com.apple.Terminal"].location != NSNotFound )
		{
			//NSLog(@"TERMINAL!!");
			return YES;
		}
		//BOOL hasWindow = (app.activationPolicy == NSApplicationActivationPolicyRegular)?YES:NO;
		//NSLog(@"APP:%@ hasWindow:%d", uniqueName, hasWindow );
	}
	return NO;
}

- (BOOL) isTerminalRunning
{
	if ( m_args != nil )
	{
		return [m_args TerminalRunning];
	}
	return NO;
}
@end
