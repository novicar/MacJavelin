//
//  MyThumbnailView.m
//  JavelinM
//relevantknowledge
//  Created by harry on 21/10/2016.
//
//

#import "MyThumbnailView.h"

@implementation MyThumbnailView
//@synthesize PDFView;

- (MyThumbnailView*)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if ( self )
	{
	}
	return self;
}

- (MyThumbnailView*)initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if ( self )
	{
	}
	return self;
}

- (void)awakeFromNib
{
	int i = 100;
	i++;
}

- (void)drawRect:(NSRect)rect {
   //[super drawRect:rect];
    
    // Drawing code here.
}

-(void)mouseDown:(NSEvent *)event
{
	int i = 100;
	i++;
}

/*-(BOOL) acceptsFirstResponder
{
	return YES;
}

-(BOOL) acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}*/
@end
