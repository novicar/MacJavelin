//
//  JAnnotation.h
//  JavelinM
//
//  Created by harry on 03/02/2015.
//
//

#import <Foundation/Foundation.h>

#define ANNOTATION_HIGHLIGHT	10
#define ANNOTATION_STRIKEOUT	20
#define ANNOTATION_UNDERLINE	30
#define ANNOTATION_NOTE			40
#define ANNOTATION_FREE_NOTE	50
#define ANNOTATION_ERROR		0
@class PDFPage;

@interface JAnnotation : NSObject <NSCoding>
{
	NSRect	m_boundary;
	int		m_nType;
	NSString*	m_sText;
	NSString*	m_sTitle;
	NSString*	m_sDate;
    PDFPage*    m_page;
    int         m_nPage;
	bool	m_bNew;
}

@property (readwrite, assign) NSRect boundary;
@property (readwrite, assign) int type;
@property (readwrite, copy) NSString* text;
@property (readwrite, copy) NSString* title;
@property (readwrite, copy) NSString* date;
@property (readwrite, assign) bool newNote;
//@property (readwrite, copy) PDFPage* page;
//@property (readwrite, assign) int pageNumber;

- (int) getAnnotationType:(NSString*)sType;

-(id) initWithType:(NSRect)rect type:(int)nType;
-(NSString*)getContent;
-(void)setPage:(PDFPage*)page number:(int)nPage;
-(PDFPage*)page;
-(void)setPageNumber:(int)nPage;
-(int)pageNumber;
//-(void)draw:(CGContextRef)context;
@end
