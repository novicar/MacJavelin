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
	BOOL m_bTerminalRunning;
}

@property (readwrite) int IntValue;
@property (readwrite) BOOL Run;
@property (readwrite) BOOL TerminalRunning;

@end

@interface ScannerThread : NSObject
{
	ThreadArgs* m_args;
}

-(void)startThread:(ThreadArgs*)args;
-(void)stopThread;
-(void)entryPoint;
-(BOOL)scanProcesses;
- (BOOL) isTerminalRunning;
@end



