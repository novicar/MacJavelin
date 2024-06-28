//
//  ScannerThread.h
//  Javelin3
//
//  Created by Novica Radonic on 21/03/2018.
//

#import <Foundation/Foundation.h>

@interface ThreadArgs : NSObject
{
	int m_nIntValue;
	BOOL m_bRun;
	NSString* m_badProcessName;
}

@property (readwrite) int IntValue;
@property (readwrite) BOOL Run;
@property (readwrite, copy) NSString* BadProcessName;

@end

@interface ScannerThread : NSObject
{
	ThreadArgs* m_args;
	NSArray*	m_processNames;
}

-(void)startThread:(ThreadArgs*)args;
-(void)stopThread;
-(void)entryPoint;
-(NSString*)scanProcesses;
- (NSString*) isBadGuyRunning;
@end



