//
//  MyGrid.m
//  Javelin3
//
//  Created by Novica Radonic on 07/06/2018.
//

#import "MyGrid.h"

@implementation MyGrid

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)event
{
	NSLog(@"KEY DOWN");
/*	if (@available(macOS 10.13, *)) {
		[self setFrameSize: self.collectionViewLayout.collectionViewContentSize];
	}*/
}

-(BOOL)becomeFirstResponder
{
	return YES;
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}
@end
