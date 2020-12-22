//
//  AnnotationPanel.m
//  JavelinM
//
//  Created by harry on 30/01/2015.
//
//

#import "AnnotationPanel.h"
// Global instance.
AnnotationPanel		*gAnnotationPanel = NULL;


NSString *AnnotationPanelAnnotationDidChangeNotification = @"AnnotationPanelAnnotationDidChange";

@interface AnnotationPanel(AnnotationPanelPriv)
- (void) updateAnnotationSubtypeAndAttributes;
@end

@implementation AnnotationPanel
- (id) init
{
	// Super.
	id myself = [super init];
	
	// Lazily load the annotation panel.
	if (_annotationPanel == NULL)
	{
		BOOL		loaded;
		
		loaded = [NSBundle loadNibNamed: @"AnnotationPanel" owner: self];
		//require(loaded == YES, bail);
	}
	
	// Display.
	[_annotationPanel makeKeyAndOrderFront: self];
	
	// Set up UI.
	[self updateAnnotationSubtypeAndAttributes];
	
	// Success.
	myself = self;
	
bail:
	
	return myself;
}

+ (AnnotationPanel *) sharedAnnotationPanel
{
	// Create if it does not exist.
	if (gAnnotationPanel == NULL)
		gAnnotationPanel = [[AnnotationPanel alloc] init];
	
	return gAnnotationPanel;
}

- (void) updateAnnotationSubtypeAndAttributes
{
	if (_annotation == NULL || [_annotation isKindOfClass: [PDFAnnotationText class]] == NO )
	{
		[_myText setString:@"" ];
		return;
	}
	NSString* s = [_annotation contents];
	//NSLog(@"-->%@", s );
	
	[_myText setString:s];
}

- (void) setAnnotation: (PDFAnnotation *) annotation
{
	// Release old.
	if (_annotation != annotation)
		_annotation = nil;
	
	// Assign.
	_annotation = annotation;
	//NSLog(@"setAnnotation: %@", [_annotation contents]);
	
	// Update.
	[self updateAnnotationSubtypeAndAttributes];
}

- (NSPanel *) panel
{
	return _annotationPanel;
}

- (IBAction) deleteNote:(id)sender
{
}

- (IBAction) editNote:(id)sender
{
	if( _annotation == NULL ) return;
	
	[_annotation setContents:[_myText string]];
	[[NSNotificationCenter defaultCenter] postNotificationName: AnnotationPanelAnnotationDidChangeNotification 
			object: self userInfo: [NSDictionary dictionaryWithObject: _annotation forKey: @"PDFAnnotation"]];
	_annotation = nil;
	[self updateAnnotationSubtypeAndAttributes];
}

@end
