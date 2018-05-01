//
//  WSImageDecoder.h
//  YYTest_ws
//
//  Created by great Lock on 2018/4/4.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WSImageType) {
    WSImageTypeUnknow = 0,
    WSImageTypeJPEG,
    WSImageTypeJPEG2000,
    WSImageTypeTIFF,
    WSImageTypeBMP,
    WSImageTypeICO,
    WSImageTypeICNS,
    WSImageTypeGIF,
    WSImageTypePNG,
    WSImageTypeWebP,
    WSImageTypeOther,
};

typedef NS_ENUM(NSUInteger, WSImageDisposeMethod) {
    WSImageDisposeNone = 0,
    WSImageDisposeBackground,
    WSImageDisposePrevious,
};

typedef NS_ENUM(NSUInteger, WSImageBlendOperation) {
    WSImageBlendNone = 0,
    WSImageBlendOver,
};

@interface WSImageFrame: NSObject<NSCopying>
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nonatomic) NSUInteger offsetX;
@property (nonatomic) NSUInteger offsetY;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) WSImageDisposeMethod dispose;
@property (nonatomic) WSImageBlendOperation blend;
@property (nullable, nonatomic, strong) UIImage *image;
+ (instancetype)frameWithImage:(UIImage *)image;
@end


@interface WSImageDecoder : NSObject

@property (nullable, nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) WSImageType type;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly) NSUInteger frameCount;
@property (nonatomic, readonly) NSUInteger loopCount;
@property (nonatomic, readonly) NSUInteger width;
@property (nonatomic, readonly) NSUInteger height;
@property (nonatomic, readonly, getter=isFinished) BOOL finalized;

+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale;

- (instancetype)initWithScale:(CGFloat)scale NS_DESIGNATED_INITIALIZER;

- (nullable WSImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index;
@end


#pragma mark - image
@interface UIImage (WSImageCoder)

- (instancetype)imageByDecoded;

@property (nonatomic) BOOL isDecodedForDisplay;
@end


NS_ASSUME_NONNULL_END
