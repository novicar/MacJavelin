//
//  CatalogItem.h
//  Javelin3
//
//  Created by Novica Radonic on 07/05/2018.
//

#import <Cocoa/Cocoa.h>
#import "CatalogProtocol.h"

@interface CatalogItem : NSCollectionViewItem
{
	IBOutlet NSImageView*	m_image;
	IBOutlet NSTextView*	m_text;
	IBOutlet NSView*		m_state;
	
	NSString*				m_sName;
	NSString*				m_sURL;
	NSString*				m_sThumbURL;
	
	NSString*				m_sSubtitle;
	NSString*				m_sISBN;
	NSString*				m_sPublisherName;
	NSString*				m_sPublisherURL;
	NSString*				m_sAuthors;
	NSString*				m_sAuthorURL;
	NSString*				m_sLanguage;
	NSString*				m_sEdition;
	NSString*				m_sDescription;
	NSString*				m_sReview;
	NSString*				m_sPrintLength;
	NSString*				m_sPublicationDate;
	NSString*				m_sPrice;
	NSString*				m_sCurrencyCode;
	
	NSString*				m_sCatalogDirectory;
}

@property (nonatomic, readwrite, copy)	NSString* Name;
@property (nonatomic, readwrite, copy)	NSString* URL;
@property (nonatomic, readwrite, copy)	NSString* ThumbURL;
@property (nonatomic, readwrite, copy)	NSString* Subtitle;
@property (nonatomic, readwrite, copy)	NSString* ISBN;
@property (nonatomic, readwrite, copy)	NSString* PublisherName;
@property (nonatomic, readwrite, copy)	NSString* PublisherURL;
@property (nonatomic, readwrite, copy)	NSString* Authors;
@property (nonatomic, readwrite, copy)	NSString* AuthorURL;
@property (nonatomic, readwrite, copy)	NSString* Language;
@property (nonatomic, readwrite, copy)	NSString* Edition;
@property (nonatomic, readwrite, copy)	NSString* Description;
@property (nonatomic, readwrite, copy)	NSString* Review;
@property (nonatomic, readwrite, copy)	NSString* PrintLength;
@property (nonatomic, readwrite, copy)	NSString* PublicationDate;
@property (nonatomic, readwrite, copy)	NSString* Price;
@property (nonatomic, readwrite, copy)	NSString* CurrencyCode;
@property (nonatomic, readwrite, copy)	NSString* CatalogDirectory;

@property (nonatomic, assign, readwrite) id <CatalogProtocol> prot;

-(void)redraw;

@end
