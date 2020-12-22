//
//  CatalogItem.m
//  Javelin3
//
//  Created by Novica Radonic on 07/05/2018.
//

#import "CatalogItem.h"


@interface CatalogItem ()

@end

@implementation CatalogItem

@synthesize Name=m_sName;
@synthesize URL=m_sURL;
@synthesize ThumbURL=m_sThumbURL;
@synthesize PublisherName=m_sPublisherName;
@synthesize PublisherURL=m_sPublisherURL;
@synthesize Authors=m_sAuthors;
@synthesize AuthorURL=m_sAuthorURL;
@synthesize Language=m_sLanguage;
@synthesize Edition=m_sEdition;
@synthesize Description=m_sDescription;
@synthesize Review=m_sReview;
@synthesize PrintLength=m_sPrintLength;
@synthesize PublicationDate=m_sPublicationDate;
@synthesize Price=m_sPrice;
@synthesize CurrencyCode=m_sCurrencyCode;
@synthesize CatalogDirectory=m_sCatalogDirectory;

@synthesize prot;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
	
}
-(void)redraw
{
	[m_text setNeedsDisplay:YES];
}

-(void)mouseUp:(NSEvent *)event
{
	//NSLog(@"CLicked on %@", self.Name);
	if ( prot )
		[prot itemClicked:self];
}

- (void)rightMouseUp:(NSEvent *)event
{
	//NSLog(@"RightMouse UP");
	if ( prot )
		[prot itemRightClicked:self withEvent:event];
}

-(void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	if (representedObject !=nil)
	{
		//NSLog(@"%@",[representedObject valueForKey:@"itemImage"]);
		
		[self setName:[representedObject valueForKey:@"Name"]];
		[self setURL:[representedObject valueForKey:@"URL"]];
		[self setThumbURL:[representedObject valueForKey:@"ThumbURL"]];
		[self setPublisherName:[representedObject valueForKey:@"PublisherName"]];
		[self setPublisherURL:[representedObject valueForKey:@"PublisherURL"]];
		[self setAuthors:[representedObject valueForKey:@"Authors"]];
		[self setAuthorURL:[representedObject valueForKey:@"AuthorURL"]];
		[self setLanguage:[representedObject valueForKey:@"Language"]];
		[self setEdition:[representedObject valueForKey:@"Edition"]];
		[self setDescription:[representedObject valueForKey:@"Description"]];
		[self setReview:[representedObject valueForKey:@"Review"]];
		[self setPrintLength:[representedObject valueForKey:@"PrintLength"]];
		[self setPublicationDate:[representedObject valueForKey:@"PublicationDate"]];
		[self setPrice:[representedObject valueForKey:@"Price"]];
		[self setCurrencyCode:[representedObject valueForKey:@"CurrencyCode"]];
		[self setCatalogDirectory:[representedObject valueForKey:@"CatalogDirectory"]];
		
		//NSLog(@"Name: %@", m_sName);
		[m_text setString:m_sName];
		[m_text alignCenter:nil];
		[m_text setEditable:NO];
		
		[m_state setWantsLayer:YES];
		
		NSString* sURL = m_sURL;
		if ( m_sCatalogDirectory != nil && m_sCatalogDirectory.length > 0 )
		{
			//NSLog(@"Cat.Directory: %@", m_sCatalogDirectory);
			[m_state setHidden:NO];
			NSRange range = [m_sURL rangeOfString:@"?dl="]; 
			if (range.location != NSNotFound) 
			{
				//NSLog(@"string contains dropbox thingy!");
				sURL = [m_sURL substringToIndex:range.location];
			}
			NSString* sFile =[[[m_sCatalogDirectory stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"] stringByAppendingPathComponent:[sURL lastPathComponent]];
			if ( [[NSFileManager defaultManager] fileExistsAtPath:sFile] )
			{
				[m_state.layer setBackgroundColor:[[NSColor colorWithRed:0 green:0.4 blue:0 alpha:1] CGColor]];
			}
			else
			{
				[m_state.layer setBackgroundColor:[[NSColor colorWithRed:0.5 green:0 blue:0 alpha:1] CGColor]];
			}
		}
		else
		{
			//NSLog(@"URL: %@", sURL);
			[m_state setHidden:YES];
		}

		if ( [m_sThumbURL length] > 0 && m_sCatalogDirectory!=nil && m_sCatalogDirectory.length > 0)
		{
			NSString* sFile = [m_sThumbURL lastPathComponent];
			NSString* sDir = [[m_sCatalogDirectory stringByDeletingPathExtension] stringByAppendingPathExtension:@"catdir"];
			NSString* sFullName = [sDir stringByAppendingPathComponent:sFile];
			
			if ( [[NSFileManager defaultManager] fileExistsAtPath:sFullName] )
			{
				NSImage* image = [[NSImage alloc] initWithContentsOfFile:sFullName];
				if (image != nil )
				{
					[m_image setImage:image];
					return;
				}
			}
		}

		//default images
		NSString* sExt = [[sURL pathExtension] lowercaseString];
		
		if ( [sExt isEqualToString:@"pdf"] )
		{
			[m_image setImage:[[NSBundle mainBundle] imageForResource:@"pdf"]];
		}
		else if ( [sExt isEqualToString:@"drmz"] )
		{
			[m_image setImage:[[NSBundle mainBundle] imageForResource:@"javelin263"]];
		}
		else
		{
			[m_image setImage:[[NSBundle mainBundle] imageForResource:@"catalog_200"]];
		}
//		[self.titleTextField setStringValue:[representedObject valueForKey:@"itemTitle"]];
//		[self.descriptionTextField setStringValue:[representedObject valueForKey:@"itemDescription"]];
//		[self.detailDescription setStringValue:[representedObject valueForKey:@"itemDetailedDescription"]];
//		[self.price setStringValue:[representedObject valueForKey:@"itemPrice"]];
//		[self.itemImageView setImage:[[NSBundle mainBundle] imageForResource:[representedObject valueForKey:@"itemImage"]]];
	}
	else
	{
		[self setName:@"no name"];
		[self setURL:@""];
		[self setThumbURL:@""];
		[self setPublisherName:@""];
		[self setPublisherURL:@""];
		[self setAuthors:@""];
		[self setAuthorURL:@""];
		[self setLanguage:@""];
		[self setEdition:@""];
		[self setDescription:@""];
		[self setReview:@""];
		[self setPrintLength:@""];
		[self setPublicationDate:@""];
		[self setPrice:@""];
		[self setCurrencyCode:@""];
	}
}
@end
