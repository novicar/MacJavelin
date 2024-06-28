//
//  Global.cpp
//  Javelin
//
//  Created by harry on 8/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "Global.h"
#include "Rijndael.h"
#include <time.h> //time_t
#include <string.h>
#include "md5.h"
#include "UnicodeString.h"

//GetSerialNumber!
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>



#define BUFFER_LEN	1048576

int	CGlobal::m_nVersionMajor = 1;
int	CGlobal::m_nVersionMinor = 0;
char* CGlobal::Date() { return (char*)"2022-09-28"; }

char CGlobal::key0[32] = { 0xDC,0x03,0x08,0x00,0xDD,0xE0,0xB5,0x0C,0x08,0x00,0xC0,0x0E,0x2D,0xB3,0x20,0xA9,0x57,0x0C,0x0F,0xD8,0x07,0xAA,0x09,0xF0,0x06,0xFE,0x20,0xB0,0x08,0x00,0x47,0x09 };
char CGlobal::key1[32] = { 0x1C,0xB3,0x21,0x12,0x2D,0xED,0xBD,0xDC,0xD8,0x0D,0xCD,0xDE,0xDD,0x01,0x11,0xA1,0x5A,0xAC,0xAF,0xDA,0x17,0x1A,0x79,0xF9,0x86,0xF7,0x26,0xB5,0x48,0x03,0x42,0x19 };
char CGlobal::key2[32] = { 0x44,0xcc,0xaa,0x0a,0x0D,0x00,0x05,0x9C,0x99,0x99,0xC9,0x9E,0x29,0x93,0x29,0x99,0x97,0xaC,0x1F,0xa8,0x17,0xAA,0x09,0xF1,0xa6,0xaE,0x10,0xcc,0xD8,0xD0,0x4D,0xC9 };

char CGlobal::iv0[32]  = { 0xB4,0x33,0x0A,0x12,0xEF,0x04,0xA4,0x1E,0x26,0xCF,0x2E,0xDF,0x09,0x33,0xBA,0xBA,0xB4,0x33,0x0A,0x12,0xEF,0x04,0xA4,0x1E,0x26,0xCF,0x2E,0xDF,0x09,0x33,0xBA,0xBA };
char CGlobal::iv1[32]  = { 0x14,0x23,0x1A,0x1D,0xDF,0xD4,0xD4,0xE1,0xA6,0xCA,0xAE,0xBF,0xA9,0x3A,0xCA,0xCA,0xC4,0x3C,0x4A,0x14,0xE4,0x14,0xA3,0x17,0x27,0x99,0x28,0xD8,0x89,0x3B,0xBB,0xB2 };
char CGlobal::iv2[32]  = { 0x24,0x13,0x2A,0xD2,0xED,0x0D,0xAE,0xEE,0x2A,0xAF,0x1E,0xDA,0x0A,0xA3,0xBC,0xBC,0xC4,0xC3,0x44,0x42,0x4F,0xA4,0xA5,0x18,0x29,0x88,0x8E,0x8F,0x79,0xB3,0xBA,0xBB };

char CGlobal::keyRes[32] = { 0x11,0x01,0x18,0x11,0xAD,0xEA,0xB4,0x4C,0x08,0x04,0xC0,0x0E,0x24,0xB3,0x24,0x49,0x57,0x0C,0x0F,0xD8,0x07,0xAA,0x09,0xF0,0x06,0xFE,0x20,0xB0,0x08,0x40,0x47,0x09 };
char CGlobal::ivRes[32]  = { 0xAC,0xBF,0xFF,0x1F,0xFD,0xED,0xBD,0xDC,0xD8,0x0D,0xCD,0xDE,0xDD,0x01,0x11,0x11,0x51,0xAC,0xAF,0xD1,0x17,0x11,0x19,0xF1,0x84,0xF7,0x24,0xB5,0x48,0x43,0x42,0x19 };

bool CGlobal::bPrepared = false;

const char* CGlobal::AppTitle()
{
	return "Drumlin Javelin";
}

/*
#include <CoreServices/CoreServices.h>
 //remember to include CoreService framework
void GetVolumeInfo_CoreService()
{
 FSVolumeRefNum refNum;
 FSVolumeInfoBitmap bits =  kFSVolInfoGettableInfo;
 FSVolumeInfo info;
 HFSUniStr255 name;
 FSRef ref;
 
 OSErr err;
 int i=1;
 do{
	err = FSGetVolumeInfo (
		kFSInvalidVolumeRefNum,//FSVolumeRefNum volume,
		i++,//ItemCount volumeIndex,
		&refNum,//FSVolumeRefNum *actualVolume,
		bits,//FSVolumeInfoBitmap whichInfo,
		&info,//FSVolumeInfo *info,
		&name,//HFSUniStr255 *volumeName,
		&ref//FSRef *rootDirectory
		);

	if ( err == 0 )
	{
		char szTemp[256];
		CUnicodeString::ToChr((const MYCHAR*)name.unicode, szTemp, name.length);
		printf("Diskname: %s", szTemp );
	}
 } while (err == 0);
}
 */
//#include <Files.h>
DWORD CGlobal::GetVolumeInfo()
{
	return GetVolumeInfo( "TO_DO" );
}

DWORD CGlobal::GetVolumeInfo( const char* szDisk )
{
	//To DO
	DWORD dwSerial = 123456;
	return dwSerial;
}

int CGlobal::GetVolumeInfoAll( DWORD* pIDs, int nCount )
{
	//TO DO
	return 1;
}

//JSHash
DWORD CGlobal::Hash(const char* str, DWORD len)
{
	unsigned int hash = 1315423911;
	unsigned int i    = 0;
	
	for(i = 0; i < len; str++, i++)
	{
		hash ^= ((hash << 5) + (*str) + (hash >> 2));
	}
	
	return hash;
}

DWORD CGlobal::Hash(BYTE* buff, DWORD len)
{
	unsigned int hash = 1315423911;
	unsigned int i    = 0;
	
	for(i = 0; i < len; buff++, i++)
	{
		hash ^= ((hash << 5) + (*buff) + (hash >> 2));
	}
	
	return hash;
}

int CGlobal::GetWinID( char* szWinID, int nSize )
{
	szWinID[0] = 0;
	
	strcpy( szWinID, "To-Do" );
	return 0;
}

void CGlobal::Scramble( char* szOriginal )
{
	char* szCopy = new char[ strlen(szOriginal)+1 ];
	strcpy( szCopy, szOriginal );
	char cTemp;
	int i = 0;
	
	while( szCopy[i] != 0 )
	{
		if ( szCopy[i+1] != 0 )
		{
			cTemp = szCopy[i];
			szCopy[i] = szCopy[i+1];
			szCopy[i+1] = cTemp;
			
			szCopy[i+1] ^= 31;
			szCopy[i] ^= 31;
			i+=2;
		}
		else
		{
			szCopy[i] ^= 31;
			i++;
		}
	}
	
	strcpy( szOriginal, szCopy );
	
	delete [] szCopy;
}

void CGlobal::Unscramble( std::string& s )
{
	char* szCopy = new char[ s.length()+1 ];
	strcpy( szCopy, s.c_str() );
	char cTemp;
	
	for( int i=0; i<s.length()-1; i+=2 )
	{
		cTemp = szCopy[i];
		szCopy[i] = szCopy[i+1];
		szCopy[i+1] = cTemp;
		
		szCopy[i] ^= 100;
		szCopy[i+1] ^= 100;
	}
	
	s.empty();
	s.append(szCopy);
	
	delete [] szCopy;
}

void CGlobal::DocumentAuthorised( DWORD dwDocID, const char* szCode, DWORD dwHash )
{
/*	TCHAR szDocID[128];
	wsprintf( szDocID, _T("%x_ID"), dwDocID );
	g_pKey->WriteProfileInt( szDocID, dwHash );
	
	_tcscat( szDocID, _T("_C") );
	TCHAR* szCodeCopy = _tcsdup( szCode );
	Scramble( szCodeCopy );
	g_pKey->WriteProfileString( szDocID, szCodeCopy );
	free( szCodeCopy );*/
}

DWORD CGlobal::CheckDocument( DWORD dwDocID, char* szCode, int nMaxLen )
{
/*	TCHAR szDocID[128];
	wsprintf( szDocID, _T("%x_ID"), dwDocID );
	
	DWORD dwHash = 0;
	dwHash = g_pKey->GetProfileInt( szDocID, 0 );
	
	if ( dwHash != 0 )
	{
		_tcscat( szDocID, _T("_C") );
		
		szCode[0] = 0;
		g_pKey->GetProfileString( szDocID, szCode, nMaxLen );
		Scramble( szCode );
	}
	return dwHash;*/
	return 0;
}

DWORD CGlobal::GetHash( DWORD dwDocID, const char* szAuthCode )
{
/*	DWORD dwSerial = CGlobal::GetVolumeInfo();
	TCHAR szWinID[128];
	CGlobal::GetWinID( szWinID, 128 );
	
	//unsigned int dwRes = 0;
	TCHAR szID[256];
	wsprintf( szID, _T("@%s]%x#%x!%s_"), szWinID, dwSerial, dwDocID, szAuthCode );
	
	CGlobal::Scramble( szID );
	
 return CGlobal::Hash( szID, _tcslen( szID ) );*/ return 0;
}

DWORD CGlobal::GetHashS( DWORD dw, DWORD dwSerial, const char* szTxt )
{
/*	TCHAR szWinID[128];
	CGlobal::GetWinID( szWinID, 128 );
	
	//unsigned int dwRes = 0;
	TCHAR szID[256];
	wsprintf( szID, _T("@%s]%x#%x!%s_"), szWinID, dwSerial, dw, szTxt );
	
	CGlobal::Scramble( szID );
	
 return CGlobal::Hash( szID, _tcslen( szID ) );*/ return 0;
}

DWORD CGlobal::GetHashD( DWORD dwDate, const char* szTxt )
{
/*	TCHAR szWinID[128];
	CGlobal::GetWinID( szWinID, 128 );
	
	TCHAR szID[256];
	wsprintf( szID, _T("@%s]!@#!@#$$!#%x!%s_"), szWinID, dwDate, szTxt );
	
	CGlobal::Scramble( szID );
	
 return CGlobal::Hash( szID, _tcslen( szID ) );*/return 0;
}

/*
 Replaces "szReplace" with "szWidth".
 WARNING: It works only if szWidth is shorter then szReplace!!!
 
 */
void CGlobal::Replace( char* szString, char* szReplace, char* szWith )
{
	char* p = szString;
	int nLen = (int)strlen( szReplace );
	int nLen1= (int)strlen( szWith );
	
	while( NULL != (p = strstr( p, szReplace ) ) )
	{
		strcpy( p, szWith );
		strcpy( p+nLen1, p+nLen );
		p += nLen1;
	}
}

bool CGlobal::PrepareBuffer( char* buffer, DWORD dwSize )
{
	//scramble 1st 4kB block
	try
	{
		CRijndael oRijndael;
		oRijndael.MakeKey( CGlobal::Key(), CGlobal::Iv(), 32, 32);
		
		int nBufferLen = (dwSize<BUFFER_LEN?dwSize:BUFFER_LEN);
		char* bufferTemp = new char[nBufferLen];
		
		oRijndael.Encrypt( buffer, bufferTemp, nBufferLen, CRijndael::CBC );
		
		memcpy( buffer, bufferTemp, nBufferLen );
		
		Mask( buffer, dwSize );
		
		delete [] bufferTemp;
		
		return true;
	}
	catch(exception& roException)
	{
		//cout << roException.what() << endl;
		return false;
	}
}

bool CGlobal::UnprepareBuffer( char* buffer, DWORD dwSize )
{
	//scramble 1st 4kB block
	try
	{
		Mask( buffer, dwSize );
		
		CRijndael oRijndael;
		oRijndael.MakeKey( CGlobal::Key(), CGlobal::Iv(), 32, 32);
		
		int nBufferLen = (dwSize<BUFFER_LEN?dwSize:BUFFER_LEN);
		char* bufferTemp = new char[nBufferLen];
		
		oRijndael.Decrypt( buffer, bufferTemp, nBufferLen, CRijndael::CBC );
		
		memcpy( buffer, bufferTemp, nBufferLen );
		
		delete [] bufferTemp;
		
		return true;
	}
	catch(exception& roException)
	{
		//cout << roException.what() << endl;
		return false;
	}
}

bool CGlobal::Mask( char* buffer, DWORD dwSize )
{
	//	DWORD dwSerial = CGlobal::GetVolumeInfo();
	//	TCHAR szWinID[128];
	//	CGlobal::GetWinID( szWinID, 128 );
	
	//	if ( dwSize > 409600 ) dwSize = 409600;
	for( DWORD i=0; i<dwSize-256; i += 128 )
	{
		for( int j=0; j<32; j++ )
		{
			if ( j % 2 )
				buffer[i+j] = buffer[i+j] ^ key2[j];
			else
				buffer[i+j] = buffer[i+j] ^ key1[j];
		}
	}
	
	return true;
}

char* CGlobal::Key()
{
	if ( !bPrepared )
	{
		bPrepared = true;
		for( int i=0; i<32; i++ )
		{
			key0[i] = (( key0[i] ^ key1[i] ) & key2[i] );
			iv0[i] =  ((  iv0[i] ^  iv1[i] ) &  iv2[i] );
		}
	}
	
	return key0;
}

char* CGlobal::Iv()
{
	if ( !bPrepared )
	{
		bPrepared = true;
		for( int i=0; i<32; i++ )
		{
			key0[i] = (( key0[i] ^ key1[i] ) & key2[i] );
			iv0[i] =  ((  iv0[i] ^  iv1[i] ) &  iv2[i] );
		}
	}
	
	return iv0;
}

void CGlobal::GetDate( DWORD dwDate, unsigned int* pnY, unsigned int* pnM, unsigned int* pnD )
{
	unsigned int t = dwDate;
	unsigned int y = t;
	y = y >> 16;
	unsigned int m = (t&0x0000ff00);
	m = m >> 8;
	unsigned int d = (t&0x000000ff);
	
	*pnY = y;
	*pnM = m;
	*pnD = d;
}

DWORD CGlobal::GetCurrentDate()
{
	time_t s = time(NULL);
	struct tm * timeinfo;
	
	timeinfo = localtime ( &s );
	DWORD dw = CGlobal::CalcTime(timeinfo);
	
	return dw;
}

bool CGlobal::GetCurrentDate( unsigned int* pY, unsigned int* pM, unsigned int* pD )
{
	DWORD dw = CGlobal::GetCurrentDate();
	CGlobal::GetDate( dw, pY, pM, pD );
	
	return true;

/*	struct _timeb timebuffer;
	struct tm now;
	if ( 0 == _ftime64_s( &timebuffer ) && 0 == _localtime64_s( &now, &timebuffer.time ) )
	{
		DWORD dw = CGlobal::CalcTime( &now );
		CGlobal::GetDate( dw, pY, pM, pD );
		
		return true;
	}

	return false;*/
}

DWORD CGlobal::CalcTime( struct tm* ptm )
{
	unsigned int y = ptm->tm_year + 1900;
	unsigned int m = ptm->tm_mon  + 1;
	unsigned int d = ptm->tm_mday;
	
	y <<= 16;
	m <<= 8;
	DWORD dwResult = y + m + d;
	
	return dwResult;
}
/*
DWORD CGlobal::CalcTimeEx( __time64_t* pTime )
{
	struct tm now;
	if (0 == _localtime64_s( &now, pTime ))
	{
		return CalcTime( &now );
	}
	
	return 0;
}
*/
DWORD CGlobal::AddDays( DWORD dwDate, int nDays )
{
	struct tm d;
	GetTM( dwDate, &d );
	d.tm_mday += nDays;
	
	mktime( &d );
	
	return CalcTime( &d );
}

time_t CGlobal::GetTimeT( DWORD dwDate )
{
	struct tm d;
	
	CGlobal::GetTM( dwDate, &d );
	
	time_t tD = mktime(&d);
	
	return tD;
}

void CGlobal::GetTM( DWORD dwDate, struct tm* ptm )
{
	unsigned int y,m,d;
	
	CGlobal::GetDate( dwDate, &y, &m, &d );
	
	ptm->tm_hour = 23;
	ptm->tm_mday = d;
	ptm->tm_min  = 59;
	ptm->tm_mon  = m-1;
	ptm->tm_sec  = 59;
	ptm->tm_year = y-1900;
	ptm->tm_isdst= 0;
	ptm->tm_wday = 0;
	ptm->tm_yday = 0;
	
	mktime( ptm );
}

/*
 Returns TRUE is current date is after dwDate
 */
bool CGlobal::IsAfter( DWORD dwDate )
{
/*	unsigned int y,m,d;
	unsigned int yNow,mNow,dNow;
	
	GetCurrentDate(&yNow, &mNow, &dNow);
	GetDate(dwDate, &y, &m, &d);
	
	if ( yNow < y ) return false;
	
	time_t tDate = GetTimeT( dwDate );
	time_t tNow; 
	time( &tNow );
	
	if ( tNow >= tDate ) return true;
	else return false;*/
	
	DWORD dwNow = GetCurrentDate();
	
	if ( dwNow > dwDate ) return true;
	
	return false;
}

/*
 Returns TRUE if current date is before dwDate
 
 */
bool CGlobal::IsBefore( DWORD dwDate )
{
/*	time_t tDate;
	struct tm d;
	unsigned int y,m,day;
	
	CGlobal::GetDate( dwDate, &y, &m, &day );
	
	d.tm_hour = 0;
	d.tm_mday = day;
	d.tm_min  = 0;
	d.tm_mon  = m-1;
	d.tm_sec  = 0;
	d.tm_year = y-1900;
	d.tm_isdst= 0;
	d.tm_wday = 0;
	d.tm_yday = 0;
	
	tDate = mktime( &d );
	
	time_t tNow; 
	time( &tNow );
	
	if ( tNow <= tDate ) return true;
	else return false;*/
	
	DWORD dwNow = GetCurrentDate();
	dwNow ++;
	
	if ( dwNow < dwDate ) return true;
	
	return false;
}

int CGlobal::CalcExpires( int nExpiresAfter )
{
	time_t tNow;
	time( &tNow );
	struct tm* ptm = localtime(&tNow);
	
	ptm->tm_mday += nExpiresAfter;
	mktime( ptm );
	return (int)CGlobal::CalcTime( ptm );
}

std::string CGlobal::CalculateCode( const char* szName, const char* szEmail1, PDOCEX_INFO pDocInfo )
{
	MD5 md5;
	char szTemp[1024];
	char szDocName[512];
	char szEmail[512];
	//char* szDot = NULL;
	
	//strcpy( szDocName, pDocInfo->szDocName );
	CUnicodeString::ToChr( (const MYCHAR*)pDocInfo->szDocName, szDocName, 512);
	strcpy( szEmail, szEmail1 );
	
	//replace extension from DRM to PDF
	for( INT i=(INT)strlen(szDocName)-1; i>0; i-- )
	{
		if ( szDocName[i] == '.' )
		{
			strcat( szDocName, "pdf" );
			break;
		}
		szDocName[i] = '\x0';
	}
	
	CUnicodeString::StrLwr( szDocName );
	CUnicodeString::StrLwr( szEmail );
	sprintf( szTemp, "@@NAME=%s$$EMAIL=%s^^^^[[%s__%d$$%d]]", 
				szName, szEmail, szDocName, pDocInfo->dwOwnerID, pDocInfo->dwDocID  );
	//		g_pLog->AddLine( szTemp );
	for( int i=0; i<strlen( szTemp ); i++ )
	{
		szTemp[i] -= 2;
	}
	//		g_pLog->AddLine( szTemp );
	
	md5.update( (const unsigned char*)szTemp, (UINT)strlen(szTemp) );
	md5.finalize();
	std::string s = md5.hexdigest();
	
	return s;
}


// Returns the serial number as a CFString. 
// It is the caller's responsibility to release the returned CFString when done with it.
void CGlobal::GetSerialNumber( char* pRes, int nLen )
{
    if (pRes != NULL) {
        memset( pRes, 0, nLen );
		
        io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
													IOServiceMatching("IOPlatformExpertDevice"));
		
        if (platformExpert) {
            //char* serialNumberAsCFString = (char*)
			CFStringRef object = (CFStringRef)
			IORegistryEntryCreateCFProperty(platformExpert,
											//CFSTR(kIOPlatformSerialNumberKey),
											CFSTR(kIOPlatformUUIDKey),
											kCFAllocatorDefault, (IOOptionBits)0);
			CFStringGetCString( object, pRes, 256, kCFStringEncodingMacRoman );
			/*            if (serialNumberAsCFString) {
				                // *serialNumber = serialNumberAsCFString;
				//strncpy( sResult, serialNumberAsCFString, nLen );
				sprintf( sResult, "%02X 
            }*/
			
            IOObjectRelease(platformExpert);
        }
    }
}



	
