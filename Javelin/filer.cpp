#include <stdlib.h> // pulls in declaration of malloc, free
#include <unistd.h> // file IO
#include <string.h> // pulls in declaration for strlen.

#include "filer.H"

#include "Rijndael.h"
#include <sys/stat.h>
//#include <share.h>
//#include <io.h>
#include <errno.h>
#include <fcntl.h>
//#ifdef DEBUG
//#include <stdio.h>
//#endif
#define	HEADER_LEN	144

extern unsigned char* align( unsigned char* pData, int nLen, int nBlockSize, int* pnNewLen );
char CFiler::key1[32]  = { '\xBA', '\xBA', '\x18', '\x11', '\xAD', '\xEA', '\xB4', '\x4C', '\x08', '\x04', '\xC0', '\x0E', '\x24', '\xB3', '\x24', '\x49', '\x57', '\x0C', '\x0F', '\xD8', '\x07', '\xAA', '\x09', '\xF0', '\x06', '\xFE', '\x20', '\xB0', '\x08', '\x40', '\x47', '\x09' };
char CFiler::key2[32]  = { '\xDE', '\xDA', '\xFF', '\x1F', '\xFD', '\xED', '\xBD', '\xDC', '\xD8', '\x0D', '\xCD', '\xDE', '\xDD', '\x01', '\x11', '\x11', '\x51', '\xAC', '\xAF', '\xD1', '\x17', '\x11', '\x19', '\xF1', '\x84', '\xF7', '\x24', '\xB5', '\x48', '\x43', '\x42', '\x19' };
//#define _SH_DENYNO      0x40
//#define _DEBUG_LOG_

#ifdef _DEBUG_LOG_
char g_szLog[1024];
void Log( char* s )
{
	printf( s );
}

void Log( const MYCHAR* s )
{
	CUnicodeString::ToChr( s, g_szLog, 1024 );
	Log( g_szLog );
}
#endif
//#ifdef _DEBUG_LOG_
//extern void Log( char* szMsg );
//#endif

MYCHAR *CValue::u_strdup(MYCHAR *in) 
{
    UINT len = (UINT)MYSTRLEN(in) + 1;
    MYCHAR *result = (MYCHAR*)malloc(2 * len);
    memcpy(result, in, 2 * len);
    return result;
}

CFiler::CFiler(void)
{
	m_list = new list<CValue*>;
}

CFiler::~CFiler(void)
{
	DeleteAll();
	
//	if ( m_list != NULL )
//		delete m_list;
	m_list = NULL;
}

INT	CFiler::AddValue( INT nType, const MYCHAR* szName, const void* pValue )
{
	CValue* pV = GetValue( szName );
	
	if ( pV != NULL )
	{
		if ( nType == pV->GetType() )
			pV->SetValue( nType, pValue ); //value already exists in the list and the type matches!
		else
			pV->SetValue( nType, pValue ); //value exists but type doesn't match - change entry
			
		return GetSize();
	}
	
	//completely new value - add it to the list
	pV = new CValue( nType, szName, pValue );

	m_list->push_back( pV );
	return GetSize();
}

INT CFiler::AddValue( const CValue* pValue )
{
	if ( pValue == NULL ) return -1;
	
	return AddValue( pValue->GetType(), pValue->GetName(), pValue->GetValue() );
}

CValue* CFiler::GetValue( INT nIndex ) const
{
	list<CValue*>::iterator iter;
	INT n = 0;
	
	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		if ( n == nIndex )
		{
			CValue* pV = *iter;
			return pV;
		}
	}

	return NULL;
}

CValue* CFiler::GetValue( const MYCHAR* szName ) const
{
	list<CValue*>::iterator iter;
	CValue* pV = NULL;
	
	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		pV = *iter;
		if ( pV != NULL )
		{
			if ( MYSTRCMP( szName, pV->GetName() ) == 0 )
				return pV;
		}
	}

	return NULL;
}

//MAC ONLY!!
CValue* CFiler::GetValueA( const char* szName ) const
{
	list<CValue*>::iterator iter;
	CValue* pV = NULL;
	static BYTE byTemp[256];
	
	CUnicodeString::ToUnicode( szName, byTemp, 256 );
	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		pV = *iter;
		if ( pV != NULL )
		{
			if ( MYSTRCMP( (MYCHAR*)byTemp, pV->GetName() ) == 0 )
				return pV;
		}
	}
	
	return NULL;
}

bool CFiler::DeleteValue( INT nIndex )
{
	list<CValue*>::iterator iter;
	INT n = 0;
	
	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		if ( n == nIndex )
		{
			CValue* pV = *iter;
			if ( pV != NULL ) delete pV;
			
			m_list->erase( iter );
			return true;
		}
	}

	return false;
}

bool CFiler::DeleteValue( const MYCHAR* szName )
{
	list<CValue*>::iterator iter;
	CValue* pV = NULL;
	
	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		pV = *iter;
		if ( pV != NULL )
		{
			if ( MYSTRCMP( szName, pV->GetName() ) == 0 )
			{
				m_list->erase( iter );
				delete pV;
				return true;
			}
		}
	}

	return false;
}

void CFiler::DeleteAll()
{
	if ( !m_list->empty() )
	{
		list<CValue*>::iterator iter;
		CValue* pV = NULL;
			
		for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
		{
			pV = *iter;
			delete pV;
			pV = NULL;
		}
		
		m_list->clear();
	}
}

//Retrieves all the data from the list in form of an byte array.
//The length of the array is returned in pnLen.
BYTE* CFiler::GetData( INT* pnLen ) const
{
	list<CValue*>::const_iterator iter;
	CValue* pV = NULL;
	INT nLen = 0;
	BYTE* pData = NULL;
	INT nTotalLen = 0;

	for ( iter = m_list->begin( ); iter != m_list->end( ); iter++ )
	{
		pV = *iter;
		BYTE* p = pV->GetData( &nLen );
		
		if ( nTotalLen == 0 )
		{
			pData = p;
			nTotalLen = nLen;
		}
		else if ( nLen > 0 )
		{
			pData = (BYTE*)realloc( pData,	nTotalLen+nLen );
			memcpy( pData+nTotalLen, p, nLen );
			free( p );
			
			nTotalLen += nLen;
		}
	}
	
	*pnLen = nTotalLen;
	return pData;
}

//Saves the list of data values and encrypts it using the Rijndael algorithm.
//returns TRUE if successful, FALSE otherwise
bool CFiler::Save( const char* szFile, const BYTE* bKey, const BYTE* bIV, INT nKeyLength, INT nBlockSize ) const
{
	BYTE* pData = NULL;
	INT nTotalLen = 0;
	INT fh = 0;
	
/*    
	//open a file
	errno_t err = _wsopen_s( &fh, szFile, _O_RDWR|_O_CREAT|_O_TRUNC|_O_BINARY, _SH_DENYNO, _S_IREAD | _S_IWRITE );
	if( err != 0 )
	{
		return false;
	}
*/
    fh = open( szFile, O_RDWR|O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR );
    if ( fh < 0 ) return false;
    
	//get all the data from the list
	pData = GetData( &nTotalLen );
	
	//write data to the file
	if ( pData != NULL && nTotalLen > 0 )
	{
		//encrypt if needed
		if ( bKey != NULL && bIV != NULL && nKeyLength > 0 && nBlockSize > 0 )
		{
			CRijndael oRijndael;
			oRijndael.MakeKey( (const char*)bKey, (const char*)bIV, nKeyLength, nBlockSize );
			
			if ( nTotalLen % nBlockSize > 0 )
			{
				//align to block size
				INT nExtra = nTotalLen % nBlockSize;
				INT nOldLen = nTotalLen;
				nTotalLen += (nBlockSize-nExtra);
				
				pData = (BYTE*)realloc( pData, nTotalLen );
				//fill extra bytes with zeros
				for( INT i=nOldLen; i<nTotalLen; i++ )
				{
					pData[i] = 0x00;
				}
			}

			BYTE* pTemp = (BYTE*)malloc(  nTotalLen );
			try{
				oRijndael.Encrypt( (const char*)pData, (char*)pTemp, nTotalLen, CRijndael::ECB );
			} catch (exception& ex ) {
				free( pData );
				free( pTemp );
				return false;
			}
			free( pData );
			pData = pTemp;
		}

		if ( -1 == write( fh, (const void*)pData, (size_t)nTotalLen ))
		{
			//INT nn = errno;
			return false;
		}
	}
	
	//close file and free the memory
	close( fh );
	free( pData );
	
	return true;
}

//Loads the list of data values and decrypts it if necessary.
//Returns FALSE in case of error, TRUE otherwise.
bool CFiler::Load( long lLen, BYTE* pData, const BYTE* bKey, const BYTE* bIV, INT nKeyLength, INT nBlockSize )
{
    DeleteAll();
	BYTE* pTemp = NULL;
	
	if ( bKey != NULL && bIV != NULL && nKeyLength != 0 && nBlockSize != 0 )
	{
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)bKey, (const char*)bIV, nKeyLength, nBlockSize );

		if ( lLen % nBlockSize > 0 )
		{
			//align to block size
			INT nExtra = (INT)(lLen % nBlockSize);
			
			lLen += (nBlockSize - nExtra);
			
			pData = (BYTE*)realloc( pData, lLen );
		}
		
		pTemp = (BYTE*)malloc( lLen );
		
		try{
			oRijndael.Decrypt( (const char*)pData, (char*)pTemp, lLen, CRijndael::ECB );
		} catch (exception& ex ) {
			//free( pData ); DON'T FREE BUFFER HERE - it will be freed in the caller!!
			free( pTemp );
			return false;
		}
		//free( pData ); DON'T FREE BUFFER HERE - it will be freed in the caller!!
		pData = pTemp;
	}
	
	INT nValues = LoadValues( pData, lLen, nBlockSize );
	
	if ( pTemp != NULL )
		free( pTemp );

	return (nValues > 0);
}
/*
INT CFiler::UstrLen( BYTE* data ) const
{
	for( INT i=0; i<10240; i+=2 )
	{
		if ( data[i] == '\x0' && data[i+1] == '\x0' ) return (i/2);
	}
	
	return (-1);
}

INT CFiler::UstrCpy( BYTE* src, BYTE* dest )
{
	for( INT i=0; i<10240; i+=2 )
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
*/
INT CFiler::LoadValues( BYTE* pData, long lLen, INT nBlockSize )
{
	long nIndex = 0;

#ifdef _DEBUG_LOG_
	char szDebug[1024];
	Log( "LV0 " );
#endif
	DeleteAll();
		
#ifdef _DEBUG_LOG_
	Log( "LV1 " );
#endif

	while( nIndex < lLen )
	{
		INT nTotalLen = 0;
		INT nType = 0;
		INT nValLen = 0;
		BYTE* pValue = NULL;
		MYCHAR* szName = NULL;
		
		memcpy( &nTotalLen, pData+nIndex, 4 ); nIndex += 4;
		memcpy( &nType,     pData+nIndex, sizeof( INT ) ); nIndex += 4;
		memcpy( &nValLen,   pData+nIndex, sizeof( INT ) ); nIndex += 4;

#ifdef _DEBUG_LOG_
		sprintf( szDebug, "\r\nTotalLen:%d nType:%d nValLen:%d nIndex:%ld", nTotalLen, nType, nValLen, nIndex );
		Log( szDebug );
#endif

		if ( nTotalLen > 0 && nType >= 0 && nType <= TYPE_BINARY && nValLen > 0 && nValLen <  1024 )
		{
			//data is OK
			pValue = new BYTE[ nValLen ];
			memcpy( pValue,     pData+nIndex, nValLen ); nIndex += nValLen;

			//////?????????
			int nNameLen = MYSTRLEN((MYCHAR*)(pData+nIndex));//UstrLen( &pData[nIndex] );
//			szName = new MYCHAR[ nNameLen+1 ];
			
//			UstrCpy( &pData[nIndex], (BYTE*)szName);//memcpy( szName, (pData+nIndex), nNameLen*2 ); 
			//?????????????
			szName = MYSTRDUP( (MYCHAR*)(pData+nIndex) ); 
#ifdef _DEBUG_LOG_
			sprintf( szDebug, 
					"ORIG Name:%02x %02x %02x %02x %02x %02x %02x\r\n", 
					(char)(*(pData+nIndex)), 
					(char)(*(pData+nIndex+1)),
					(char)(*(pData+nIndex+2)),
					(char)(*(pData+nIndex+3)),
					(char)(*(pData+nIndex+4)),
					(char)(*(pData+nIndex+5)),
					(char)(*(pData+nIndex+6)) );
			Log( szDebug );
#endif

            //nIndex += (MYSTRLEN( szName )*sizeof( MYCHAR ) + sizeof( MYCHAR ));
			//nIndex += (MYSTRLEN( szName )*2 + 2);
			nIndex += nNameLen*2 +2;
#ifdef _DEBUG_LOG_
			sprintf( szDebug, "[%ld], Name:%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\r\n", 
					nIndex, 
					(char)szName[0],(char)szName[1],(char)szName[2],(char)szName[3],(char)szName[4],
					(char)szName[5],(char)szName[6],(char)szName[7],(char)szName[8],(char)szName[9] );
			Log( szDebug );
#endif

			AddValue( nType, szName, pValue );
			delete [] pValue;
			free( szName );
		}
		else
		{
			//encrypted data was padded with zeros
			if ( nType == 0 || GetSize() > 0 || nTotalLen > 1024 || nValLen > 1024 )
			{
				nIndex += nBlockSize;
#ifdef _DEBUG_LOG_
				sprintf( szDebug, "nIndex = %ld nLen=%ld\r\n", nIndex, lLen );
				Log( szDebug );
#endif

			}
			else
			{
#ifdef _DEBUG_LOG_
	Log( "LV3 " );
#endif

				//or there was an error during decryption
				//Anyway - just leave!
				//nIndex += nBlockSize;
				//bRes = false;
				break;
			}
		}
	}
	
	return GetSize();//returns number of read values
}

/*
	NOTE: Returns data in the form of:
	(Bytes0-3)	TotalLen
	(Bytes4-7)	Type
	(Bytes8-11)	Data length
*/
BYTE* CValue::GetData( INT* pLen ) const
{
	BYTE* p = NULL;
	INT nIntLen = sizeof(INT);
	INT nValueLen = 0;
	INT nNameLen = (INT)MYSTRLEN( m_szName ) * sizeof( MYCHAR ) + sizeof( MYCHAR );
	INT nTotalLen = 0;
	
	switch( m_nType )
	{
	case TYPE_INT:
	case TYPE_DATE:
		nValueLen = nIntLen;
		break;

	case TYPE_INT16:
		nValueLen = 2;
		break;
		
	case TYPE_BYTE:
		nValueLen = 1;
		break;
	
	case TYPE_INT64:
		nValueLen = 8;
		break;
		
	case TYPE_DOUBLE:
		nValueLen = sizeof( double );
		break;
		
	case TYPE_STRING:
		nValueLen = (INT)MYSTRLEN( (MYCHAR*)m_pValue )*sizeof( MYCHAR) + sizeof( MYCHAR );
		break;
		
	case TYPE_BINARY:
		{
			INT* pn = (INT*)m_pValue;//first byte is data length!
			nValueLen = *pn + nIntLen;
		}
		break;
		
	default:
		*pLen = 0;
		return NULL;
	}

	nTotalLen = nIntLen + nIntLen + nIntLen + nValueLen + nNameLen;
	p = (BYTE*)malloc( nTotalLen );

	memcpy( p, &nTotalLen, nIntLen );			//first integer is TOTAL LENGTH
	memcpy( p+nIntLen,   &m_nType, nIntLen );	//second integer is TYPE
	memcpy( p+nIntLen*2, &nValueLen, nIntLen );	//third integer is DATA LENGTH
	memcpy( p+nIntLen*3, m_pValue, nValueLen ); //the value
	
	MYSTRCPY( (MYCHAR*)(p + nIntLen*3 + nValueLen), (const MYCHAR*)m_szName );//Name

	*pLen = nTotalLen;	
	return p;
}

const BYTE* CValue::GetBinaryValue( INT* pLen ) const
{
	*pLen = 0;
	
	//this method is only valid for BINARY data
	if ( this->GetType() != TYPE_BINARY ) return NULL;
	
	const BYTE* pData = (const BYTE*)this->GetValue();
	if ( pData == NULL ) return NULL;
	
	memcpy( pLen, pData, sizeof( INT ) );
	return (&pData[sizeof(INT)]);
}

/*
	Writes PDK document header (Dataset) as defined in DocInfoEx structure.
	
	Arguments:
		fh			FileHandle.
		pDocExInfo	Header data
		pEncryp		Encryption keys
		
	Returns:
		-9			Unable to encrypt header.
		0<			Number of bytes written (OK)
		
*/
INT CFiler::WriteDocumentHeader( INT fh, PDOCEX_INFO pDocExInfo, PENCRYP pEncryp )
{
	BYTE*	pTemp = new BYTE[32 + sizeof(INT)];
	
	AddValue( TYPE_INT,			L"ID",				(void*)&pDocExInfo->dwDocID );
	AddValue( TYPE_STRING,		L"DocName",			(void*)&pDocExInfo->szDocName );
	AddValue( TYPE_STRING,		L"DocDescription",	(void*)&pDocExInfo->szDocDesc );
	AddValue( TYPE_INT,			L"PubDate",			(void*)&pDocExInfo->dwPubDate );
	AddValue( TYPE_DOUBLE,		L"Version",			(void*)&pDocExInfo->dVersion );
	AddValue( TYPE_INT,			L"UploadDate",		(void*)&pDocExInfo->dwUploadDate );
	AddValue( TYPE_INT,			L"DocSize",			(void*)&pDocExInfo->dwDocSize );
	AddValue( TYPE_STRING,		L"ISBN",			(void*)&pDocExInfo->szISBN );
	AddValue( TYPE_INT,			L"OwnerID",			(void*)&pDocExInfo->dwOwnerID );
	AddValue( TYPE_INT,			L"CreatorID",		(void*)&pDocExInfo->dwCreatorID );
	AddValue( TYPE_INT64,		L"DocState",		(void*)&pDocExInfo->exlDocState );
	AddValue( TYPE_INT,			L"Expires",			(void*)&pDocExInfo->dwExpires );
//	AddValue( TYPE_BINARY,		L"USK",				PrepareBin( pDocExInfo->byUSK,  32, pTemp ) );
//	AddValue( TYPE_BINARY,		L"HCKD",			PrepareBin( pDocExInfo->byHCKD, 16, pTemp ) );
//	AddValue( TYPE_BINARY,		L"HCKS",			PrepareBin( pDocExInfo->byHCKS, 16, pTemp ) );
	AddValue( TYPE_STRING,		L"DOCPWD",			(void*)&pDocExInfo->szDocPwd );
	AddValue( TYPE_INT,			L"StartDate",		(void*)&pDocExInfo->dwStartDate );
	AddValue( TYPE_INT,			L"ExpiryDate",		(void*)&pDocExInfo->dwExpiryDate );
	AddValue( TYPE_INT,			L"OpenCount",		(void*)&pDocExInfo->dwOpeningCount );
	AddValue( TYPE_INT,			L"PrintCount",		(void*)&pDocExInfo->dwPrintingCount );
	AddValue( TYPE_INT,			L"PrintPages",		(void*)&pDocExInfo->dwPagesToPrint );
	AddValue( TYPE_INT16,		L"AskPassword",		(void*)&pDocExInfo->sAskPassword );
	AddValue( TYPE_INT16,		L"MustBeOnline",	(void*)&pDocExInfo->sMustBeOnline );
	AddValue( TYPE_INT16,		L"EnableClipboard",	(void*)&pDocExInfo->sEnableClipboard );
	AddValue( TYPE_INT16,		L"BlockGrabbers",	(void*)&pDocExInfo->sBlockGrabbers );
	AddValue( TYPE_INT16,		L"RelaxedPriting",	(void*)&pDocExInfo->sRelaxedPrinting );
	AddValue( TYPE_INT,			L"ExpiresAfter",	(void*)&pDocExInfo->nExpiresAfter );
	AddValue( TYPE_INT,			L"TotalSize",		(void*)&pDocExInfo->dwTotalSize );
	AddValue( TYPE_INT16,		L"Initialised",		(void*)&pDocExInfo->sInitialised );
	AddValue( TYPE_INT,			L"UserID",			(void*)&pDocExInfo->dwUserID );
	
	AddValue( TYPE_STRING,		L"FontName",		(void*)&pDocExInfo->szFontName );
	AddValue( TYPE_INT16,		L"FontStyle",		(void*)&pDocExInfo->sFontStyle );
	AddValue( TYPE_INT16,		L"FontSize",		(void*)&pDocExInfo->sFontSize );
	AddValue( TYPE_INT,			L"FontColour",		(void*)&pDocExInfo->nFontColour );
	AddValue( TYPE_INT,			L"Direction",		(void*)&pDocExInfo->nDirection );
	AddValue( TYPE_INT,			L"FromPage",		(void*)&pDocExInfo->nFromPage );
	AddValue( TYPE_INT,			L"ToPage",			(void*)&pDocExInfo->nToPage );
	AddValue( TYPE_INT16,		L"Opacity",			(void*)&pDocExInfo->sOpacity );
	AddValue( TYPE_INT,			L"Vert",			(void*)&pDocExInfo->nVert );
	AddValue( TYPE_INT,			L"Hor",				(void*)&pDocExInfo->nHor );
	AddValue( TYPE_STRING,		L"WMText",			(void*)&pDocExInfo->szWMText );
	AddValue( TYPE_INT16,		L"WMType",			(void*)&pDocExInfo->sWMType );
	
	AddValue( TYPE_INT,			L"AllowedUsers",			(void*)&pDocExInfo->nAllowedUsers );
	BYTE* pUsers = NULL;
	if ( pDocExInfo->nAllowedUsers > 0 )
	{
		INT nL = pDocExInfo->nAllowedUsers*sizeof(INT);
		pUsers = new BYTE[ nL + sizeof(INT) ];
		AddValue( TYPE_BINARY, L"Users", PrepareBin( (BYTE*)pDocExInfo->pnUsers, nL, pUsers ) );
	}
	
	
	INT nLen = (INT)SaveData( fh, pEncryp );

	delete [] pTemp;
	if ( pUsers != NULL ) delete [] pUsers;
	
	return nLen;//return length of document header
}

long CFiler::SaveData( INT fh, PENCRYP pEncryp )
{
	INT nLen = 0;
	BYTE* pData = GetData( &nLen );
	long nWritten = -1;
		
	if ( pEncryp == NULL || pEncryp->pHeaderKey == NULL || pEncryp->pHeaderIV == NULL )
	{
		//no encryption
		//13.02.2012 - added scrambling of unencrypted buffer
		ScrambleBuffer( pData, nLen, CFiler::key1, 32 );
		///
		nWritten = write( fh, pData, nLen );//write document header
		//nWritten = _write( fh, pData, nLen );//write document header
	}
	else
	{
		//need to encrypt doc header
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pHeaderKey, (const char*)pEncryp->pHeaderIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		BYTE* pNewData = align( pData, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = (nLen != nNewLen);
		
		nLen = nNewLen;
		BYTE* pEnc = (BYTE*)malloc(  nLen );
		try{
			oRijndael.Encrypt( (const char*)pNewData, (char*)pEnc, nLen, CRijndael::ECB );
			nWritten = write( fh, pEnc, nLen );
		} catch (exception& ex ) {
			free( pData );
			free( pEnc );
			if ( bFree ) delete [] pNewData;
			return -9;
		}

		if ( bFree ) delete [] pNewData;
		free( pData );
		free( pEnc );
	}
	
	return nWritten;
}

BYTE* CFiler::PrepareBin( BYTE* pOriginal, INT nLen, BYTE* pTemp ) const
{
	if ( pOriginal == NULL )
	{
		nLen = 0;
		memcpy( pTemp, &nLen, sizeof( INT ) );
		return pTemp;
	}
	
	memcpy( pTemp, &nLen, sizeof( INT ) );
	for( INT i=0; i<nLen; i++ )
	{
		pTemp[ sizeof( INT ) + i ] = pOriginal[i];
	}
	return pTemp;
}

BYTE* CFiler::GetBin( const BYTE* pSource, BYTE* pDest, INT nLen ) const
{
	if ( pSource == NULL )
	{
		memset( pDest, 0, nLen );
		return pDest;
	}
	
	INT n = 0;
	memcpy( &n, pSource, sizeof( INT ) );
	if ( n > nLen ) n=nLen;
	
	for( INT i=0; i<nLen; i++ )
	{
		pDest[i] = pSource[ sizeof(INT) + i ];
	}
	
	return pDest;
}

/*
	Writes (encrypted) PDF document data into previously prepared PDK file.
	
	Arguments:
		fh				File handle.
		szDocName		PDF file name.
		pEncryp			Encryption keys
		
	Returns:
		-10				Unable to open PDF document.
		-11				Unable to get PDF file size.
		-12				Unable to read PDF document.
		-13				Unable to encrypt PDF document.
		0<				Size of written document.
		
*/
long CFiler::WriteDocument( INT fh, char* szDocName, PENCRYP pEncryp )
{
	INT fhDoc = 0;
/*	errno_t err = _wsopen_s( &fhDoc, szDocName, _O_RDONLY|_O_BINARY, _SH_DENYNO, 0 );
	if( err != 0 )
	{
		return -10;
	}
*/
	fhDoc = open( szDocName, O_RDONLY );
    if ( fhDoc < 0 ) return -10;
    
	long lLen = (long)lseek( fhDoc, 0L, SEEK_END );
	
	if ( lLen == -1 )
	{
		close( fhDoc );
		return -11;
	}

	if ( -1 == lseek( fhDoc, 0L, SEEK_SET ) )
	{
		close( fhDoc );
		return -11;
	}

	long nRead = 0;
	BYTE* p = (BYTE*)malloc(  lLen );
	
	if( ( nRead = read( fhDoc, p, lLen ) ) < 0 )
	{
		nRead = errno;
		free( p );
		return -12;
	}

	close( fhDoc );
	
	if ( pEncryp == NULL || pEncryp->pDataKey == NULL || pEncryp->pDataIV == NULL )
	{
		//no encryption
		//13.02.2012 - added scrambling of unencrypted buffer
		ScrambleBuffer( p, lLen, CFiler::key2, 32 );
		///
		long nWritten = write( fh, p, lLen );
		free( p );
		return nWritten;
	}
	else
	{
		//use encryption before saving the file
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pDataKey, (const char*)pEncryp->pDataIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		INT nLen = (INT)lLen;
		BYTE* pNewData = align( p, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = ( nLen != nNewLen);
		
		nLen = nNewLen;

		BYTE* pEnc = (BYTE*)malloc(  nLen );
		long nWritten = 0;
		try{
			oRijndael.Encrypt( (const char*)pNewData, (char*)pEnc, nLen, CRijndael::ECB );
			nWritten = write( fh, pEnc, nLen );
		} catch (exception& ex ) {
			free( p );
			free( pEnc );
			if ( bFree ) delete [] pNewData;
			return -13;
		}
		free( p );
		free( pEnc );
		if ( bFree ) delete [] pNewData;
		
		return nWritten;
	}
}

void CFiler::Initialise( PDOCEX_INFO pDoc ) const
{
	for( INT i=0; i<128; i++ ) pDoc->byAdditional[i] = 0x00;
//	for( INT i=0; i<16; i++ ) pDoc->byHCKD[i] = pDoc->byHCKS[i] = 0x00;
//	for( INT i=0; i<32; i++ ) pDoc->byUSK[i] = 0x00;
	
	pDoc->dVersion = 0;
	pDoc->dwCreatorID = 0;
	pDoc->dwDocID = 0;
	pDoc->dwDocSize = 0;
	pDoc->dwExpires = 0;
	pDoc->dwExpiryDate = 0;
	pDoc->dwOpeningCount = 0;
	pDoc->dwOwnerID = 0;
	pDoc->dwPagesToPrint = 0;
	pDoc->dwPrintingCount = 0;
	pDoc->dwPubDate = 0;
	pDoc->dwStartDate = 0;
	pDoc->dwTotalSize = 0;
	pDoc->dwUploadDate = 0;
	pDoc->dwUserID = 0;
	pDoc->exlDocState = 0;
	pDoc->nDirection = 0;
	pDoc->nExpiresAfter = 0;
	pDoc->nFontColour = 0;
	pDoc->nFromPage = 0;
	pDoc->nHor = 0;
	pDoc->nVert = 0;
	pDoc->nToPage = 0;
	pDoc->sAskPassword = 0;
	pDoc->sBlockGrabbers = 0;
	pDoc->sRelaxedPrinting = 0;
	pDoc->sEnableClipboard = 0;
	pDoc->sFontSize = 0;
	pDoc->sFontStyle[0] = 0;
	pDoc->sInitialised = 0;
	pDoc->sMustBeOnline = 0;
	pDoc->sOpacity = 0;
	pDoc->sWMType = 0;
	pDoc->szDiskID[0] = 0x00;
	pDoc->szDocDesc[0] = 0x00;
	pDoc->szDocName[0] = 0;
	pDoc->szDocPwd[0] = 0;
	pDoc->szFontName[0] = 0;
	pDoc->szFullFileName[0] = 0;
	pDoc->szISBN[0] = 0;
	pDoc->szOSID[0] = 0;
	pDoc->szWMText[0] = 0;
	
	pDoc->nAllowedUsers = 0;
	pDoc->pnUsers = NULL;
}

//BYTE* CFiler::DebugAllocMem( INT n, unsigned INT* pn ) const
/*
	Reads the actual document data from already opened file (file handle:fh) from offset (nOffset). Data is
	placed in previously allocated buffer (pData/nDataLen).
	If the file is encrypted, all the keys are in pEncryp structure (pDataIV and pDataKey)
	
	Arguments:
		fh			File handle.
		nOffset		Offset from the begining of the opened file where data starts.
		pData		Data buffer for read data (decrypted)
		nDataLen	Size of pData buffer.
		pEncryp		Encryption keys structure.
		
	Returns:
		-15			Can't position file pointer.
		-16			Can't read data from the file.
		-17			Unable to decrypt data.
		0			OK
		
*/
INT CFiler::LoadDocument( INT fh, INT nOffset, BYTE* pData, INT nDataLen, PENCRYP pEncryp ) const
{
	if ( lseek( fh, nOffset, SEEK_SET ) == -1 )
	{
		close( fh );
		return -15;
	}
	
	if ( read( fh, pData, nDataLen ) < nDataLen )
	{
		close( fh );
		return -16;
	}
	close( fh );
	
	if ( pEncryp != NULL && pEncryp->pDataIV != NULL && pEncryp->pDataKey != NULL )
	{
		//must decrypt data
		//decrypt header
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pDataKey, (const char*)pEncryp->pDataIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		INT nLen = nDataLen;
		BYTE* pNewData = align( pData, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = ( nLen != nNewLen );

		BYTE* pDec = (BYTE*)malloc( nNewLen );
		try{
			oRijndael.Decrypt( (const char*)pNewData, (char*)pDec, nNewLen, CRijndael::ECB );
			
			memcpy( pNewData, pDec, nNewLen );
			free( pDec );
			if ( bFree ) delete [] pNewData;
		} catch (exception& ex ) {
			if ( bFree ) delete [] pNewData;
			free( pDec );
			return -17;
		}
	}
	else
	{
		//13.02.2012 - added scrambling of unencrypted buffer
		ScrambleBuffer( pData, nDataLen, CFiler::key2, 32 );
		///
	}
	return 0;
}

INT CFiler::LoadDocumentFromData( BYTE* pMainData, UINT nMainDataLen, INT nOffset, BYTE* pData, INT nDataLen, PENCRYP pEncryp, bool bSelfAuth  ) const
{
	memcpy( pData, &pMainData[nOffset], nDataLen );//copy from main data buffer to caller-allocated buffer
	
	if ( pEncryp != NULL && pEncryp->pDataIV != NULL && pEncryp->pDataKey != NULL )
	{
		//must decrypt data
		//decrypt header
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pDataKey, (const char*)pEncryp->pDataIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		INT nLen = nDataLen;
		BYTE* pNewData = align( pData, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = ( nLen != nNewLen );
		
		BYTE* pDec = (BYTE*)malloc( nNewLen );
		try{
			oRijndael.Decrypt( (const char*)pNewData, (char*)pDec, nNewLen, CRijndael::ECB );
			
			memcpy( pNewData, pDec, nNewLen );
			free( pDec );
			if ( bFree ) delete [] pNewData;
		} catch (exception& ex ) {
			if ( bFree ) delete [] pNewData;
			free( pDec );
			return -17;
		}
	}
	else
	{
		//13.02.2012 - added scrambling of unencrypted buffer
		if ( bSelfAuth )
			ScrambleBuffer( pData, nDataLen, CFiler::key1, 32 );
		else
			ScrambleBuffer( pData, nDataLen, CFiler::key2, 32 );
		///
	}
	
	return 0;
}

/*

	Loads a PDK file and reads its file and document headers. Populates DOCEX_INFO structure on exit.
	
	Arguments:
		pDocExInfo	Pointer to the document info structure that will be populated after successful header read.
		szFile		File name of a PDK file.
		puDocLen	Length of embedded document. (output)
		pnOffset	Offset in bytes where the actual document data begins. (output)
		pnPDKVersion Version of Drumlin PDK file (Added on 04/07/2011)
		pEncryp		Encryption keys.
		
	Return codes:
		-10						Unable to open PDK file
		-11						Can't find file len
		<negative value>		Unable to read file header (see ReadHeader)
		0<						File handle of the successfully opened file.
		
*/
INT CFiler::LoadHeader( PDOCEX_INFO pDocExInfo, const char* szFile, UINT* puDocLen, INT* pnOffset, INT* pnPDKVersion, PENCRYP pEncryp )
{
	INT fh = 0;
	
	if ( puDocLen != NULL )
		*puDocLen = 0;
	if ( pnOffset != NULL )
		*pnOffset = 0;
	if ( pnPDKVersion != 0 )
		*pnPDKVersion = 0;
	
/*	errno_t err = _wsopen_s( &fh, szFile, _O_RDONLY|_O_BINARY, _SH_DENYNO, 0 );
	if( err != 0 )
	{
		//unable to open file.
		return -10;
	}
*/
    fh = open( szFile, O_RDONLY );
    if ( fh < 0 ) return -10;
    
	//retrieve file length
	long lFileLen = (long)lseek( fh, 0L, SEEK_END );
	
	if ( lFileLen == -1 )
	{
		close( fh );
		return -11;
	}

	if ( -1 == lseek( fh, 0L, SEEK_SET ) )
	{
		close( fh );
		return -11;
	}
	
	INT nHeaderLen = 0;
	INT nRes = ReadHeader( fh, pDocExInfo, &nHeaderLen, pnPDKVersion, pEncryp );
	
	if ( nRes < 0 )
	{	//unable to read header
		close( fh );
		return nRes;
	}

	UINT nBytes = (UINT)(lFileLen - nHeaderLen);
	if ( puDocLen != NULL )
		*puDocLen = nBytes;
	if ( pnOffset != NULL )
		*pnOffset = nHeaderLen;
		
	return fh;
}

INT CFiler::LoadHeaderFromData( PDOCEX_INFO pDocExInfo, BYTE* data, UINT nDataLen, UINT* puDocLen, INT* pnOffset, INT* pnPDKVersion, PENCRYP pEncryp )
{
	if ( puDocLen != NULL )
		*puDocLen = 0;
	if ( pnOffset != NULL )
		*pnOffset = 0;
	if ( pnPDKVersion != 0 )
		*pnPDKVersion = 0;
	
	INT nHeaderLen = 0;
	INT nRes = ReadHeaderFromData( data, nDataLen, pDocExInfo, &nHeaderLen, pnPDKVersion, pEncryp );
	
	if ( nRes < 0 )
	{	//unable to read header
		return nRes;
	}
    
	UINT nBytes = (UINT)(nDataLen - nHeaderLen);
	if ( puDocLen != NULL )
		*puDocLen = nBytes;
	if ( pnOffset != NULL )
		*pnOffset = nHeaderLen;
    
	return 1;
}

/*
	Reads file and document headers.
	
	Returns 0 if successful, or a negative value otherwise.
		-18		Unable to read file
		-19		Wrong file format
		-20		Can't read dataset
		-21		Unable to load dataset
		-22		Problem with encryption
		-23		Wrong DRM (PDK) file format
		
	Also returns offset to the real PDF data in pnDocumentHeaderLen parameter.
	
*/
INT CFiler::ReadHeader( INT fh, PDOCEX_INFO pDocExInfo, INT* pnDocumentHeaderLen, INT* pnPDKVersion, PENCRYP pEncryp )
{
	BYTE* pHeader = new BYTE[ HEADER_LEN ];
	INT nVersion  = 0;
	INT nOffset   = 0;

	*pnDocumentHeaderLen = 0;
	
	Initialise( pDocExInfo );
	
	if ( read( fh, pHeader, HEADER_LEN ) < HEADER_LEN )
	{	//unable to read header
		delete [] pHeader;
		return -18;
	}
	
	if ( pHeader[0] != '{' || pHeader[1] != 'D' || pHeader[2] != 'R' || pHeader[3] != 'M' || pHeader[4] != 'P' ||
			pHeader[5] != 'D' || pHeader[6] != 'K' || pHeader[7] != '}' )
	{	//wrong file format
		delete [] pHeader;
		return -19;
	}

	memcpy( &nVersion, &pHeader[8], sizeof( INT ) );//get file version
	memcpy( &nOffset,  &pHeader[12],sizeof( INT ) );//get offset to real PDF data
	*pnDocumentHeaderLen = nOffset;//I'll need this offset in the caller
	
	*pnPDKVersion = nVersion; //retrieve PDK file version for the caller (04/07/2011)
	
	for( INT i=0; i<128; i++ )
	{	//get additional bytes
		pDocExInfo->byAdditional[i] = pHeader[16 + i];
	}
	
	delete [] pHeader;//finished with file header
	pHeader = NULL;
	
	//read the dataset
	INT nDSLen = nOffset - HEADER_LEN;
	
	if ( nDSLen < 100 || nOffset < 100 || nDSLen > 10240 || nOffset > 10240 )
	{
		//it's probably wrong format of DRM file
		return -23;
	}
	pHeader = (BYTE*)malloc( nDSLen );
	if ( read( fh, pHeader, nDSLen ) < nDSLen )
	{	//unable to read DataSet
		free( pHeader );
		return -20;
	}

	if ( pEncryp != NULL && pEncryp->pHeaderIV != NULL && pEncryp->pHeaderKey != NULL )
	{
		//decrypt header
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pHeaderKey, (const char*)pEncryp->pHeaderIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		INT nLen = nDSLen;
		BYTE* pNewHeader = align( pHeader, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = ( nLen != nNewLen );

		BYTE* pDec = (BYTE*)malloc( nNewLen );
		try{
			oRijndael.Decrypt( (const char*)pNewHeader, (char*)pDec, nNewLen, CRijndael::ECB );
			free( pHeader );
			if ( bFree ) delete [] pNewHeader;
			pHeader = pDec;
			nDSLen = nNewLen;
		} catch (exception& ex ) {
			free( pHeader );
			if ( bFree ) delete [] pNewHeader;
			free( pDec );
			return -22;
		}
	}
	else
	{	
		//13.02.2012 - added scrambling of unencrypted buffer
		ScrambleBuffer( pHeader, nDSLen, CFiler::key1, 32 );
		///
	}
	
	if ( LoadValues( pHeader, nDSLen, 32 ) == 0)
	{	//error while loading data set
		free( pHeader );
		return -21;
	}
	free( pHeader );
	pHeader = NULL;
	
	
	PopulateDiex( pDocExInfo );
	

	//everything is OK if I got so far	
	return 0;
}

void CFiler::PopulateDiex( PDOCEX_INFO pDocExInfo ) const
{
	//Finished with the file header - go and read the document header
	CValue* pValue = NULL;
	
#ifdef _WINDOWS
	pValue = GetValue( L"ID" );
#else
	pValue = GetValueA( "ID" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwDocID = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"DocName" );
#else
	pValue = GetValueA( "DocName" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szDocName, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"DocDescription" );
#else
	pValue = GetValueA( "DocDescription" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szDocDesc, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"PubDate" );
#else
	pValue = GetValueA( "PubDate" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwPubDate = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Version" );
#else
	pValue = GetValueA( "Version" );
#endif
	if ( pValue != NULL ) 
	{
		double* p = (double*)pValue->GetValue();
		pDocExInfo->dVersion = *p;
	}
	
#ifdef _WINDOWS
	pValue = GetValue( L"UploadDate" );
#else
	pValue = GetValueA( "UploadDate" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwUploadDate = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"DocSize" );
#else
	pValue = GetValueA( "DocSize" );
#endif
	
	if ( pValue != NULL ) pDocExInfo->dwDocSize = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"ISBN" );
#else
	pValue = GetValueA( "ISBN" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szISBN, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"OwnerID" );
#else
	pValue = GetValueA( "OwnerID" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwOwnerID = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"CreatorID" );
#else
	pValue = GetValueA( "CreatorID" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwCreatorID = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"DocState" );
#else
	pValue = GetValueA( "DocState" );
#endif
	if ( pValue != NULL )
	{
		EXTRALONG* p = (EXTRALONG*)pValue->GetValue();
		pDocExInfo->exlDocState = *p;
	}
	
#ifdef _WINDOWS
	pValue = GetValue( L"Expires" );
#else
	pValue = GetValueA( "Expires" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwExpires = (INT)(*(INT*)(pValue->GetValue()));
	
	//	pValue = GetValue( L"USK" );
	//	if ( pValue != NULL ) GetBin( pValue->GetValue(), pDocExInfo->byUSK, 32 );
	
	//	pValue = GetValue( L"HCKD" );
	//	if ( pValue != NULL ) GetBin( pValue->GetValue(), pDocExInfo->byHCKD, 16 );
	
	//	pValue = GetValue( L"HCKS" );
	//	if ( pValue != NULL ) GetBin( pValue->GetValue(), pDocExInfo->byHCKS, 16 );
	
#ifdef _WINDOWS
	pValue = GetValue( L"DocPwd" );
#else
	pValue = GetValueA( "DocPwd" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szDocPwd, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"StartDate" );
#else
	pValue = GetValueA( "StartDate" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwStartDate = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"ExpiryDate" );
#else
	pValue = GetValueA( "ExpiryDate" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwExpiryDate = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"OpenCount" );
#else
	pValue = GetValueA( "OpenCount" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwOpeningCount = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"PrintCount" );
#else
	pValue = GetValueA( "PrintCount" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwPrintingCount = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"PrintPages" );
#else
	pValue = GetValueA( "PrintPages" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwPagesToPrint = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"AskPassword" );
#else
	pValue = GetValueA( "AskPassword" );
#endif
	if ( pValue != NULL ) pDocExInfo->sAskPassword = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"MustBeOnline" );
#else
	pValue = GetValueA( "MustBeOnline" );
#endif
	if ( pValue != NULL ) pDocExInfo->sMustBeOnline = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"EnableClipboard" );
#else
	pValue = GetValueA( "EnableClipboard" );
#endif
	if ( pValue != NULL ) pDocExInfo->sEnableClipboard = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"BlockGrabbers" );
#else
	pValue = GetValueA( "BlockGrabbers" );
#endif
	if ( pValue != NULL ) pDocExInfo->sBlockGrabbers = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"ExpiresAfter" );
#else
	pValue = GetValueA( "ExpiresAfter" );
#endif
	if ( pValue != NULL ) pDocExInfo->nExpiresAfter = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"TotalSize" );
#else
	pValue = GetValueA( "TotalSize" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwTotalSize = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Initialised" );
#else
	pValue = GetValueA( "Initialised" );
#endif
	if ( pValue != NULL ) pDocExInfo->sInitialised = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"UserID" );
#else
	pValue = GetValueA( "UserID" );
#endif
	if ( pValue != NULL ) pDocExInfo->dwUserID = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"FontName" );
#else
	pValue = GetValueA( "FontName" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szFontName, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"FontStyle" );
#else
	pValue = GetValueA( "FontStyle" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->sFontStyle, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"FontSize" );
#else
	pValue = GetValueA( "FontSize" );
#endif
	if ( pValue != NULL ) pDocExInfo->sFontSize = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"FontColour" );
#else
	pValue = GetValueA( "FontColour" );
#endif
	if ( pValue != NULL ) pDocExInfo->nFontColour = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Direction" );
#else
	pValue = GetValueA( "Direction" );
#endif
	if ( pValue != NULL ) pDocExInfo->nDirection = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"FromPage" );
#else
	pValue = GetValueA( "FromPage" );
#endif
	if ( pValue != NULL ) pDocExInfo->nFromPage = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"ToPage" );
#else
	pValue = GetValueA( "ToPage" );
#endif
	if ( pValue != NULL ) pDocExInfo->nToPage = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Opacity" );
#else
	pValue = GetValueA( "Opacity" );
#endif
	if ( pValue != NULL ) pDocExInfo->sOpacity = (short)(*(short*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Vert" );
#else
	pValue = GetValueA( "Vert" );
#endif
	if ( pValue != NULL ) pDocExInfo->nVert = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"Hor" );
#else
	pValue = GetValueA( "Hor" );
#endif
	if ( pValue != NULL ) pDocExInfo->nHor = (INT)(*(INT*)(pValue->GetValue()));
	
#ifdef _WINDOWS
	pValue = GetValue( L"WMText" );
#else
	pValue = GetValueA( "WMText" );
#endif
	if ( pValue != NULL ) MYSTRCPY( pDocExInfo->szWMText, (MYCHAR*)pValue->GetValue() );
	
#ifdef _WINDOWS
	pValue = GetValue( L"WMType" );
#else
	pValue = GetValueA( "WMType" );
#endif
	if ( pValue != NULL ) pDocExInfo->sWMType = (short)(*(short*)(pValue->GetValue()));
	
	pDocExInfo->nAllowedUsers = 0;
	pDocExInfo->pnUsers = NULL;
	
#ifdef _WINDOWS
	pValue = GetValue( L"AllowedUsers" );
#else
	pValue = GetValueA( "AllowedUsers" );
#endif
	if ( pValue != NULL ) pDocExInfo->nAllowedUsers = (INT)(*(INT*)(pValue->GetValue()));
	
	if ( pDocExInfo->nAllowedUsers > 0 )
	{
#ifdef _WINDOWS
		pValue = GetValue( L"Users" );
#else
		pValue = GetValueA( "Users" );
#endif
		if ( pValue == NULL )
		{
			pDocExInfo->nAllowedUsers = 0;
			pDocExInfo->pnUsers = NULL;
		}
		else
		{
			INT nLen = 0;
			const BYTE* p = pValue->GetBinaryValue( &nLen );
			if ( p == NULL )
			{
				pDocExInfo->nAllowedUsers = 0;
				pDocExInfo->pnUsers = NULL;
			}
			else
			{
				DWORD* pUsers = new DWORD[pDocExInfo->nAllowedUsers];
				
				for( INT i=0,j=0; i<pDocExInfo->nAllowedUsers && j < nLen; i++ )
				{
					pUsers[i] = 0;
					memcpy( &pUsers[i], &p[j], sizeof(INT) );
					j += sizeof(INT);
				}
				
				pDocExInfo->pnUsers = pUsers;
			}
		}
	}
}

INT CFiler::ReadHeaderFromData( BYTE* data, UINT nDataLen, PDOCEX_INFO pDocExInfo, INT* pnDocumentHeaderLen, INT* pnPDKVersion, PENCRYP pEncryp )
{
	INT nVersion  = 0;
	INT nOffset   = 0;
    
	*pnDocumentHeaderLen = 0;
	
	Initialise( pDocExInfo );
	
    BYTE* pHeader = data;
    
	if ( pHeader[0] != '{' || pHeader[1] != 'D' || pHeader[2] != 'R' || pHeader[3] != 'M' || pHeader[4] != 'P' ||
        pHeader[5] != 'D' || pHeader[6] != 'K' || pHeader[7] != '}' )
	{	//wrong file format
		return -19;
	}
    
	memcpy( &nVersion, &pHeader[8], sizeof( INT ) );//get file version
	memcpy( &nOffset,  &pHeader[12],sizeof( INT ) );//get offset to real PDF data
	*pnDocumentHeaderLen = nOffset;//I'll need this offset in the caller
	
	*pnPDKVersion = nVersion; //retrieve PDK file version for the caller (04/07/2011)
	
	for( INT i=0; i<128; i++ )
	{	//get additional bytes
		pDocExInfo->byAdditional[i] = pHeader[16 + i];
	}
	
	pHeader = &data[HEADER_LEN];
	
	//read the dataset
	INT nDSLen = nOffset - HEADER_LEN;
	
	if ( nDSLen < 100 || nOffset < 100 || nDSLen > 10240 || nOffset > 10240 )
	{
		//it's probably wrong format of DRM file
		return -23;
	}

	if ( pEncryp != NULL && pEncryp->pHeaderIV != NULL && pEncryp->pHeaderKey != NULL )
	{
		//decrypt header
		CRijndael oRijndael;
		oRijndael.MakeKey( (const char*)pEncryp->pHeaderKey, (const char*)pEncryp->pHeaderIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
		
		INT nNewLen = 0;
		INT nLen = nDSLen;
		BYTE* pNewHeader = align( pHeader, nLen, pEncryp->nBlockSize, &nNewLen );
		bool bFree = ( nLen != nNewLen );
        
		BYTE* pDec = (BYTE*)malloc( nNewLen );
		
		try
		{
			oRijndael.Decrypt( (const char*)pNewHeader, (char*)pDec, nNewLen, CRijndael::ECB );
			if ( bFree ) delete [] pNewHeader;
			pHeader = pDec;
			nDSLen = nNewLen;
		}
		catch (exception& ex ) 
		{
			if ( bFree ) delete [] pNewHeader;
			free( pDec );
			return -22;
		}
	}
	else
	{	
		//13.02.2012 - added scrambling of unencrypted buffer
		ScrambleBuffer( pHeader, nDSLen, CFiler::key1, 32 );
		///
	}
    
	if ( LoadValues( pHeader, nDSLen, 32 ) == 0)
	{	//error while loading data set
		return -21;
	}
	
	pHeader = NULL;
	
	//Finished with the file header - go and read the document header
	PopulateDiex( pDocExInfo );
    
	//everything is OK if I got so far	
	return 0;
}
/*

	Saves a PDF file, populates the header with DocExInfo structure members and
	(optionally) encrypts the header with pEncryp->pHeaderKey and data with pEncryp->pDataKey
	
	Arguments:
		pDocExInfo		Structure with all the data required for the PDK header
		szFile			PDK file name.
		pEncryp			Encryption keys (optional)
		pRawDocData		Data which doesn't have to be encrypted (optional)
		nDataLen		Length of the raw data (optional)
		
	Returns:
		-5				Unable to create document.
		-6				Unable to write filetype marker etc.
		-9				Unable to encrypt header.
		-10				Unable to open PDF document.
		-11				Unable to get PDF file size.
		-12				Unable to read PDF document.
		-13				Unable to encrypt PDF document.
		0<				Size of written document.

*/
INT CFiler::SaveDocument( PDOCEX_INFO pDocExInfo, const char* szFile, PENCRYP pEncryp, BYTE* pRawDocData, INT nDataLen )
{
	INT fh = 0;
	
	DeleteAll();
	
	//open file
/*	errno_t err = _wsopen_s( &fh, szFile, _O_RDWR|_O_CREAT|_O_TRUNC|_O_BINARY, _SH_DENYNO, _S_IREAD | _S_IWRITE );
	if( err != 0 )
	{
		//unable to create document
		return -5;
	}
*/
	fh = open( szFile, O_RDWR|O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR );
    if ( fh < 0 ) return -5;
    
	//write file header
	if ( -1 == write( fh, "{DRMPDK}", 8 ) )
	{
		return -6;
	}
    
	INT nOffset = 0;
	INT nPDK_FileVersion = PDK_VERSION;
	if ( -1 == write( fh, &nPDK_FileVersion, sizeof(INT) ) )
	{
		return -6;
	}

	//placeholder for offset to data
	if ( -1 == write( fh, &nOffset, sizeof(INT) ) )
	{
		return -6;
	}
	
	if ( -1 == write( fh, pDocExInfo->byAdditional, 128 ) )
	{
		return -6;
	}

	//write DOCUMENT HEADER
	INT nDocHeaderLen = WriteDocumentHeader( fh, pDocExInfo, pEncryp );
	if ( nDocHeaderLen < 0 ) return nDocHeaderLen;
	
	nOffset = HEADER_LEN + nDocHeaderLen;
	
	//write Document itself
	INT nRes = 0;
	
	if ( pRawDocData != NULL && nDataLen > 0 )
	{
		//if raw data is here - use it and don't encrypt it if pEncryp data members are not set.
		if ( pEncryp != NULL && pEncryp->pDataKey != NULL && pEncryp->pDataIV != NULL )
		{
			//encrypt data before saving it
			CRijndael oRijndael;
			oRijndael.MakeKey( (const char*)pEncryp->pDataKey, (const char*)pEncryp->pDataIV, pEncryp->nKeyLen, pEncryp->nBlockSize );
			
			INT nNewLen = 0;

			BYTE* pNewData = align( pRawDocData, nDataLen, pEncryp->nBlockSize, &nNewLen );
			bool bFree = ( nDataLen != nNewLen );
			
			nDataLen = nNewLen;

			BYTE* pEnc = (BYTE*)malloc(  nDataLen );
			nRes = 0;
			try{
				oRijndael.Encrypt( (const char*)pNewData, (char*)pEnc, nDataLen, CRijndael::ECB );
				nRes = (INT)write( fh, pEnc, nDataLen );
			} catch (exception& ex ) {
				free( pEnc );
				if ( bFree ) delete [] pNewData;
				return -7;
			}
			free( pEnc );
			if ( bFree ) delete [] pNewData;
		}
		else
		{
			//don't have to encrypt data
			//13.02.2012 - added scrambling of unencrypted buffer
			ScrambleBuffer( pRawDocData, nDataLen, CFiler::key2, 32 );
			///
			nRes = (INT)write( fh, pRawDocData, nDataLen );
			//nRes = _write( fh, pRawDocData, nDataLen );
		}
	}
	else
	{
        char szTemp[512];
        U2C( (const BYTE*)pDocExInfo->szFullFileName, szTemp, 512 );
		nRes = (INT)WriteDocument( fh, szTemp, pEncryp );
	}
	
	//_commit( fh );//flush bytes
	
	//go back to the file header and write document data offset
	lseek( fh, 12L, SEEK_SET );
	write( fh, &nOffset, sizeof( INT ) );
	
	close( fh );
		
	return nRes;
}

void CFiler::U2C( const BYTE* szU, char* szC, int nLen )
{
    memset( szC, 0, nLen );
    for( int c=0,u=0; u<nLen*2 && c<nLen; c++,u+=2 )
    {
        if ( szU[u] != '\x0' ) szC[c] = szU[u];
    }
}

void CFiler::Close( INT fh )
{
	close( fh );
}

/*
	13.02.2012 - Prepare buffer by XORing sequence of bytes
*/
void CFiler::ScrambleBuffer( BYTE* buffer, INT nBufferLen, char* sequence, INT nSeqLen) const
{
	int i=0;
	while( i<nBufferLen )
	{
		for( int j=0; j<nSeqLen && i<nBufferLen; j++ )
		{
			buffer[i] = buffer[i] ^ sequence[j];
			
			i++;
		}
	}
}
/*
INT CFiler::UpdateHeader( INT fh, BYTE* pAdditional, PENCRYP pEncryp )
{
	DeleteAll();
	
	
	if ( -1 == _lseek( fh, 0L, SEEK_SET ) )
	{
		_close( fh );
		return -1;
	}
	
	//write file header
	if ( -1 == _write( fh, "{DRMPDK}", 8 ) )
	{
		return -6;
	}
	INT nOffset = 0;
	INT nPDK_FileVersion = PDK_VERSION;
	if ( -1 == _write( fh, &nPDK_FileVersion, sizeof(INT) ) )
	{
		return -6;
	}

	//placeholder for offset to data
	if ( -1 == _write( fh, &nOffset, sizeof(INT) ) )
	{
		return -6;
	}
	
	if ( -1 == _write( fh, pAdditional, 128 ) )
	{
		return -6;
	}

	//write DOCUMENT HEADER
	INT nDocHeaderLen = SaveData( fh, pEncryp );
	if ( nDocHeaderLen < 0 ) return nDocHeaderLen;
	
	nOffset = HEADER_LEN + nDocHeaderLen;
	
	//write Document itself
	INT nRes = WriteDocument( fh, pDocExInfo->szFullFileName, pEncryp );
	
	_commit( fh );//flush bytes
	
	//go back to the file header and write document data offset
	_lseek( fh, 12L, SEEK_SET );
	_write( fh, &nOffset, sizeof( INT ) );
	
	_close( fh );
		
	return nRes;
}*/
