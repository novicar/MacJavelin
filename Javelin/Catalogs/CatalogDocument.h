//
//  CatalogDocument.h
//  Javelin3
//
//  Created by Novica Radonic on 02/05/2018.
//

#import <Cocoa/Cocoa.h>
#import "CatalogProtocol.h"
#import "CatalogWindowController.h"
#import "Constants.h"


extern NSString* const CatDocumentUTI;

@interface CatalogDocument : NSDocument
{
	CatalogWindowController* m_catalogWindowController;
}
@property (nonatomic, assign, readwrite) id <CatalogProtocol> prot;

@end
