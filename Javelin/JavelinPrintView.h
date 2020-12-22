//
//  JavelinPrintView.h
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "DocInfo.h"
#import "PDFView+rightMouseDown.h"

@class Watermark;

@interface JavelinPrintView : NSImageView {
@private
	Watermark*	_watermark;
}

-(void) setWatermark:(Watermark*)watermark;

//-(void) doMyPrint:(NSPrintInfo*)pi;

//- (void)printPDFFromData:(NSData*)data printInfo:(NSPrintInfo*)printInfo page:(PDFPage*)page;
@end
