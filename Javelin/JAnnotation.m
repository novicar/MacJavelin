//
//  JAnnotation.m
//  JavelinM
//
//  Created by harry on 03/02/2015.
//
//

#import "JAnnotation.h"

@implementation JAnnotation

@synthesize boundary=m_boundary;
@synthesize type=m_nType;
@synthesize text=m_sText;
@synthesize title=m_sTitle;
@synthesize date=m_sDate;
@synthesize newNote=m_bNew;
//@synthesize page=m_page;
//@synthesize pageNumber=m_nPage;

- (id)init
{
    self = [super init];
    if (self) {
		m_boundary	= NSMakeRect(0, 0, 0, 0);
		m_nType		= 0;
		m_sText		= @"";
		m_sTitle	= @"";
		m_sDate		= @"";
        m_page      = nil;
        m_nPage     = 0;
		m_bNew 		= NO;
    }
    
    return self;
}

-(id) initWithType:(NSRect)rect type:(int)nType
{
    self = [super init];
    if (self) {
        m_boundary	= rect;
        m_nType		= nType;
        m_sText		= @"";
        m_sTitle	= @"";
        m_sDate		= @"";
        m_page      = nil;
        m_nPage     = 0;
		m_bNew 		= NO;
    }
    
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
	m_boundary	= [aDecoder decodeRectForKey:@"boundary"];
	m_nType		= [aDecoder decodeIntForKey:@"type"];
	m_sText		= [aDecoder decodeObjectForKey:@"text"];
	m_sTitle	= [aDecoder decodeObjectForKey:@"title"];
	m_sDate		= [aDecoder decodeObjectForKey:@"date"];
    m_page = nil;
	m_nPage     = 0;
	m_bNew 		= NO;
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeRect:m_boundary forKey:@"boundary"];
	[aCoder encodeInt:m_nType forKey:@"type"];
	[aCoder encodeObject:m_sText forKey:@"text"];
	[aCoder encodeObject:m_sTitle forKey:@"title"];
	[aCoder encodeObject:m_sDate forKey:@"date"];
}

- (int) getAnnotationType:(NSString*)sType
{
	if ( [sType isEqualToString:@"Underline"] )
		return ANNOTATION_UNDERLINE;
	else if ( [sType isEqualToString:@"Highlight"] )
		return ANNOTATION_HIGHLIGHT;
	else if ( [sType isEqualToString:@"StrikeOut"] )
		return ANNOTATION_STRIKEOUT;
	else if ( [sType isEqualToString:@"Text"] )
		return ANNOTATION_NOTE;
	else if ( [sType isEqualToString:@"FreeText"] )
		return ANNOTATION_FREE_NOTE;
	else
		return ANNOTATION_ERROR;
}

- (NSString*) getContent
{
    return m_sText;
}

-(void)setPage:(PDFPage*)page number:(int)nPage
{
    m_page = page;
    m_nPage = nPage;
}

-(PDFPage*)page
{
    return m_page;
}

-(void)setPageNumber:(int)nPage
{
    m_nPage = nPage;
}

-(int)pageNumber
{
    return m_nPage;
}

@end
