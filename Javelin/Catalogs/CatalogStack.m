//
//  CatalogStack.m
//  Javelin3
//
//  Created by Novica Radonic on 16/05/2018.
//

#import "CatalogStack.h"

@implementation CatalogStack

-(unsigned  long)count
{
	if ( m_stackOfCatalogs == nil )
		return 0;
	
	return [m_stackOfCatalogs count];
}

-(NSString*)getAndRemoveTop
{
	NSString* s = [self getTop];
	
	unsigned long nCount = [self count];
	if ( s != nil && nCount > 0 )
	{
		[m_stackOfCatalogs removeObjectAtIndex:nCount-1];
	}
	
	return s;
}

-(NSString*)getTop
{
	if ( m_stackOfCatalogs == nil )
		return nil;
	
	unsigned long nCount = [self count]; 
	if ( nCount == 0 )
		return nil;
	
	NSString* s = [m_stackOfCatalogs objectAtIndex:nCount-1];
	
	return s;
}

-(unsigned long)add:(NSString*)sPath
{
	if ( m_stackOfCatalogs == nil )
		m_stackOfCatalogs = [[NSMutableArray alloc] init];
	[m_stackOfCatalogs addObject:sPath];
	return [self count];
}

@end
