//
//  WSFrameImage.h
//  YYTest_ws
//
//  Created by great Lock on 2018/5/13.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSAnimationImageView.h"

@interface WSFrameImage : UIImage<WSAnimatedImage>


- (instancetype)initWithImagePaths:(NSArray<NSString *> *)paths
                  oneFrameDuration:(NSTimeInterval)oneFrameDuration
                         loopCount:(NSUInteger)loopCount;

- (instancetype)initWithImagePaths:(NSArray<NSString *> *)paths
                    frameDurations:(NSArray<NSNumber *> *)frameDurations
                         loopCount:(NSUInteger)loopCount;

- (instancetype)initWithImageDataArray:(NSArray<NSData *> *)dataArray
                      oneFrameDuration:(NSTimeInterval)oneFrameDuration
                             loopCount:(NSUInteger)loopCount;

- (instancetype)initWithImageDataArray:(NSArray<NSData *> *)dataArray
                        frameDurations:(NSArray<NSNumber *> *)frameDurations
                             loopCount:(NSUInteger)loopCount;

@end
