//
//  DocumentList.h
//  Javelin3
//
//  Created by Novica Radonic on 24/09/2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DocumentList : NSObject
{
	NSMutableDictionary* m_documents;
}

-(void) addDocument:(NSString*)sDoc startPage:(int)nPage;
-(BOOL) saveMe;
-(BOOL) loadMe;
-(int) getPageForDocument:(NSString*)sDoc;

@end

NS_ASSUME_NONNULL_END
