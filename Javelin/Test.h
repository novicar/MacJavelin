#ifndef __TEST_CLASS__
#define __TEST_CLASS__

//
//  Test.h
//  Javelin
//
//  Created by harry on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

class CTestClass
{
public:
    CTestClass() { m_nX = m_nY = 0; }
    int getX() const { return m_nX; }
    int getY() const { return m_nY; }
    
    void setVars( int x, int y );
private:
    int m_nX;
    int m_nY;
};

#endif

