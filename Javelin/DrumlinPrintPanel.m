//
//  DrumlinPrintPanel.m
//  Javelin
//
//  Created by harry on 9/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DrumlinPrintPanel.h"


@implementation DrumlinPrintPanel

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
/*
- (void)dealloc
{
    [super dealloc];
}
*/
- (void) awakeFromNib
{
}

- (void)beginSheetWithPrintInfo:(NSPrintInfo *)printInfo modalForWindow:(NSWindow *)docWindow delegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo
{
	[super beginSheetWithPrintInfo:printInfo 
					modalForWindow:docWindow 
						  delegate:modalDelegate 
					didEndSelector:didEndSelector 
					   contextInfo:contextInfo];
}

- (void)setOptions:(NSPrintPanelOptions)options
{
	NSPrintPanelOptions myOptions = options;
	
	if ( (myOptions & NSPrintPanelShowsPreview) == NSPrintPanelShowsPreview )
	{
		myOptions ^= NSPrintPanelShowsPreview;
	}
	
	[super setOptions:myOptions];
}
@end
