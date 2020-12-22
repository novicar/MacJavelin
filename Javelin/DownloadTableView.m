//
//  DownloadTableView.m
//  Javelin
//
//  Created by harry on 27/08/2013.
//
//

#import "DownloadTableView.h"


@implementation DownloadTableView

@synthesize rightClickedRow=m_row;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		m_row = -1;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}
/*
-(NSMenu*)menuForEvent:(NSEvent*)theEvent
{
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
   int row = [self rowAtPoint:mousePoint];
   // Produce the menu here or perform an action like selection of the row.
   
   NSLog(@"%f : %f (%d)", mousePoint.x, mousePoint.y, row);
}
*/

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int row = [self rowAtPoint:mousePoint];
	//NSLog(@"%f : %f (%d)", mousePoint.x, mousePoint.y, row);
	
	m_row = row;
	
	[super rightMouseDown:theEvent];
}

@end
