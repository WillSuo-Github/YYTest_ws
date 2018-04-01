//
//  WSAnimationImageView.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSAnimationImageView.h"
#import "WSKit.h"

#define LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);\
__VA_ARGS__;\
dispatch_semaphore_signal(self->_lock);

@interface WSAnimationImageView () {
    @package
    UIImage<WSAnimatedImage> *_curAnimatedImage;
    
    dispatch_semaphore_t _lock;
    NSOperationQueue *_requestQueue;
    
    CADisplayLink *_link;
    NSTimeInterval _time;
    
    UIImage *_curFrame;
    NSUInteger _curIndex;
    
    BOOL _loopEnd;
    NSUInteger _curLoop;
    NSUInteger _totalLoop;
    
    NSMutableDictionary *_buffer;
    BOOL _bufferMiss;
    
    CGRect _curContentsRect;
    BOOL _curImageHasContentsRect;
}

@end


@implementation WSAnimationImageView

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = true;
    self.frame = (CGRect) {CGPointZero, image.size};
    self.image = image;
    return self;
}

- (void)setCurrentAnimatedImageIndex:(NSUInteger)currentAnimatedImageIndex {
    if (!_curAnimatedImage) return;
    if (currentAnimatedImageIndex >= _curAnimatedImage.animateImageFrameCount) return;
    if (_curIndex == currentAnimatedImageIndex) return;
    
    dispatch_async_on_main_queue(^{
        LOCK(
             [_requestQueue cancelAllOperations];
             [_buffer removeAllObjects];
             [self willChangeValueForKey:@"currentAnimatedImageIndex"];
             _curIndex = currentAnimatedImageIndex;
             [self didChangeValueForKey:@"currentAnimatedImageIndex"];
             _curFrame = [_curAnimatedImage animatedImageFrameAtIndex:_curIndex];
             if (_curImageHasContentsRect) {
                 _curContentsRect = [_curAnimatedImage animatedImageContentsRectAtIndex:_curIndex];
             }
             _time = 0;
             _loopEnd = false;
             _bufferMiss = false;
             [self.layer setNeedsDisplay];
        )
    });
}

- (NSUInteger)currentAnimatedImageIndex {
    return _curIndex;
}

- (void)setRunloopMode:(NSString *)runloopMode {
    if ([_runloopMode isEqual:runloopMode]) return;
    if (_link) {
        if (_runloopMode) {
            [_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_runloopMode];
        }
        if (runloopMode.length) {
            [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:_runloopMode];
        }
    }
    _runloopMode = runloopMode.copy;
}

@end
