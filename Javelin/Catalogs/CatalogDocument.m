//
//  CatalogDocument.m
//  Javelin3
//
//  Created by Novica Radonic on 02/05/2018.
//

#import "CatalogDocument.h"

NSString* const CatDocumentUTI = @"com.drumlinsecurity.xml";

@implementation CatalogDocument

@synthesize prot;

/*
- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return <#nibName#>;
}
*/
/*
- (void)showWindows
{
	[m_catalogWindowController showWindow:[m_catalogWindowController window]];
}
*/
- (NSString *)windowNibName
{
	return @"CatalogView";
}

- (void) makeWindowControllers
{
	m_catalogWindowController = [[CatalogWindowController alloc] init];
	[self addWindowController: m_catalogWindowController];
	
	return;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
	return YES;
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
/*	if (outError) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
	}*/
//	NSFileWrapper* w1 = [[NSFileWrapper alloc] initWithURL:url options:NSFileWrapperReadingImmediate error:outError];
	return YES;
		
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	//[self writeToURL:[self fileURL] ofType:DwnDocumentUTI error:nil];
	//[self updateChangeCount:NSSaveOperation];
	//[self saveDocument:self];
/*	if ( prot )
	{
		
		[prot catalogWindowClosed];
	}*/
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}
+ (BOOL)autosavesInPlace {
    return YES;
}

@end
