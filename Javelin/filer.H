#ifndef __FILER_H__
#define __FILER_H__

//#include <malloc.h>
#include <list>
#include "DocInfo.h"
#include "DrumlinTypes.h"
#include "UnicodeString.h"

/*
#define	MYCHAR		wchar_t
#define MYSTRCPY	wcscpy
//#define MYSTRDUP	wcsdup
#define	MYSTRCMP	wcscmp
#define MYSTRLEN	wcslen
#define MYSTRSTR	wcsstr
*/
#define	MYCHAR		wchar_t
#define MYSTRCPY	CUnicodeString::StrCpy
#define MYSTRDUP	CUnicodeString::StrDup
#define	MYSTRCMP	CUnicodeString::StrCmp
#define MYSTRLEN	CUnicodeString::StrLen
#define MYSTRSTR	CUnicodeString::StrStr

#define	TYPE_INT		0
#define	TYPE_DATE		1
#define	TYPE_DOUBLE		2
#define	TYPE_STRING		3
#define	TYPE_BYTE		4
#define	TYPE_INT64		5
#define	TYPE_INT16		6
#define	TYPE_BINARY		7



using namespace std;


class CValue
{
private:
	MYCHAR	m_szName[32];
	INT		m_nType;
	void*	m_pValue;
    
	
    
public:
	CValue()
	{
		m_nType = TYPE_INT;
		m_pValue = NULL;
		m_szName[0] = 0;
	}
	
	CValue( INT nType, const MYCHAR* szName, const void* pValue )
	{
		MYSTRCPY( m_szName, szName );
		m_pValue = NULL;
		SetValue( nType, pValue );
	}
	
	~CValue()
	{
		if ( m_pValue != NULL ) free( m_pValue );
	}
	
	void SetValue( INT nType, const void* pValue )
	{
		m_nType = nType;
		
		if ( m_pValue != NULL ) free( m_pValue );
		
		switch( nType )
		{
		case TYPE_INT:
		case TYPE_DATE:
			m_pValue = (BYTE*)malloc( sizeof( INT ) );
			memcpy( m_pValue, pValue, sizeof( INT ) );
			break;
			
		case TYPE_DOUBLE:
			m_pValue = (BYTE*)malloc( sizeof( double ) );
			memcpy( m_pValue, pValue, sizeof( double ) );
			break;
		
		case TYPE_BYTE:
			m_pValue = (BYTE*)malloc( 1 );
			memcpy( m_pValue, pValue, 1 );
			break;
			
		case TYPE_INT16:
			m_pValue = (BYTE*)malloc( 2 );
			memcpy( m_pValue, pValue, 2 );
			break;
		
		case TYPE_INT64:
			m_pValue = (BYTE*)malloc( sizeof( EXTRALONG ) );
			memcpy( m_pValue, pValue, sizeof( EXTRALONG ) );
			break;
			
		case TYPE_STRING:
		{
			MYCHAR* pTemp = u_strdup( (MYCHAR*)pValue );
			m_pValue = (BYTE*)pTemp;
			break;
		}
		
		case TYPE_BINARY:
		{
			//WARNING!!!
			//You must prepare data buffer so that
			//1st four bytes are length!!!!!
			INT* pLen = (INT*)pValue;
			m_pValue = (BYTE*)malloc( 4 + *pLen );
			
			memcpy( m_pValue, pValue, *pLen + 4 );
			break;
		}
		}
	}
	
	INT GetType() const { return m_nType; }
	const void* GetValue() const { return m_pValue; }
	const MYCHAR* GetName() const { return m_szName; }
	BYTE* GetData( INT* pLen ) const;
	const BYTE* GetBinaryValue( INT* pLen ) const;
    
    static MYCHAR *u_strdup(MYCHAR *in);
};

class CFiler
{
private:
	static char key1[32];
	static char key2[32];
	list<CValue*>*	m_list;
	
public:
	CFiler(void);
	~CFiler(void);
	
	INT		AddValue( INT nType, const MYCHAR* szName, const void* pValue );
	INT		AddValue( const CValue* pValue );
	
	INT		GetSize() const { return m_list->size(); }
	
	CValue* GetValue( INT nIndex ) const;
	CValue* GetValue( const MYCHAR* szName ) const;
	CValue* GetValueA( const char* szName ) const;//MAC ONLY!
	
	bool	DeleteValue( INT nIndex );
	bool	DeleteValue( const MYCHAR* szName );
	
	void	DeleteAll();
	
	bool	Save( const char* szFile, const BYTE* bKey=NULL, const BYTE* bIV=NULL, INT nKeyLength=0, INT nBlockSize=0 ) const;
	bool	Load( const char* szFile, const BYTE* bKey=NULL, const BYTE* bIV=NULL, INT nKeyLength=0, INT nBlockSize=0 );
	bool	Load( long lLen, BYTE* pData, const BYTE* bKey=NULL, const BYTE* bIV=NULL, INT nKeyLength=0, INT nBlockSize=0 );
	
//	INT		Save( PDOCEX_INFO, const MYCHAR* );
	INT		LoadHeader( PDOCEX_INFO pDocExInfo, const char* szFile, UINT* puDocLen, INT* pnOffset, INT* pnPDKVersion, PENCRYP pEncryp=NULL );
    INT     LoadHeaderFromData( PDOCEX_INFO pDocExInfo, BYTE* data, UINT nDataLen, UINT* puDocLen, INT* pnOffset, INT* pnPDKVersion, PENCRYP pEncryp=NULL );

	INT		LoadDocument( INT fh, INT nOffset, BYTE* pData, INT nDataLen, PENCRYP pEncryp=NULL  ) const;
	INT		LoadDocumentFromData( BYTE* pMainData, UINT nMainDataLen, INT nOffset, BYTE* pData, INT nDataLen, PENCRYP pEncryp=NULL, bool bSelfAuth=false  ) const;
	
	INT		SaveDocument( PDOCEX_INFO, const char*, PENCRYP pEncryp=NULL, BYTE* pRawDocData=NULL, INT nDataLen=0 );

//	void	DeleteBuffer( BYTE* pData ) const { free( pData ); }
	BYTE*	DebugAllocMem( INT n, UINT* pn ) const
	{
		*pn = n;
		BYTE* pData = new BYTE[ n ];
		return pData;
	}

	INT		LoadValues( BYTE* pData, long lLen, INT nBlockSize );
	
	BYTE*	GetData( INT* pnLen ) const;
	
	void	Initialise( PDOCEX_INFO ) const;
	void	Close( INT );

private:
	INT		WriteDocumentHeader( INT, PDOCEX_INFO, PENCRYP pEncryp=NULL );
	INT		ReadHeader( INT, PDOCEX_INFO, INT*, INT*, PENCRYP pEncryp=NULL );
    INT		ReadHeaderFromData( BYTE* data, UINT nDataLen, PDOCEX_INFO, INT*, INT*, PENCRYP pEncryp=NULL );
	long	SaveData( INT fh, PENCRYP pEncryp=NULL );
	void	PopulateDiex( PDOCEX_INFO pDocExInfo ) const;
	
	BYTE*	PrepareBin( BYTE*, INT, BYTE* ) const;
	BYTE*	GetBin( const BYTE*, BYTE*, INT ) const;
	
	long	WriteDocument( INT, char*, PENCRYP pEncryp=NULL );
    void    U2C( const BYTE* szU, char* szC, int nLen );
	INT		UstrLen( BYTE* data ) const;
	INT		UstrCpy( BYTE* src, BYTE* dest );
	
	void	ScrambleBuffer( BYTE*, INT, char*, INT ) const;
};

#endif


