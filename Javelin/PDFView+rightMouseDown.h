//
//  PDFView+rightMouseDown.h
//  JavelinM
//
//  Created by harry on 24/09/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface PDFView (rightMouseDown)
	-(void)rightMouseDown:(NSEvent *)theEvent;
	-(void)setMenu:(NSMenu *)menu;
@end
