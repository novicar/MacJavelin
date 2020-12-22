//
//  UnicodeString.cpp
//  Javelin
//
//  Created by harry on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <stdlib.h>
#include <string.h>

#include "UnicodeString.h"

#define MAX_STR_LEN	10240

INT CUnicodeString::StrLen( const MYCHAR* s )
{
	const BYTE* data = (const BYTE*)s;
	for( INT i=0; i<MAX_STR_LEN; i+=2 )
	{
		if ( data[i] == '\x0' && data[i+1] == '\x0' ) return (i/2);
	}
	
	return (-1);
}

INT CUnicodeString::StrCpy( MYCHAR* sDest, const MYCHAR* sSrc )
{
	const BYTE* src = (const BYTE*)sSrc;
	BYTE* dest= (BYTE*)sDest;
	
	for( INT i=0; i<MAX_STR_LEN; i+=2 )
	{
		dest[i] = src[i];
		dest[i+1] = src[i+1];
		
		if ( src[i] == '\x0' && src[i+1] == '\x0' )
		{
			return (i/2);
		}
	}
	
	return (-1);
}

INT CUnicodeString::StrCmp( const MYCHAR* s1, const MYCHAR* s2 )
{
	const BYTE* src = (const BYTE*)s1;
	const BYTE* dest= (const BYTE*)s2;
	
	for( INT i=0; i<MAX_STR_LEN; i+=2 )
	{
		if ( dest[i] != src[i] || dest[i+1] != src[i+1] ) return -1;
		
		if ( src[i] == '\x0' && src[i+1] == '\x0' )
		{
			return 0;
		}
	}
	
	return (1);
}

//searches for occurence of s2 in s1
INT CUnicodeString::StrStr( const MYCHAR* s1, const MYCHAR* s2 )
{
	INT nLen1 = CUnicodeString::StrLen( s1 );
	if ( nLen1 <= 0 ) return -1;
	
	INT nLen2 = CUnicodeString::StrLen( s2 );
	if ( nLen2 <= 0 ) return -2;
	
	const BYTE* b1 = (const BYTE*)s1;
	const BYTE* b2 = (const BYTE*)s2;
	bool bFound = false;
	
	for( INT i=0; i<nLen1*2; i++ )
	{
		if ( b1[i] == b2[0] )
		{
			bFound = true;
			for( INT j=1; j<nLen2*2 && (i+j < nLen1*2); j++ )
			{
				if ( b1[i+j] != b2[j] )
				{
					bFound = false;
					break;
				}
			}
			if ( bFound ) return i;
		}
	}
	
	return -1;
}

MYCHAR* CUnicodeString::StrDup( const MYCHAR* s )
{
	const BYTE* src = (const BYTE*)s;
	INT nLen = CUnicodeString::StrLen(s);
	if ( nLen <= 0 ) return NULL;
	
	BYTE* dest = (BYTE*)malloc( nLen*2 + 2 );
	for( INT i=0; i<nLen*2+2; i++ )
	{
		dest[i] = src[i];
	}

	return (MYCHAR*)dest;
}

void CUnicodeString::ToChr(const MYCHAR *s, char *sc, INT nMaxLen )
{
	INT nLen = CUnicodeString::StrLen( s );
	if ( nLen > 0 )
	{
		nLen = nLen*2+2;
		const BYTE* p = (const BYTE*)s;
		
		for( int i=0, j=0; i<nLen && j< nMaxLen; i+=2, j++ )
		{
			if ( p[i] != 0 && (p[i] < 0x20 || p[i] > 127) )
				sc[j] = '_';
			else
				sc[j] = p[i];
			sc[j+1] = '\x0';
		}
	}
}

void CUnicodeString::ToUnicode( const char* sChar, BYTE* pUnicode, INT nMaxLen )
{
	UINT nLen = (UINT)strlen( sChar );
	
	if ( nLen > 0 )
	{
		for( int c=0, u=0; c<nLen && u<nMaxLen; c++,u+=2 )
		{
			pUnicode[u] = sChar[c];
			pUnicode[u+1] = '\x0';
			pUnicode[u+2] = '\x0';
			pUnicode[u+3] = '\x0';
		}
	}
	
}

void CUnicodeString::StrLwr( char* s )
{
	UINT nLen = (UINT)strlen( s );
	
	for( UINT i=0; i<nLen; i++ )
	{
		if ( s[i] >= 'A' && s[i] <= 'Z' )
			s[i] += ' ';
	}
}