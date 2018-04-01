//
//  WSImageExampleHelper.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSImageExampleHelper.h"

@implementation WSImageExampleHelper

+ (void)addTapControlToAnimationedImageView:(WSAnimationImageView *)view {
    if (!view) return;
    view.userInteractionEnabled = true;
    __weak typeof(view) _view = view;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
        if ([_view isAnimating]) [_view stopAnimating];
        else [_view startAnimating];
        
        ///??? 后边两种都不知道是啥
        UIViewAnimationOptions op =UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState;
        
        [UIView animateWithDuration:0.1 delay:0 options:op animations:^{
            _view.layer.transformScale = 0.97;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0 options:op animations:^{
                _view.layer.transformScale = 1.008;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0 options:op animations:^{
                    _view.layer.transformScale = 1;
                } completion:NULL];
            }];
        }];
    }];
    [view addGestureRecognizer:tap];
}

+ (void)addPanControlToAnimationedImageView:(WSAnimationImageView *)view {
    if (!view) return;
    view.userInteractionEnabled = true;
    __weak typeof(view) _view = view;
    __block BOOL previousIsPlaying;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithActionBlock:^(id sender) {
        UIImage<WSAnimatedImage> *image = (id)_view.image;
        if (![image conformsToProtocol:@protocol(WSAnimatedImage)]) return;
        UIPanGestureRecognizer *gesture = sender;
        CGPoint p = [gesture locationInView:gesture.view];
        CGFloat progress = p.x / gesture.view.width;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            previousIsPlaying = [_view isAnimating];
            [_view stopAnimating];
            _view.currentAnimatedImageIndex = image.animateImageFrameCount * progress;
        }else if (gesture.state == UIGestureRecognizerStateEnded ||
                  gesture.state == UIGestureRecognizerStateCancelled) {
            if (previousIsPlaying) [_view startAnimating];
        }else {
            _view.currentAnimatedImageIndex = image.animateImageFrameCount * progress;
        }
    }];
    [view addGestureRecognizer:pan];
}
@end
