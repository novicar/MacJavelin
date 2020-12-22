#import "DownloadItem.h"

//#include <QuickLook/QuickLook.h>

static NSString* originalURLKey = @"downloadURL";
static NSString* bookmarkKey = @"bookmark";
static NSOperationQueue* downloadIconQueue = nil;
static NSDictionary* quickLookOptions = nil;

#define ICON_SIZE 48.0

@implementation DownloadItem

- (id)initWithOriginalURL:(NSURL *)downloadURL fileURL:(NSURL *)onDiskURL
{
    self = [super init];
    if (self) {
        originalURL = downloadURL;
        resolvedFileURL = onDiskURL;
    }
    return self;
}

- (id)initWithSavedPropertyList:(id)propertyList
{
    self = [super init];
    if (self) {
        if (![propertyList isKindOfClass:[NSDictionary class]]) {
            //[self release];
            return nil;
        }
        
        NSString* originalURLString = [propertyList objectForKey:originalURLKey];
        if (!originalURLString || ![originalURLString isKindOfClass:[NSString class]]) {
            //[self release];
            return nil;
        }
        
        originalURL = [[NSURL alloc] initWithString:originalURLString];
        if (!originalURL) {
            //[self release];
            return nil;
        }
        
        NSData* bookmarkData = [propertyList objectForKey:bookmarkKey];
        if (!bookmarkData || ![bookmarkData isKindOfClass:[NSData class]]) {
            //[self release];
            return nil;
        }
        
        // test if the file still exists
        resolvedFileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                                     options:(NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting)
                                               relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
        if (!resolvedFileURL) {
            //[self release];
            return nil;
        }
    }
    
    return self;
}
/*
- (void)dealloc
{
    [originalURL release];
    [resolvedFileURL release];
    [iconImage release];
    [super dealloc];
}
*/
@synthesize originalURL, resolvedFileURL, iconImage;

- (NSImage *)iconImage
{
    if (iconImage == nil) {
        iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[resolvedFileURL path]];
        [iconImage setSize:NSMakeSize(ICON_SIZE, ICON_SIZE)];
        if (!downloadIconQueue) {
            downloadIconQueue = [[NSOperationQueue alloc] init];
            [downloadIconQueue setMaxConcurrentOperationCount:2];
            //quickLookOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
            //                    (id)kCFBooleanTrue, (id)kQLThumbnailOptionIconModeKey,
             //                   nil];
        }
//        [downloadIconQueue addOperationWithBlock:^{
//           CGImageRef quickLookIcon = QLThumbnailImageCreate(NULL, (CFURLRef)resolvedFileURL, CGSizeMake(ICON_SIZE, ICON_SIZE), (CFDictionaryRef)quickLookOptions);
//            if (quickLookIcon != NULL) {
 //               NSImage* betterIcon = [[NSImage alloc] initWithCGImage:quickLookIcon size:NSMakeSize(ICON_SIZE, ICON_SIZE)];
 //               [self performSelectorOnMainThread:@selector(setIconImage:) withObject:betterIcon waitUntilDone:NO];
 //               [betterIcon release];
 //               CFRelease(quickLookIcon);
 //           }
 //       }];
    }
    return iconImage;
}

- (NSString *)displayName
{
    return [[resolvedFileURL path] lastPathComponent];
}

- (id)propertyListForSaving
{
    NSData* bookmarkData = [resolvedFileURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
    if (!bookmarkData) {
        return nil;
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [originalURL absoluteString], originalURLKey,
            bookmarkData, bookmarkKey,
            nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %@ (from %@)>", [self class], resolvedFileURL, originalURL];
}

@end
