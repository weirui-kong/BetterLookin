//
//  LKExportManager.m
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

#import "LKExportManager.h"
#import "LookinHierarchyInfo.h"
#import "LookinHierarchyFile.h"
#import "LookinAppInfo.h"
#import "LookinDisplayItem.h"
#import "LookinDocument.h"
#import "LKHelper.h"
#import "LKNavigationManager.h"
#import "LookinDisplayItem.h"

@implementation LKExportManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LKExportManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (NSData *)dataFromHierarchyInfo:(LookinHierarchyInfo *)info imageCompression:(CGFloat)compression fileName:(NSString **)fileName {
    LookinHierarchyFile *file = [LookinHierarchyFile new];
    file.serverVersion = info.serverVersion;
    file.hierarchyInfo = info;
    
    NSMutableDictionary<NSString *, NSData *> *soloScreenshots = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSData *> *groupScreenshots = [NSMutableDictionary dictionary];
    
    NSArray<LookinDisplayItem *> *allItems = [LookinDisplayItem flatItemsFromHierarchicalItems:info.displayItems];
    [allItems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull displayItem, NSUInteger idx, BOOL * _Nonnull stop) {
        displayItem.screenshotEncodeType = LookinDisplayItemImageEncodeTypeNone;
        soloScreenshots[@(displayItem.layerObject.oid)] = [self _compressedDataFromImage:displayItem.soloScreenshot compression:compression];
        groupScreenshots[@(displayItem.layerObject.oid)] = [self _compressedDataFromImage:displayItem.groupScreenshot compression:compression];
    }];
    file.soloScreenshots = soloScreenshots.copy;
    file.groupScreenshots = groupScreenshots.copy;
    
    LookinDocument *document = [[LookinDocument alloc] init];
    document.hierarchyFile = file;
    NSError *error;
    NSData *exportedData = [document dataOfType:@"com.lookin.lookin" error:&error];
    if (error) {
        NSAssert(NO, @"");
    }
    
    if (fileName) {
        NSString *timeString = ({
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMddHHmm"];
            [formatter stringFromDate:date];
        });
        NSString *iOSVersion = ({
            NSString *str = info.appInfo.osDescription;
            NSUInteger dotIdx = [str rangeOfString:@"."].location;
            if (dotIdx != NSNotFound) {
                str = [str substringToIndex:dotIdx];
            }
            str;
        });
        *fileName = [NSString stringWithFormat:@"%@_ios%@_%@.lookin", info.appInfo.appName, iOSVersion, timeString];
        
    }
    
    return exportedData;
}

/// compression 范围从 0.01 ~ 1
- (NSData *)_compressedDataFromImage:(LookinImage *)sourceImage compression:(CGFloat)compression {
    if (!sourceImage) {
        return nil;
    }
    
#if TARGET_OS_IPHONE
    return nil;
    
#elif TARGET_OS_MAC
    
    compression = MAX(MIN(compression, 1), 0.01);
    
    NSSize targetSize = NSMakeSize(sourceImage.size.width * compression, sourceImage.size.height * compression);
    NSRect targetFrame = NSMakeRect(0, 0, targetSize.width, targetSize.height);
    NSImageRep *sourceImageRep = [sourceImage bestRepresentationForRect:targetFrame context:nil hints:nil];
    
    NSImage *resizedImage = [[NSImage alloc] initWithSize:targetSize];
    [resizedImage lockFocus];
    [sourceImageRep drawInRect:targetFrame];
    [resizedImage unlockFocus];
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[resizedImage TIFFRepresentation]];
    NSData *compressedData = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1];
    return compressedData;
#endif
}

+ (void)exportScreenshotWithDisplayItem:(LookinDisplayItem *)displayItem {
    NSImage *image = displayItem.groupScreenshot;
    if (!image) {
        AlertError(LookinErr_Inner, CurrentKeyWindow);
        return;
    }
    
    NSData *imageData = [image TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1];
    if (!imageData) {
        AlertError(LookinErr_Inner, CurrentKeyWindow);
        return;
    }
    
    NSString *fileName = [displayItem title] ? : @"LookinImage";

    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:fileName];
    [panel setAllowsOtherFileTypes:NO];
    [panel setAllowedFileTypes:@[@"tiff"]];
    [panel setExtensionHidden:YES];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:CurrentKeyWindow completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSString *path = [[panel URL] path];
            NSError *writeError;
            BOOL writeSucc = [imageData writeToFile:path options:0 error:&writeError];
            if (!writeSucc) {
                AlertError(writeError, CurrentKeyWindow);
                NSAssert(NO, @"");
            }
        }
    }];
}

+ (NSInteger)nativeScaleForDisplayItem:(LookinDisplayItem *)displayItem {
    NSImage *image = displayItem.groupScreenshot;
    CGFloat pointWidth = displayItem.frame.size.width;
    if (!image || pointWidth <= 0) {
        return 0;
    }
    CGFloat scale = image.size.width / pointWidth;
    return MAX((NSInteger)round(scale), 1);
}

+ (NSSize)pixelSizeForDisplayItem:(LookinDisplayItem *)displayItem scale:(NSInteger)scale {
    return NSMakeSize(displayItem.frame.size.width * scale, displayItem.frame.size.height * scale);
}

+ (void)copyScreenshotAsPNGWithDisplayItem:(LookinDisplayItem *)displayItem scale:(NSInteger)scale {
    NSImage *sourceImage = displayItem.groupScreenshot;
    if (!sourceImage) {
        AlertError(LookinErr_Inner, CurrentKeyWindow);
        return;
    }

    NSSize targetSize = [self pixelSizeForDisplayItem:displayItem scale:scale];
    if (targetSize.width <= 0 || targetSize.height <= 0) {
        AlertError(LookinErr_Inner, CurrentKeyWindow);
        return;
    }

    NSImage *imageToCopy = sourceImage;
    if (!NSEqualSizes(targetSize, sourceImage.size)) {
        NSRect targetFrame = NSMakeRect(0, 0, targetSize.width, targetSize.height);
        NSImageRep *sourceImageRep = [sourceImage bestRepresentationForRect:targetFrame context:nil hints:nil];

        NSImage *resizedImage = [[NSImage alloc] initWithSize:targetSize];
        [resizedImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImageRep drawInRect:targetFrame];
        [resizedImage unlockFocus];
        imageToCopy = resizedImage;
    }

    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:[imageToCopy TIFFRepresentation]];
    NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    if (!pngData) {
        AlertError(LookinErr_Inner, CurrentKeyWindow);
        return;
    }

    NSPasteboard *paste = [NSPasteboard generalPasteboard];
    [paste clearContents];
    [paste setData:pngData forType:NSPasteboardTypePNG];
}

@end
