//
//  WSImage.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSImage.h"
#import "WSKit.h"

@implementation WSImage {
    WSImageDecoder *_decoder;
    NSArray *_preloadedFrames;
    dispatch_semaphore_t _preloadedLock;
    NSUInteger _bytesPerFrame;
}

+ (WSImage *)imageNamed:(NSString *)name {
    if (name.length == 0) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = [NSBundle preferredScales];
    for (unsigned int s = 0; s < scales.count; s ++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaleName = [res stringByAppendingNameScale:scale];
        for (NSString *e in exts) {
            path = [[NSBundle mainBundle] pathForResource:scaleName ofType:e];
            if (path) break;
        }
        if (path) break;
    }
    if (path.length == 0) return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) return nil;
    
    return [[self alloc] initWithData:data scale:scale];
}

#pragma mark - protocol WSAnimatedImage
- (NSUInteger)animateImageFrameCount {
    return _decoder.frameCount;
}

- (NSUInteger)animatedImageLoopCount {
    return _decoder.loopCount;
}

- (NSUInteger)animatedImageBytesPerFrame {
    return _bytesPerFrame;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= _decoder.frameCount) return nil;
    dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
    UIImage *image = _preloadedFrames[index];
    dispatch_semaphore_signal(_preloadedLock);
    if (image) return image == (id)[NSNull null] ? nil : image;
    return [_decoder ]
}

@end
