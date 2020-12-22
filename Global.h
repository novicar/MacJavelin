//
//  Global.h
//  Javelin
//
//  Created by harry on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#ifndef __GLOBAL__
#define __GLOBAL__
#include <string>
#include <sys/timeb.h>
#include <time.h>
#include "DocInfo.h"
#include "DrumlinTypes.h"

class CGlobal
{
public:
	static char* Key();
	static char* Iv();
	static int	m_nVersionMajor;
	static int	m_nVersionMinor;
	static bool Mask( char* buffer, DWORD dwSize );
	static const char* AppTitle();
	
	static DWORD GetVolumeInfo();
	static DWORD GetVolumeInfo( const char* );
	static int GetVolumeInfoAll( DWORD* pIDs, int nCount );
	
	static DWORD Hash( const char* str, DWORD len);
	static DWORD Hash( BYTE* buff, DWORD len);
	
	static int GetWinID( char* szWinID, int nSize );
	
	static void Scramble( char* szOriginal );
	static void Unscramble( std::string& s );
	
	static void DocumentAuthorised( DWORD dwDocID, const char* szCode, DWORD dwHash );
	static DWORD CheckDocument( DWORD dwDocID, char* szCode, int nMaxLen );

	static DWORD GetHash( DWORD, const char* );
	static DWORD GetHashD( DWORD, const char* );
	static DWORD GetHashS( DWORD, DWORD, const char* );
	
	static DWORD ErrorText( char* szError, int nMaxLen );
	//static int U2MB( LPCTSTR szUnicode, char** ppMultiByte, int nLen );
	//static int U2MBXX( LPCTSTR szUnicode, char* szMultiByte, int nLen );
	//static int MB2U( LPCSTR szText, TCHAR** ppUnicode, int nLen );
	//static int MB2UXX( LPCSTR szText, TCHAR* szUnicode, int nLen );
	
	static void Replace( char* szString, char* szReplace, char* szWith );
	
	static bool PrepareBuffer( char* buffer, DWORD dwSize );
	static bool UnprepareBuffer( char* buffer, DWORD dwSize );
//	static PDOCEX_INFO GetDocInfo( WORD );
	static time_t GetTimeT( DWORD );
	static void GetDate( DWORD, unsigned int*, unsigned int*, unsigned int* );
	static bool GetCurrentDate( unsigned int*, unsigned int*, unsigned int* );
	static DWORD GetCurrentDate();
	static void GetTM( DWORD, struct tm* );
	static DWORD CalcTime( struct tm* );
	//static DWORD CalcTimeEx( __time64_t* );
	static int CalcExpires( int nExpiresAfter );
	static DWORD AddDays( DWORD, int );
	static bool IsAfter( DWORD dwDate );
	static bool IsBefore( DWORD dwDate );
	static void AddPubID( char* szText, PDOCEX_INFO pDocInfo, bool bPrinting=false );
	
	static int VersionMajor() { return m_nVersionMajor; }
	static int VersionMinor() { return m_nVersionMinor; }
	static char* Date();
	
//	static int ReadResamplingMethod();
//	static int GetResamplingMethod() { return m_nResamplingMethod; }
	
	static std::string CalculateCode( const char*, const char*, PDOCEX_INFO );
	
	static char* ExpandWMText( const char*, const char*, DWORD );
	static int GetColour( int nDrumlinFontColour );
	
	//static PBRANDING GetResources( WORD dwID );
	static bool IsPDF( const char* );
	
	static void GetSerialNumber( char* pRes, int nLen );
	
	//static HBITMAP CreateBitmapMask(HBITMAP, COLORREF);
public:
	static bool	bPrepared;
	static char key0[32];
	static char iv0[32];
	static char key1[32];
	static char iv1[32];
	static char key2[32];
	static char iv2[32];
	static char keyRes[32];
	static char ivRes[32];
	
};
#endif