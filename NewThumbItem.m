//
//  NewThumbItem.m
//  JavelinM
//
//  Created by harry on 21/02/2017.
//
//

#import "NewThumbItem.h"

@interface NewThumbItem ()

@end

@implementation NewThumbItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void) setImage:(NSImage*)image
{
	//m_image = image;
	
	m_imageView.image = image;
}
@end
