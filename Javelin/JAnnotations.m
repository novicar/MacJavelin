//
//  JAnnotations.m
//  JavelinM
//
//  Created by Novica Radonic on 02/05/2017.
//
//

#import "JAnnotations.h"
#import "General.h"

@implementation JAnnotations

- (id)initWithDocument:(PDFDocument*)document
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        m_annotations = [[NSMutableDictionary alloc] init];
        m_pDocument = document;
    }
    
    return self;
}

-(void) addHighlight:(JAnnotation* )ann toPage:(int)nPage
{
    NSNumber* key = [NSNumber numberWithInteger:nPage];
    NSMutableArray* ans = (NSMutableArray*)[m_annotations objectForKey:key];
    if ( ans == nil )
        ans = [[NSMutableArray alloc] init];
    [ans addObject:ann];
    
    //NSLog(@"Added annot to page:%d (%d) %@", nPage, ann.type, NSStringFromRect(ann.boundary));
    
    [m_annotations setObject:ans forKey:[NSNumber numberWithInteger:nPage]];
}

-(BOOL) save:(NSURL*) sFile
{
    int nTotal = 0;
    int nType = 0;
  /*
    //add PDF native annotations
    for( int i=0; i<[[m_pDocument pdfDocument] pageCount]; i++ )
    {
        //NSLog(@"Page: %d", i+1);
        //NSLog(@"-----------");
        PDFPage* page = [[m_pDocument pdfDocument] pageAtIndex:i];
        int nPage = (int)CGPDFPageGetPageNumber([page pageRef]);
        int nAnnotCount = (int)[[page annotations] count];
        if ( nAnnotCount > 0 )
        {
            int nCount = 0;
            //NSMutableArray* pArray = [[NSMutableArray alloc] init];
            
            NSNumber* key = [NSNumber numberWithInteger:nPage];
            NSMutableArray* pArray = [m_annotations objectForKey:key];
            if ( pArray == nil )
                pArray = [[NSMutableArray alloc] init];
            
            for( int n=0; n < nAnnotCount; n++)
            {
                PDFAnnotation* ann = [[page annotations] objectAtIndex:n];
                if ( [[ann type] isEqualToString:@"Link"] == NO )
                {
                    if ( [ann bounds].size.width != 0 )
                    {
                        //NSLog(@"%@ -- %@ -- %@", NSStringFromRect([ann bounds]), [ann type], [ann contents] );
                        JAnnotation* pJA = [[JAnnotation alloc] init];
                        nType = [pJA getAnnotationType:[ann type]];
                        if ( nType != 0 )
                        {
                            nCount ++;
                            nTotal ++;
                            
                            pJA.boundary = [ann bounds];
                            pJA.type = nType;
                            pJA.text = [ann contents];
                            if ( pJA.text == nil ) pJA.text = @"";
                            
                            pJA.title = [ann contents];
                            if ( pJA.title == nil ) pJA.title = @"";
                            
                            [pArray addObject:pJA];
                        }
                    }
                }
            }
            if ( nCount > 0 )
            {
                NSNumber* key = [NSNumber numberWithInt:i];
                [m_annotations setObject:pArray forKey:key];
            }
        }
        //DEBUG
        NSNumber* key = [NSNumber numberWithInteger:nPage];
        NSMutableArray* pArray = [m_annotations objectForKey:key];
        if ( pArray != nil )
        {
            for( int i=0; i<[pArray count]; i++)
            {
                JAnnotation* an = [pArray objectAtIndex:i];
                NSLog(@"page:%d (%d) %@", nPage, an.type, NSStringFromRect(an.boundary));
            }
        }

        //END DEBUG
    }
*/
	
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:m_annotations];
    
    NSURL* url = [self getNtsUrl:sFile];//[m_docURL URLByAppendingPathExtension:@"nts"];
    
    NSError* error;
    BOOL bRes = [data writeToURL:url options:NSDataWritingAtomic error:&error];
    
    if(error != nil)
    {
        NSLog(@"write error while saving annotations %@", error);
        
        //NSLog(@"%@", [error localizedDescription]);
        [General displayAlert:@"ERROR: Unable to save annotations" message:[error localizedDescription]];
    }
    return bRes;
}

- (NSURL*)getNtsUrl:(NSURL *)docURL
{
    NSURL* uurl = [General applicationDataDirectory];
    
    //make sure directory exists
    //	NSFileManager* fileManager = [[NSFileManager alloc] init];
    //	if (![fileManager fileExistsAtPath:[uurl path]])
    //		[fileManager createDirectoryAtURL:uurl withIntermediateDirectories:NO attributes:nil error:nil];
    
    uurl = [uurl URLByAppendingPathComponent:[docURL lastPathComponent]];
    uurl = [uurl URLByAppendingPathExtension:@"nts"];
    
    return uurl;
}


-(NSArray*) highlightsForPage:(int)nPage
{
    NSNumber* key = [NSNumber numberWithInteger:nPage];
    return [m_annotations objectForKey:key];
}

-(NSArray*) annotsForIndex:(int)nIndex
{
    //NSArray* keys = [m_annotations allKeys];
    NSArray* keys = [[m_annotations allKeys] sortedArrayUsingSelector:@selector(compare:)];
    if ( nIndex < keys.count)
    {
        return [m_annotations objectForKey:[keys objectAtIndex:nIndex]];
    }
    return nil;
}

-(NSArray*) notesForIndex:(int)nIndex
{
    //NSArray* keys = [m_annotations allKeys];
    NSArray* keys = [[m_annotations allKeys] sortedArrayUsingSelector:@selector(compare:)];
    if ( nIndex < keys.count)
    {
        NSArray* annots = [m_annotations objectForKey:[keys objectAtIndex:nIndex]];
        if ( annots == nil || annots.count == 0 )
            return nil;
        
        NSMutableArray* notes = [[NSMutableArray alloc] init];
        for( int i=0; i<annots.count; i++ )
        {
            JAnnotation* an = [annots objectAtIndex:i];
            if ( an.type == ANNOTATION_NOTE )
                [notes addObject:an];
        }
        if (notes.count > 0 )
            return notes;
    }
    return nil;
}

-(JAnnotation*)getAnnotationAtPoint:(NSPoint)point onPage:(int)nPage// withOffset:(CGPoint)ptOffset
{
    NSArray* annots = [self highlightsForPage:nPage];
    if ( annots == nil || [annots count] == 0 )
        return nil;
    
	//NSLog(@"Point X:%f Y%f", point.x, point.y );
	
    for( int i=0; i<[annots count]; i++ )
    {
        JAnnotation* an = [annots objectAtIndex:i];
		//NSLog(@"Rect: %@  %@", NSStringFromRect(an.boundary), an.text );
        if ( NSPointInRect(point, [an boundary]) )
        {
            return an;
        }
    }
    
    return nil;
}

-(BOOL)removeAnnotation:(JAnnotation*)annotation fromPage:(int)nPage
{
    NSMutableArray* annots = (NSMutableArray*)[self highlightsForPage:nPage];
    if ( annots != nil && [annots count] != 0 )
    {
        for( int i=0; i<[annots count]; i++ )
        {
            JAnnotation* an = [annots objectAtIndex:i];
            if ( an == annotation )
            {
                [annots removeObjectAtIndex:i];
                return YES;
            }
        }
    }
    return NO;
}

-(unsigned long)count
{
    unsigned long  nTotal = 0;
    for( int i=0; i<[m_annotations count]; i++ )
    {
        nTotal = [[self annotsForIndex:i] count];
    }
    return nTotal;
}

-(unsigned int)numberOfPages
{
    return [m_annotations count];
}
@end
