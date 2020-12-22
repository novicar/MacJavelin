//
//  FreeNoteWindow.m
//  JavelinM
//
//  Created by harry on 13/02/2015.
//
//

#import "FreeNoteWindow.h"

@implementation FreeNoteWindow

-(void)windowDidMove:(NSNotification *)notification
{
	//NSLog(@"Did move");
}
-(void)becomeKeyWindow
{
	//NSLog(@"Becomes KeyWindow");
	[super becomeKeyWindow];
}

-(void)resignKeyWindow
{
	//NSLog(@"Resign KeyWindow");
	[super resignKeyWindow];
}

- (BOOL)resignFirstResponder
{
	//NSLog(@"Resign FR");
	return [super resignFirstResponder];
}

- (BOOL)becomeFirstResponder
{
	//NSLog(@"Become FR");
	
	return [super becomeFirstResponder];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	//NSLog(@"Did Resign Key--");
}

-(void)windowDidResignMain:(NSNotification *)notification
{
	//NSLog(@"Did Resign Main--");
}

-(void)createWnd
{
NSButton* bb = [[NSButton alloc] initWithFrame:NSMakeRect(3, 3, 40, 20)];
	
NSTextField* tf = [[NSTextField alloc] initWithFrame:NSMakeRect(3, 20, 100, 20)];

[[self contentView] addSubview:tf];
[[self contentView] addSubview:bb];

}

@end
