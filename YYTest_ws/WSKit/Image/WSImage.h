//
//  WSImage.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSAnimationImageView.h"
#import "WSImageCoder.h"

@interface WSImage : UIImage <WSAnimatedImage>

@property (nonatomic, readonly) WSImageType animatedImageType;

@property (nonatomic, readonly) NSUInteger animatedImageMemorySize;

+ (nullable WSImage *)imageNamed:(NSString *)name;

@end
