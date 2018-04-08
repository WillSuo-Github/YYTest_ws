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

typedef NS_ENUM(NSUInteger, WSAnimationImageType) {
    WSAnimationImageTypeNone = 0,
    WSAnimationImageTypeImage,
    WSAnimationImageTypeHighlightedImage,
    WSAnimationImageTypeImages,
    WSAnimationImageTypeHighlightedImages,
};

@interface WSAnimationImageView () {
    @package
    UIImage<WSAnimatedImage> *_curAnimatedImage;
    
    dispatch_semaphore_t _lock;
    NSOperationQueue *_requestQueue;
    
    CADisplayLink *_link;
    NSTimeInterval _time;
    
    UIImage *_curFrame;
    NSUInteger _curIndex;
    NSUInteger _totalFrameCount;
    
    BOOL _loopEnd;
    NSUInteger _curLoop;
    NSUInteger _totalLoop;
    
    NSMutableDictionary *_buffer;
    BOOL _bufferMiss;
    NSUInteger _maxBufferCount;
    NSInteger _incrBufferCount;
    
    CGRect _curContentsRect;
    BOOL _curImageHasContentsRect;
}

@end


@implementation WSAnimationImageView

- (instancetype)init {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = true;
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = true;
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = true;
    self.frame = (CGRect) {CGPointZero, image.size};
    self.image = image;
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    self = [super init];
    _runloopMode = NSRunLoopCommonModes;
    _autoPlayAnimatedImage = true;
    CGSize size = image ? image.size : highlightedImage.size;
    self.frame = (CGRect){CGPointZero, size};
    self.image = image;
    self.highlightedImage = highlightedImage;
    return self;
}


- (void)setImage:(UIImage *)image {
    if (self.image == image) return;
    
}

- (void)resetAnimated {
    if (!_link) {
        _lock = dispatch_semaphore_create(1);
        _buffer = [NSMutableDictionary new];
        _requestQueue = [NSOperationQueue new];
        _requestQueue.maxConcurrentOperationCount = 1;
        _link = [CADisplayLink displayLinkWithTarget:[WSWeakProxy proxyWithTarget:self] selector:@selector(step:)];
        if (_runloopMode) {
            [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:_runloopMode];
        }
        _link.paused = true;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    [_requestQueue cancelAllOperations];
    LOCK(
         if (_buffer.count) {
             NSMutableDictionary *holder = _buffer;
             _buffer = [NSMutableDictionary new];
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                 ///??? 项目中总是空调 class方法是为啥
                 [holder class];
             });
         }
    );
    _link.paused = true;
    _time = 0;
    if (_curIndex != 0) {
        [self willChangeValueForKey:@"currentAnimatedImageIndex"];
        _curIndex = 0;
        [self didChangeValueForKey:@"currentAnimatedImageIndex"];
    }
    _curAnimatedImage = nil;
    _curFrame = nil;
    _curLoop = 0;
    _totalLoop = 0;
    _totalFrameCount = 1;
    _loopEnd = false;
    _bufferMiss = false;
    _incrBufferCount = 0;
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

- (id)imageForType:(WSAnimationImageType)type {
    switch (type) {
        case WSAnimationImageTypeNone: return nil;
        case WSAnimationImageTypeImage: return self.image;
        case WSAnimationImageTypeImages: return self.animationImages;
        case WSAnimationImageTypeHighlightedImage: return self.highlightedImage;
        case WSAnimationImageTypeHighlightedImages: return self.highlightedAnimationImages;
    }
    return nil;
}

- (WSAnimationImageType)currentImageType {
    WSAnimationImageType curType = WSAnimationImageTypeNone;
    if (self.highlighted) {
        if (self.highlightedAnimationImages.count) curType = WSAnimationImageTypeHighlightedImages;
        else if (self.highlightedImage) curType = WSAnimationImageTypeHighlightedImage;
    }
    if (curType == WSAnimationImageTypeNone) {
        if (self.animationImages.count) curType = WSAnimationImageTypeImages;
        else if (self.image) curType = WSAnimationImageTypeImage;
    }
    return curType;
}

- (void)setImage:(id)image withType:(WSAnimationImageType)type {
    [self stopAnimating];
    if (_link) [self resetAnimated];
    _curFrame = nil;
    switch (type) {
        case WSAnimationImageTypeNone: break;
        case WSAnimationImageTypeImage: super.image = image; break;
        case WSAnimationImageTypeHighlightedImage: super.highlightedImage = image; break;
        case WSAnimationImageTypeImages: super.animationImages = image; break;
        case WSAnimationImageTypeHighlightedImages: super.highlightedAnimationImages = image; break;
    }
    
}

- (void)imageChanged {
    WSAnimationImageType newType = [self currentImageType];
    id newVisibleImage = [self imageForType:newType];
    NSUInteger newImageFrameCount = 0;
    BOOL hasContentsRect = false;
    if ([newVisibleImage isKindOfClass:[UIImage class]] &&
        [newVisibleImage conformsToProtocol:@protocol(WSAnimatedImage)]) {
        newImageFrameCount = ((UIImage<WSAnimatedImage> *) newVisibleImage).animateImageFrameCount;
        if (newImageFrameCount > 1) {
            hasContentsRect = [((UIImage<WSAnimatedImage> *) newVisibleImage) respondsToSelector:@selector(animatedImageContentsRectAtIndex:)];
        }
    }
    if (!hasContentsRect && _curImageHasContentsRect) {
        if (!CGRectEqualToRect(self.layer.contentsRect, CGRectMake(0, 0, 1, 1))) {
            [CATransaction begin];
            [CATransaction setDisableActions:true];
            self.layer.contentsRect = CGRectMake(0, 0, 1, 1);
            [CATransaction commit];
        }
    }
    
    _curImageHasContentsRect = hasContentsRect;
    if (hasContentsRect) {
        CGRect rect = [((UIImage<WSAnimatedImage> *) newVisibleImage) animatedImageContentsRectAtIndex:0];
        [self setContentsRect:rect forImage:newVisibleImage];
    }
    
    if (newImageFrameCount > 1) {
        [self resetAnimated];
        _curAnimatedImage = newVisibleImage;
        _curFrame = newVisibleImage;
        _totalLoop = _curAnimatedImage.animatedImageLoopCount;
        _totalFrameCount = _curAnimatedImage.animateImageFrameCount;
        self
    }
}

- (void)calcMaxBufferCount {
    int64_t bytes = (int64_t)_curAnimatedImage.animateImageFrameCount
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

- (void)setContentsRect:(CGRect)rect forImage:(UIImage *)image {
    CGRect layerRect = CGRectMake(0, 0, 1, 1);
    if (image) {
        CGSize imageSize = image.size;
        if (imageSize.width > 0.01 && imageSize.height > 0.01) {
            layerRect.origin.x = rect.origin.x / imageSize.width;
            layerRect.origin.y = rect.origin.y / imageSize.height;
            layerRect.size.width = rect.size.width / imageSize.width;
            layerRect.size.height = rect.size.height / imageSize.height;
            if (CGRectIsNull(layerRect) || CGRectIsEmpty(layerRect)) {
                layerRect = CGRectMake(0, 0, 1, 1);
            }
        }
    }
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    self.layer.contentsRect = layerRect;
    [CATransaction commit];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    
}

- (void)didEnterBackground:(NSNotification *)notification {
    
}

@end
