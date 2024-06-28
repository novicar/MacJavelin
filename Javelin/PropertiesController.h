//
//  PropertiesController.h
//  Javelin
//
//  Created by harry on 9/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DocumentRecord;


@interface PropertiesController : NSObject {
@private
    IBOutlet		NSTextField		*title;
	IBOutlet		NSTextField		*subject;
	IBOutlet		NSTextField		*author;
	IBOutlet		NSTextField		*keywords;
	IBOutlet		NSTextField		*creator;
	IBOutlet		NSTextField		*producer;
	IBOutlet		NSTextField		*created;
	IBOutlet		NSTextField		*modified;
	IBOutlet		NSTextField		*pages;
	IBOutlet		NSTextField		*filename;
	IBOutlet		NSTextField		*filesize;
	
	IBOutlet		NSTextField		*docID;
	IBOutlet		NSTextField		*openedNo;
	IBOutlet		NSTextField		*printedNo;
	IBOutlet		NSTextField		*printPages;
	IBOutlet		NSTextField		*startDate;
	IBOutlet		NSTextField		*endDate;
	IBOutlet		NSTextField		*txSelfAuth;
	IBOutlet		NSTextField		*publisherID;
	IBOutlet		NSTextField		*disableScreenCapture;
	
	IBOutlet		NSWindow		*properties;
	
	BOOL m_bSelfAuth;

//	NSDictionary	*pdfAttributes;
}

//- (void) setProperties: (NSDictionary*)attrs;
//- (void)showProperties:(NSWindow *)window attributes:(NSDictionary*)attrs docRecord:(DocumentRecord*)docRec;
- (void)fillProperties:(NSDictionary*)attrs 
			 docRecord:(DocumentRecord*)docRec 
			  fileName:(NSString*)sFileName 
			  fileSize:(NSUInteger)nFileSize
		blockGrabbers:(BOOL)bBlockGrabbers
		   publisherID:(NSUInteger)nPublisherID	
				 pages:(NSUInteger)nPages 
			  inWindow:(NSWindow*)window;

- (IBAction)closeProperties: (id)sender;

@property (readonly) NSWindow* properties;
@property (assign, readwrite) BOOL selfAuth;
@end
