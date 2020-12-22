//
//  AuthCodePanel.h
//  Javelin
//
//  Created by harry on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AC_Controller
- (BOOL) handlesKeyDown: (NSEvent *) keyDown inWindow: (NSWindow *) window;
- (BOOL) handlesMouseDown: (NSEvent *) mouseDown inWindow: (NSWindow *) window;
@end

@interface AuthCodePanel : NSPanel {
    id<AC_Controller> controller;
}

@property (nonatomic, assign) id<AC_Controller> controller;

@end
@end
