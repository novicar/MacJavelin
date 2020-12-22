//
//  AnnotationPanel.h
//  JavelinM
//
//  Created by harry on 30/01/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


// Notification.
extern NSString *AnnotationPanelAnnotationDidChangeNotification;

@interface AnnotationPanel : NSPanel
{
	IBOutlet NSPanel		*_annotationPanel;
	PDFAnnotation*			_annotation;
	IBOutlet NSTextView*	_myText;
	IBOutlet NSButton*		_btnDelete;
	IBOutlet NSButton*		_btnEdit;
}

- (IBAction) deleteNote:(id)sender;
- (IBAction) editNote:(id)sender;

+ (AnnotationPanel *) sharedAnnotationPanel;
- (void) setAnnotation: (PDFAnnotation *) annotation;
- (void) updateAnnotationSubtypeAndAttributes;
@end
