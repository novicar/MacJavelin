#ifndef __DOC_INFO__
#define __DOC_INFO__

#define PDK_VERSION	2
#include "DrumlinTypes.h"

typedef long long EXTRALONG;

typedef struct DocInfoEx
{
	DWORD			dwDocID;
	MYCHAR			szDocName[64];
	MYCHAR			szDocDesc[512];
	DWORD			dwPubDate;
	double			dVersion;
	DWORD			dwUploadDate;
	DWORD			dwDocSize;
	MYCHAR			szISBN[64];
	DWORD			dwOwnerID;
	DWORD			dwCreatorID;
	EXTRALONG		exlDocState;
	DWORD			dwExpires;
	int				pUSK;
	int				pHCKD;
	int				pHCKS;
	MYCHAR			szDocPwd[32];
	DWORD			dwStartDate;
	DWORD			dwExpiryDate;
	DWORD			dwOpeningCount;
	DWORD			dwPrintingCount;
	DWORD			dwPagesToPrint;
	short			sAskPassword;
	short			sMustBeOnline;
	short			sEnableClipboard;
	short			sBlockGrabbers;
	short			sRelaxedPrinting;
	int				nExpiresAfter;
	DWORD			dwTotalSize;
	short			sInitialised;
	
	MYCHAR			szFontName[32];
	MYCHAR			sFontStyle[32];
	short			sFontSize;
	int				nFontColour;
	int				nDirection;
	int				nFromPage;
	int				nToPage;
	short			sOpacity;
	int				nVert;
	int				nHor;
	MYCHAR			szWMText[128];
	short			sWMType;
	
	BYTE			byAdditional[128];
	MYCHAR			szFullFileName[512];
	MYCHAR			szDiskID[50];
	MYCHAR			szOSID[50];
	DWORD			dwUserID;
	int				nAllowedUsers;
	DWORD*			pnUsers;
} DOCEX_INFO, *PDOCEX_INFO;

typedef struct BrandingResources
{
	BYTE*		binBitmap;
	int			nBitmapLen;
	BYTE*		binIcon;
	int			nIconLen;
	MYCHAR*		szCompany;
	MYCHAR*		szLink;
} BRANDING, *PBRANDING;

typedef struct Encryp
{
	BYTE*	pHeaderKey;
	BYTE*	pHeaderIV;
	
	BYTE*	pDataKey;
	BYTE*	pDataIV;
	
	int		nKeyLen;
	int		nBlockSize;
} ENCRYP, *PENCRYP;

#endif
