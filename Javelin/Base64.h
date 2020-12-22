//
//  Base64.h
//  Javelin
//
//  Created by harry on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#ifndef __BASE_64__
#define __BASE_64__

#include "DrumlinTypes.h"

class CBase64
{
public:
	static void Decode( const char* szEncodedString, BYTE* result, UINT nMaxLen );

private:
	static void decodeblock( BYTE in[4], BYTE out[3] );
	static const char cb64[];
	static const char cd64[];
};
#endif