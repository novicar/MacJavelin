//
//  WarningController.h
//  Javelin3
//
//  Created by Novica Radonic on 20/08/2018.
//

#import <Cocoa/Cocoa.h>

@interface WarningController : NSWindowController
{
	IBOutlet NSButton*			m_btnOK;
	IBOutlet NSView*			m_view;
	
	IBOutlet NSTextField*		m_firstLine;
	IBOutlet NSTextField*		m_secondLine;
	IBOutlet NSTextField*		m_thirdLine;
	
	NSString*					m_sFirst;
	NSString*					m_sSecond;
	NSString*					m_sThird;
	
}
-(id)initWindow;

-(IBAction) ok:(id)sender;

-(void)setLabels:(NSString*)sFirst second:(NSString*)sSecond third:(NSString*)sThird;
@end
