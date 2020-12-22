//
//  TestOC.m
//  Javelin
//
//  Created by harry on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TestOC.h"
#import "Test.h"


@implementation TestOC

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) doSomething: (int) x andY: (int) y
{
    CTestClass* p = new CTestClass();
    p->setVars(x+1,y-1);

    NSLog( @"X=%d Y=%d", p->getX(), p->getY() );
    delete p;
}

@end
