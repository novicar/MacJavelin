//
//  JAnnotations.h
//  JavelinM
//
//  Created by Novica Radonic on 02/05/2017.
//
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "JAnnotation.h"
#import "JavelinDocument.h"

@interface JAnnotations : NSObject
{
    NSMutableDictionary* m_annotations;
    JavelinDocument* m_pDocument;
}

-(void) addHighlight:(JAnnotation* )ann toPage:(int)nPage;
-(BOOL) save:(NSURL*) sFile;
-(NSArray*) highlightsForPage:(int)nPage;
- (NSURL*)getNtsUrl:(NSURL *)docURL;
-(JAnnotation*)getAnnotationAtPoint:(NSPoint)point onPage:(int)nPage;// withOffset:(CGPoint)ptOffset;
-(BOOL)removeAnnotation:(JAnnotation*)annotation fromPage:(int)nPage;
-(id)initWithDocument:(JavelinDocument*)document;
-(unsigned long)count;

-(NSArray*) annotsForIndex:(int)nIndex;
-(unsigned int)numberOfPages;
-(NSArray*) notesForIndex:(int)nIndex;
@end
