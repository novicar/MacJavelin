//
//  NewThumbItem.h
//  JavelinM
//
//  Created by harry on 21/02/2017.
//
//

#import <Cocoa/Cocoa.h>

@interface NewThumbItem : NSCollectionViewItem
{
	NSImage* m_image;
	
	IBOutlet NSImageView* m_imageView;
}

-(void) setImage:(NSImage*)image;
@end
