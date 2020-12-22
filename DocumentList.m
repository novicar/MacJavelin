//
//  DocumentList.m
//  Javelin3
//
//  Created by Novica Radonic on 24/09/2020.
//

#import "DocumentList.h"
#import "General.h"

@implementation DocumentList

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        m_documents = [[NSMutableDictionary alloc] init];
    }
 
    return self;
}

-(void) addDocument:(NSString*)sDoc startPage:(int)nPage
{
	NSNumber* page = [NSNumber numberWithInt:nPage];
	[m_documents setObject:page forKey:sDoc];
	
	NSNumber* page1 = (NSNumber*)[m_documents objectForKey:sDoc];
	NSLog(@"PAGE: %@", page1);
}

- (NSURL*)getFileName
{
	NSURL* url = [General applicationDataDirectory];
	url = [url URLByAppendingPathComponent:@"doclist.bin"];
	
	return url;
}

-(BOOL) saveMe
{
 	NSError* error;
	NSURL* url = [self getFileName];
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:m_documents];
	BOOL bRes = [data writeToURL:url options:NSDataWritingAtomic error:&error];
    
	//BOOL bRes = [m_documents writeToURL:url error:&error];
	//BOOL bRes = [m_documents writeToURL:url atomically:YES];
    if(bRes == NO)
    {
        NSLog(@"write error while saving doc list");
        
        //NSLog(@"%@", [error localizedDescription]);
		[General displayAlert:@"ERROR: Unable to save document list" message:[error localizedDescription]];
    }
    return bRes;
}

-(BOOL) loadMe
{
	NSURL* file = [self getFileName];
	/*m_documents = [[NSMutableDictionary alloc] initWithContentsOfURL:file];
	if ( m_documents == nil )
		m_documents = [[NSMutableDictionary alloc] init];
	return YES;*/
	NSError* error = nil;
	NSData* data = [NSData dataWithContentsOfURL:file options:0 error:&error];
	m_documents = (NSMutableDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ( m_documents == nil )
		m_documents = [[NSMutableDictionary alloc] init];
	
	return YES;
}

-(int) getPageForDocument:(NSString*)sDoc
{
	NSNumber* page = (NSNumber*)[m_documents objectForKey:sDoc];
	
	if ( page != nil )
	{
		int nPage = [page intValue];
		return nPage;
	}
	return -1;
}

@end
