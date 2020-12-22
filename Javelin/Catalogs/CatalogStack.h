//
//  CatalogStack.h
//  Javelin3
//
//  Created by Novica Radonic on 16/05/2018.
//

#import <Foundation/Foundation.h>

@interface CatalogStack : NSObject
{
	NSMutableArray*			m_stackOfCatalogs;
}

-(unsigned long)count;
-(NSString*)getAndRemoveTop;
-(NSString*)getTop;
-(unsigned long)add:(NSString*)sPath;
@end
