//
//  PDFView+rightMouseDown.m
//  JavelinM
//
//  Created by harry on 24/09/2014.
//
//

#import "PDFView+rightMouseDown.h"

@implementation PDFView (rightMouseDown)
-(void)rightMouseDown:(NSEvent *)theEvent
{
	//NSLog(@"RIGHT\n");
     //[self.scene rightMouseDown:theEvent];
}

-(void)setMenu:(NSMenu *)menu
{
	//NSLog(@"MENU\n");
	//[super setMenu:nil];
	[self.window setMenu:nil];
}
@end
