//
//  AuthCodePanel.m
//  Javelin
//
//  Created by harry on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AuthCodePanel.h"

@synthesize controller;

@implementation AuthCodePanel

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


//	PUBLIC INSTANCE METHODS -- OVERRIDES FROM NSWindow

//	NSWindow will refuse to become the main window unless it has a title bar.
//	Overriding lets us become the main window anyway.
- (BOOL) canBecomeMainWindow
{
    return YES;
}

//	Much like above method.
- (BOOL) canBecomeKeyWindow
{
    return YES;
}

//	Ask our delegate if it wants to handle keystroke or mouse events before we route them.
- (void) sendEvent:(NSEvent *) theEvent
{
    //	Offer key-down events to the delegats
    if ([theEvent type] == NSKeyDown)
        if (self.controller)
            if ([self.controller handlesKeyDown: theEvent  inWindow: self])
                return;
	
    //	Offer mouse-down events (lefty or righty) to the delegate
    if ( ([theEvent type] == NSLeftMouseDown) || ([theEvent type] == NSRightMouseDown) )
        if (self.controller)
            if ([self.controller handlesMouseDown: theEvent  inWindow: self])
                return;
	
    //	Delegate wasn’t interested, so do the usual routing.
    [super sendEvent: theEvent];
}

@end
