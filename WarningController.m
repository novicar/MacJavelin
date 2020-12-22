//
//  WarningController.m
//  Javelin3
//
//  Created by Novica Radonic on 20/08/2018.
//

#import "WarningController.h"

@interface WarningController ()

@end

@implementation WarningController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.window makeFirstResponder:m_view];
	
	if ( m_sFirst != nil )
		[m_firstLine setStringValue:m_sFirst];
	
	if ( m_sSecond != nil )
		[m_secondLine setStringValue:m_sSecond];
	
	if ( m_sThird != nil )
		[m_thirdLine setStringValue:m_sThird];
}

- (id)initWindow
{
	self = [[WarningController alloc] initWithWindowNibName:@"WarningController"];
	if (self) 
	{
		// Initialization code here.
	}
	
	return self;
}

-(IBAction) ok:(id)sender
{
	[[self window] close];
}

-(void)setLabels:(NSString*)sFirst second:(NSString*)sSecond third:(NSString*)sThird
{
	m_sFirst = sFirst;
	m_sSecond = sSecond;
	m_sThird = sThird;
	
//	[m_firstLine setStringValue:sFirst];
//	[m_secondLine setStringValue:sSecond];
//	[m_thirdLine setStringValue:sThird];
}
@end
