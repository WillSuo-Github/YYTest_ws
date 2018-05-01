//
//  UIDevice+WSAdd.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (WSAdd)

+ (double)systemVersion;

#pragma mark - Memory Information

@property (nonatomic, readonly) int64_t memoryTotal;

@property (nonatomic, readonly) int64_t memoryUsed;

@property (nonatomic, readonly) int64_t memoryFree;

@property (nonatomic, readonly) int64_t memoryActive;

@property (nonatomic, readonly) int64_t memoryInactive;

@property (nonatomic, readonly) int64_t memoryWired;

@property (nonatomic, readonly) int64_t memoryPurgable;
@end


#ifndef kSystemVersion
#define kSystemVersion [UIDevice systemVersion]
#endif
