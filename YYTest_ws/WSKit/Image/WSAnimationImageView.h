//
//  WSAnimationImageView.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSAnimationImageView : UIImageView

@property (nonatomic, assign) NSUInteger currentAnimatedImageIndex;

@property (nonatomic, copy) NSString *runloopMode;

@property (nonatomic, assign) BOOL autoPlayAnimatedImage;
@end


@protocol WSAnimatedImage <NSObject>
@required
- (NSUInteger)animateImageFrameCount;

- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;

- (CGRect)animatedImageContentsRectAtIndex:(NSUInteger)index;

@end
