//
//  JavelinDocument.m
//  Javelin
//
//  Created by harry on 8/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JavelinDocument.h"
#import "JavelinController.h"

@implementation JavelinDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    _fileContents = nil;
    return self;
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"JavelinDocument";
}

- (void) makeWindowControllers
{
    JavelinController	*controller;
    
    // Create controller.
    controller = [[JavelinController alloc] initWithWindowNibName: [self windowNibName]];
    [self addWindowController: controller];
    
    // Done.
    [controller release];
    
    return;
}

/*
- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)type
{
    //just check file type. The actual file read will be done in
    //JavelinController
    if ( [type caseInsensitiveCompare:@"pdf"] == NSOrderedSame )
        return YES;
    else if ( [type caseInsensitiveCompare:@"drmx"] == NSOrderedSame )
        return YES;
    
    return NO;
}
*/


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( [typeName caseInsensitiveCompare:@"PDF Document"] == NSOrderedSame ) return YES;
    if ( [typeName caseInsensitiveCompare:@"Javelin Document"] == NSOrderedSame ) return YES;
    return NO;
}

- (NSAttributedString*)getFileContents
{
    return _fileContents;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}
/*
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
   
//Insert code here to read your document from the given data of the specified type. 
//If outError != NULL, ensure that you create and set an appropriate error when returning NO.
//You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}
*/
@end
