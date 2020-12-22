//
//  UnicodeString.h
//  Javelin
//
//  Created by harry on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#ifndef __UNICODE_STRING__
#define __UNICODE_STRING__
#include "DrumlinTypes.h"

class CUnicodeString
{
public:
	static INT StrLen( const MYCHAR* s );
	static INT StrCpy( MYCHAR* sDest, const MYCHAR* sSrc );
	static INT StrCmp( const MYCHAR* s1, const MYCHAR* s2 );
	static INT StrStr( const MYCHAR* s1, const MYCHAR* s2 );
	static MYCHAR* StrDup( const MYCHAR* s );
	static void ToChr( const MYCHAR* s, char* sc, INT nMaxLen );
	static void ToUnicode( const char* sChar, BYTE* pUnicode, INT nMaxLen );
	static void StrLwr( char* s );
};
#endif
