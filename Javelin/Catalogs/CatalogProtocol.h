//
//  CatalogProtocol.h
//  Javelin3
//
//  Created by Novica Radonic on 02/05/2018.
//

#ifndef CatalogProtocol_h
#define CatalogProtocol_h

@class CatalogItem;

@protocol CatalogProtocol <NSObject>
	//-(void)catalogWindowClosed;
	-(void)itemClicked:(CatalogItem*)pItem;
	-(void)itemRightClicked:(CatalogItem*)pItem withEvent:(NSEvent*)event;
@end

#endif /* CatalogProtocol_h */
