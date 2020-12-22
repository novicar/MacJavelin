//
//  Watermark.m
//  Javelin
//
//  Created by harry on 9/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Watermark.h"
#import "General.h"
//#import "math.h"

@implementation Watermark

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		m_sWatermark = nil;
		m_nType = 0;//1-screen; 2-print
		m_sText = nil;
		m_Color = nil;
		m_Font = nil;
		m_nDirection = -1;//diagonal
		m_sFontSize = 12;
		//m_wmImage = nil;
    }
    
    return self;
}
/*
- (void)dealloc
{
	//if ( m_sWatermark != nil ) [m_sWatermark release];
	//if ( m_sText != nil ) [m_sText release];
	//if ( m_wmImage != nil ) [m_wmImage release];
    [super dealloc];
}
*/
- (int)type
{
	return m_nType;
}

- (BOOL) isPrint
{
	if ( m_nType >= 2 ) return YES;
	
	return NO;
}

- (BOOL) isScreen
{
	if ( m_nType == 1 || m_nType == 3 ) return YES;
	return NO;
}

/*
- (void)setWatermark:(const unsigned char*)szWatermarkUnicodeText 
			  ofType:(int)type
		 forDocument:(const unsigned char*)szDocName 
			   DocID:(unsigned int)docID
			authCode:(NSString*)authCode
{
	char szTemp[256];
	
	[General convertUnicode:szWatermarkUnicodeText toChar:szTemp maxLen:256];
	m_sWatermark = [NSString stringWithUTF8String:szTemp];
	
	[General convertUnicode:szDocName toChar:szTemp maxLen:256];
	NSString *sName = [NSString stringWithUTF8String:szTemp];
	[self expand:sName docID:docID authCode:authCode];
	
	m_nType = type;
}
*/

- (void)setWatermark:(PDOCEX_INFO)pDocInfo
			authCode:(NSString*)sAuthCode
{
	// where ownerchar szTemp[256];
	NSString* sss = [General stringFromWchar:(const wchar_t *)pDocInfo->szWMText length:256];
	m_sWatermark = [NSString stringWithString:sss];
	NSString *sName = [General stringFromWchar:(const wchar_t *)pDocInfo->szDocName length:256];
//	[General convertUnicode:(const unsigned char*)pDocInfo->szWMText
//					 toChar:szTemp
//					 maxLen:256];
//	m_sWatermark = [NSString stringWithUTF8String:szTemp];
	
//	[General convertUnicode:(const unsigned char*)pDocInfo->szDocName
//					 toChar:szTemp
//					 maxLen:256];
	
//	NSString *sName = [NSString stringWithUTF8String:szTemp];
	
	m_nType = (int)pDocInfo->sWMType;
	m_nDirection = pDocInfo->nDirection;
	m_nHor = pDocInfo->nHor;
	m_nVert = pDocInfo->nVert;
	m_nStartPage = pDocInfo->nFromPage;
	m_nEndPage = pDocInfo->nToPage;
	m_sFontSize = pDocInfo->sFontSize;
	
	if ( m_sFontSize > 14 ) m_sFontSize = 14;

	float fRed = 0.8;
	float fGreen = 0.1;
	float fBlue = 0.1;
	
	//.NET has following pattern for colours:
	//0xAARRGGBB
	//AA - alpha, RR - red, GG - green, BB - blue
	unsigned int nCol = (unsigned int)pDocInfo->nFontColour;
	unsigned int nBlue = (nCol & 0x000000ff);
	unsigned int nGreen = ((nCol & 0x0000ff00) >> 8);
	unsigned int nRed = ((nCol & 0x00ff0000) >> 16);
	
	//NSLog( @"C:%X R:%X G:%X B:%X", nCol, nRed, nGreen, nBlue );
	
	float fD = (float)(nRed+nGreen+nBlue);
	if ( fD == 0.0 )
	{
		fRed = 0.2;
		fGreen = 0.2;
		fBlue = 0.2;
		fD = 1.0;
	}
	else
	{
		fRed = nRed / fD;
		fGreen = nGreen / fD;
		fBlue = nBlue / fD;
	}
	
	fD = pDocInfo->sOpacity/100.0;
	if ( fD < 0.4 ) fD = 0.4;
	
	m_Color = [NSColor colorWithRed:fRed green:fGreen blue:fBlue alpha:fD];
/*Removed on 2013-12-20 in order to use fontsize 12 in all cases
	int nFontSize = pDocInfo->sFontSize;
	if ( nFontSize > 20 ) nFontSize = 12;
	m_Font = [NSFont fontWithName:@"Helvetica" size:nFontSize];
*/
	[self expand:sName 
		   docID:(unsigned int)pDocInfo->dwDocID 
		authCode:sAuthCode];
}

- (NSString*)watermark
{
	return m_sWatermark;
}

#define STARS_LEN	3

- (NSString*) prepareAuthCode:(NSString*)authCode
{
	int nLen = (int)[authCode length];
	
	if ( nLen == 0 ) return authCode;
	else if ( nLen == 1 ) return @"*";
	else if ( nLen == 2 ) return @"**";
	else if ( nLen == 3 ) return @"***";
	else if ( nLen == 4 ) return @"****";
	else
	{
		NSRange r = NSMakeRange((nLen-STARS_LEN)/2, STARS_LEN);
		NSString* s = [authCode stringByReplacingCharactersInRange:r withString:@"***"];
		return s;
	}
}

- (void) expand:(NSString*)sName docID:(unsigned int)docid authCode:(NSString*)authCode
{
	NSArray *strings = [m_sWatermark componentsSeparatedByString:@"%"];
	
	if ( strings == nil || strings.count == 0 )
	{
		return;
	}
	
	NSMutableString *res = [[NSMutableString alloc] initWithCapacity:512];
	
	[res appendString:(NSString*)[strings objectAtIndex:0]];
	
	for( int i=1; i<[strings count]; i++ )
	{
		NSString *sTemp = nil;
		NSString *s = (NSString*)[strings objectAtIndex:i];
		if (s != nil && [s length]>0 && (i>0 || [s length]>1) )
		{
			//NSLog( @"WMcomponent:[%d] %@ len:%u", i, s, (unsigned int)[s length]);
			
			unichar c = [s characterAtIndex:0];
			switch(c)
			{
			case 'A':
			case 'a'://auth code
				if ( authCode != nil )
					sTemp = [self prepareAuthCode:authCode];
				else
					sTemp = @"AC";
				break;

			case 'D':
			case 'd'://date
			{
				NSDate *today = [NSDate date];
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
				[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
				
				sTemp = [dateFormatter stringFromDate:today];
				//[dateFormatter release];
				break;
			}
					
			case 'T':
			case 't'://time
			{
				NSDate *today = [NSDate date];
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
				[dateFormatter setDateStyle:NSDateFormatterNoStyle];
				
				sTemp = [dateFormatter stringFromDate:today];
				//[dateFormatter release];
				break;
			}
					
			case 'I':
			case 'i'://user id
				//sTemp = @"DrumlinJM";
				sTemp = [General getID];
				break;

			case 'M':
			case 'm'://computer name
				{
					NSProcessInfo *pi = [NSProcessInfo processInfo];
					sTemp = [NSString stringWithFormat:@"%@", [pi hostName]];
				}
				break;

			case 'U':
			case 'u'://username
				sTemp = [NSString stringWithString:NSFullUserName()];
				break;

			case 'F':
			case 'f'://document file name
					sTemp = [NSString stringWithString:sName];
				break;

			case 'C':
			case 'c'://document ID
				sTemp = [NSString stringWithFormat:@"%d", docid];
				break;
				
			case '|':
				sTemp = @"\r\n";
				break;
					
			default:
				//sTemp = [NSString stringWithFormat:@"_%d_", (int)c];
				[res appendString:s];
				continue;
			}
			[res appendString:sTemp];
			[res appendString:[s substringFromIndex:1]];
			//NSLog( @"%@", res);
		}
	}
	
	//NSLog( @"WM:%@", res );
//	m_sText = [[NSMutableAttributedString alloc] initWithString:res];
	
	if ( m_Font == nil )
		m_Font = [NSFont fontWithName:@"Helvetica" size:m_sFontSize];//2019-05-08 Mike asked me to decrease font size and then 2019-08-08 back again
	
//	if ( m_Color == nil )
//		m_Color = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:0.8];
	
	if ( m_Color == nil )
		m_Color = [NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
	
	NSArray *values = [NSArray arrayWithObjects:m_Font, m_Color, nil];
	NSArray *keys   = [NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
	
	//NSDictionary *attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	
	NSDictionary *attr = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	//NSForegroundColorAttributeName
	
	//[m_sText setAttributes:attr range:NSMakeRange(0, [m_sText length])];
	//[m_sText retain];
	//NSString *sTemp = [NSString stringWithString:res];
	m_sText = [[NSMutableAttributedString alloc] initWithString:res attributes:attr];
	//[res release];
}

//- (void) createImage:(NSSize)aSize
//{
//	if ( m_wmImage != nil ) [m_wmImage release];
/*	
	NSGraphicsContext * context = [NSGraphicsContext currentContext];
	NSBitmapImageRep *bitmap =
	[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
											pixelsWide:aSize.width
											pixelsHigh:aSize.height
										 bitsPerSample:8
									   samplesPerPixel:4
											  hasAlpha:YES 
											  isPlanar:NO
										colorSpaceName:NSCalibratedRGBColorSpace
										   bytesPerRow:0
										  bitsPerPixel:0];
	NSGraphicsContext *bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
	[NSGraphicsContext setCurrentContext:bitmapContext];
	NSRect drawRect = { {0,0}, aSize};
	NSRect bounds = [self bounds];
	[self setBounds:drawRect];
	[self drawRect:drawRect];
	[self setBounds:bounds];
	[[bitmap TIFFRepresentation] writeToFile:aFile
								  atomically:NO];
	[bitmap release];
	[NSGraphicsContext setCurrentContext:context]
*/	
//}
- (void)drawFixedAt:(NSPoint)point rect:(NSRect)rect
{
	[m_sText drawAtPoint:point];
}

- (void)drawAt:(NSPoint)point rect:(NSRect)rect
{
/* removed on 2013-12-20 in order to have fonsize:12 in all cases and font at the bottom
	NSAffineTransform* xform = [NSAffineTransform transform];

	float fRadians = 0;
	BOOL bAngled = NO;
	BOOL bHorizontal = NO;
	int nX=0, nY=0;
	
	if ( m_nDirection == -1 )
	{
		//diagonal
		float f = rect.size.height/rect.size.width;
		fRadians = atanf(f);
		bAngled = YES;
	}
	else if ( m_nDirection == 0 )
	{
		//vertical
		fRadians = 3.14/2.0;//90 degrees
		bAngled = YES;
		point.y = m_nHor/25.4 * 72.0;
	}
	else if ( m_nDirection <= 45 )
	{
		//angle (in degrees) is set by the user
		fRadians = 3.14 / 180.0 * (float)m_nDirection;
		bAngled = YES;
	}
	else
	{
		//horizontal
		bHorizontal = YES;
		nX = m_nHor/25.4 * 72.0;
		nY = m_nVert/25.4 * 72.0;
		nY = rect.size.height - nY;
	}
	
	if ( bAngled )
	{
		[xform translateXBy:0 yBy:rect.size.height-10];
		[xform rotateByRadians:-fRadians];
	
		[xform concat];
		
		[m_sText drawAtPoint:point ];
	}
	else
	{
		
		[m_sText drawAtPoint:NSMakePoint(nX, nY)];
	}
*/
	NSSize stringSize = [m_sText size];
	int nX = (rect.size.width - stringSize.width)/2.0;
	if ( nX < 0 ) nX = 0;
	
	[m_sText drawAtPoint:NSMakePoint(nX, rect.origin.y+26.0)];//bottom
	[m_sText drawAtPoint:NSMakePoint(nX, rect.origin.y+rect.size.height-40.0)];//top
}

- (BOOL) printToPage:(int)nPage
{
	if ( self.isPrint && nPage >= m_nStartPage && nPage <= m_nEndPage )
		return YES;
	
	return NO;
}

- (void) allowPrint:(BOOL)bAllow
{
	m_bPrintWatermark = bAllow;
}

- (void)printAt:(NSPoint)point rect:(NSRect)rect
{
	if ( m_bPrintWatermark == NO )
		return;
	
	NSAffineTransform* xform = [NSAffineTransform transform];

	float fRadians = 0;
	BOOL bAngled = NO;
	BOOL bHorizontal = NO;
	int nX=0, nY=0;

	//2019-04-25 - removed 72 pixels per inch calculation
	nX = m_nHor;//25.4 * 72.0;
	nY = m_nVert;///25.4 * 72.0;
	nY = rect.size.height - nY;

	if ( m_nDirection == -1 )
	{
		//diagonal
		float f = rect.size.height/rect.size.width;
		fRadians = atanf(f);
		bAngled = YES;
		nX = m_nHor;
		int nDeltaY = m_nVert/25.4 * 72.0;
		nY = rect.size.height - nDeltaY;
		
		nX = nX/25.4 * 72.0;
	}
	else if ( m_nDirection == 0 )
	{
		//vertical
		fRadians = 3.14/2.0;//90 degrees
		bAngled = YES;
/*		//if ( m_nHor > 150 )
		//	point.y = (m_nHor-20)/25.4 * 72.0;
		//else
			point.y = m_nHor/25.4 * 72.0;
		//point.x = m_nVert/25.4 * 72.0;*/
		
		nX = m_nHor;
		int nDeltaY = m_nVert/25.4 * 72.0;
		nY = rect.size.height - nDeltaY;
		
		nX = nX/25.4 * 72.0;
		//nY = nY/25.4 * 72.0;

	}
	else if ( m_nDirection <= 45 )
	{
		//angle (in degrees) is set by the user
		fRadians = 3.14 / 180.0 * (float)m_nDirection;
		bAngled = YES;
		nX = m_nHor;
		int nDeltaY = m_nVert/25.4 * 72.0;
		nY = rect.size.height - nDeltaY;
		
		nX = nX/25.4 * 72.0;
	}
	else
	{
		//horizontal
		bHorizontal = YES;
		nX = m_nHor;
		int nDeltaY = m_nVert/25.4 * 72.0;
		nY = rect.size.height - nDeltaY;
		
		nX = nX/25.4 * 72.0;
	}
	
	if ( bAngled )
	{
		//[xform translateXBy:0 yBy:rect.size.height-10];
		//[xform translateXBy:point.x yBy:point.y];
		//[xform rotateByRadians:-fRadians];
	//[xform translateXBy:10 yBy:10];
		//[xform concat];
		//[xform set];
		//NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:@"koko kaka koku"];
		//[s drawAtPoint:point ];
		
		[xform translateXBy:nX yBy:nY];
		[xform rotateByRadians:-fRadians];
		[xform concat];
		
		point.x = 0;
		point.y = 0;
		[m_sText drawAtPoint:point ];
	}
	else
	{
		
		[m_sText drawAtPoint:NSMakePoint(nX, nY)];
	}

}

@end
