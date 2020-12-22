#import <Cocoa/Cocoa.h>


@interface DownloadItem : NSObject <NSTableViewDelegate, NSTableViewDataSource>
{
    NSURL* originalURL;
    NSURL* resolvedFileURL;
    NSImage* iconImage;
}

- (id)initWithOriginalURL:(NSURL *)downloadURL fileURL:(NSURL *)onDiskURL;
- (id)initWithSavedPropertyList:(id)propertyList;

@property(readonly) NSURL* originalURL;
@property(readonly) NSURL* resolvedFileURL;

@property(readonly) NSString* displayName;
@property(readwrite) NSImage* iconImage;

@property(readonly) id propertyListForSaving;

@end
