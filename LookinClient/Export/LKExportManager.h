//
//  LKExportManager.h
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LookinHierarchyInfo, LookinDisplayItem;

@interface LKExportManager : NSObject

+ (instancetype)sharedInstance;

- (NSData *)dataFromHierarchyInfo:(LookinHierarchyInfo *)info imageCompression:(CGFloat)compression fileName:(NSString **)fileName;

+ (void)exportScreenshotWithDisplayItem:(LookinDisplayItem *)displayItem;

// 截图没有携带倍率信息，这里用像素尺寸和 frame 的比例反推
+ (NSInteger)nativeScaleForDisplayItem:(LookinDisplayItem *)displayItem;

+ (NSSize)pixelSizeForDisplayItem:(LookinDisplayItem *)displayItem scale:(NSInteger)scale;

+ (void)copyScreenshotAsPNGWithDisplayItem:(LookinDisplayItem *)displayItem scale:(NSInteger)scale;

@end
