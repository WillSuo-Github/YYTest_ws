//
//  WSImageDecoder.m
//  YYTest_ws
//
//  Created by great Lock on 2018/4/4.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSImageCoder.h"
#import "WSKitMacro.h"
#import <CoreFoundation/CoreFoundation.h>
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>
#import <pthread.h>
#import <zlib.h>

#ifndef WSIMAGE_WEBP_ENABLED
#if __has_include(<webp/decode.h>) && __has_include(<webp/encode.h>) && \
__has_include(<webp/demux.h>) && __has_include(<web/mux.h>)
#define WSIMAGE_WEBP_ENABLED 1
#import <webp/decode.h>
#import <webp/encode.h>
#import <webp/demux.h>
#import <webp/mux.h>
#elif __has_include("webp/decode.h") && __has_include("webp/encode.h") && \
__has_include("webp/demux.h") && __has_include("webp/mux.h")
#define WSIMAGE_WEBP_ENABLED 1
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#else
#define WSIMAGE_WEBP_ENABLED 0
#endif
#endif


#pragma mark - Utility (for little endian platform)

#define WS_FOUR_CC(c1, c2, c3, c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define WS_TWO_CC(c1, c2) ((uint16_t)(((c2) << 8) | (c1)))

static inline uint16_t ws_swap_endian_uint16(uint16_t value) {
    return (uint16_t) ((value & 0x00FF) <<8) | (uint16_t) ((value & 0xFF00) >> 8);
}

static inline uint32_t ws_swap_endian_uint32(uint32_t value) {
    return
    (uint32_t)((value & 0x000000FFU) << 24) |
    (uint32_t)((value & 0x0000FF00U) <<  8) |
    (uint32_t)((value & 0x00FF0000U) >>  8) |
    (uint32_t)((value & 0xFF000000U) >> 24) ;
}

typedef enum {
    WS_PNG_ALPHA_TYPE_PALEETE = 1 << 0,
    WS_PNG_ALPHA_TYPE_COLOR = 1 << 1,
    WS_PNG_ALPHA_TYPE_ALPHA = 1 << 2,
} ws_png_alpha_type;

typedef enum {
    WS_PNG_DISPOSE_OP_NONE = 0,
    WS_PNG_DISPOSE_OP_BACKGROUND = 1,
    WS_PNG_DISPOSE_OP_PREVIOUS = 2,
} ws_png_dispose_op;

typedef enum {
    WS_PNG_BLEND_OP_SOURCE = 0,
    WS_PNG_BLEND_OP_OVER = 1,
} ws_png_blend_op;

typedef struct {
    uint32_t width;
    uint32_t height;
    uint8_t bit_depth;
    uint8_t color_type;
    uint8_t compression_method;
    uint8_t filter_method;
    uint8_t interlace_method;
} ws_png_chunk_IHDR;

typedef struct {
    uint32_t sequence_number;
    uint32_t width;
    uint32_t height;
    uint32_t x_offset;
    uint32_t y_offset;
    uint16_t delay_num;
    uint16_t delay_den;
    uint8_t dispose_op;
    uint8_t blend_op;
} ws_png_chunk_fcTL;

typedef struct {
    uint32_t offset;
    uint32_t fourcc;
    uint32_t length;
    uint32_t crc32;
} ws_png_chunk_info;

typedef struct {
    uint32_t chunk_index;
    uint32_t chunk_num;
    uint32_t chunk_size;
    ws_png_chunk_fcTL frame_control;
} ws_png_frame_info;

typedef struct {
    ws_png_chunk_IHDR header;
    ws_png_chunk_info *chunks;
    uint32_t chunk_num;
    
    ws_png_frame_info *apng_frames;
    uint32_t apng_frame_num;
    uint32_t apng_loop_num;
    
    uint32_t *apng_shared_chunk_indexs;
    uint32_t apng_shared_chunk_num;
    uint32_t apng_shared_chunk_size;
    uint32_t apng_shared_insert_index;
    bool apng_first_frame_is_cover;
} ws_png_info;

static void ws_png_chunk_IHDR_write(ws_png_chunk_IHDR *IHDR, uint8_t *data) {
    *((uint32_t *)(data)) = ws_swap_endian_uint32(IHDR->width);
    *((uint32_t *)(data + 4)) = ws_swap_endian_uint32(IHDR->height);
    data[8] = IHDR->bit_depth;
    data[9] = IHDR->color_type;
    data[10] = IHDR->compression_method;
    data[11] = IHDR->filter_method;
    data[12] = IHDR->interlace_method;
}

CGColorSpaceRef WSCGColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

static void WSCGDataProviderReleaseDataCallBack(void *info, const void *data, size_t size) {
    if (info) free(info);
}

CGImageRef WSCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay) {
    if (!imageRef) return NULL;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NULL;
    
    if (decodeForDisplay) {
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
        BOOL hasAlpha = false;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = true;
        }
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, WSCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!context) return NULL;
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef newImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        return newImage;
    }else {
        CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        if (!dataProvider) return NULL;
        CFDataRef data = CGDataProviderCopyData(dataProvider);
        if (!data) return NULL;
        
        CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        if (!newProvider) return NULL;
        
        CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(newProvider);
        return newImage;
    }
}

static uint8_t *ws_png_copy_frame_data_at_index(const uint8_t *data,
                                                const ws_png_info *info,
                                                const uint32_t index,
                                                uint32_t *size) {
    if (index >= info->apng_frame_num) return NULL;
    
    ws_png_frame_info *frame_info = info->apng_frames + index;
    uint32_t frame_remux_size = 8 + info->apng_shared_chunk_size + frame_info->chunk_size;
    if (!(info->apng_first_frame_is_cover && index == 0)) {
        frame_remux_size -= frame_info->chunk_num * 4;
    }
    uint8_t *frame_data = malloc(frame_remux_size);
    if (!frame_data) return NULL;
    *size = frame_remux_size;
    
    uint32_t data_offset = 0;
    bool inserted = false;
    memcpy(frame_data, data, 8);
    data_offset += 8;
    for (uint32_t i = 0; i < info->apng_shared_chunk_num; i ++) {
        uint32_t shared_chunk_index = info->apng_shared_chunk_indexs[i];
        ws_png_chunk_info *shared_chunk_info = info->chunks + shared_chunk_index;
        
        if (shared_chunk_index >= info->apng_shared_insert_index && !inserted) {
            inserted = true;
            for (uint32_t c = 0; c < frame_info->chunk_num; c ++) {
                ws_png_chunk_info *insert_chunk_info = info->chunks + frame_info->chunk_index + c;
                if (insert_chunk_info->fourcc == WS_FOUR_CC('f', 'd', 'A', 'T')) {
                    *((uint32_t *)(frame_data + data_offset)) = ws_swap_endian_uint32(insert_chunk_info->length - 4);
                    *((uint32_t *)(frame_data + data_offset + 4)) = WS_FOUR_CC('I', 'd', 'A', 'T');
                    memcpy(frame_data + data_offset + 8, data + insert_chunk_info->offset + 12, insert_chunk_info->length - 4);
                    uint32_t crc = (uint32_t)crc32(0, frame_data + data_offset + 4, insert_chunk_info->length);
                    *((uint32_t *)(frame_data + data_offset + insert_chunk_info->length + 4)) = ws_swap_endian_uint32(crc);
                    data_offset += insert_chunk_info->length + 8;
                }else {
                    memcpy(frame_data + data_offset, data + insert_chunk_info->offset, insert_chunk_info->length + 12);
                    data_offset += insert_chunk_info->length + 12;
                }
                
            }
        }
        
        if (shared_chunk_info->fourcc == WS_FOUR_CC('I', 'H', 'D', 'R')) {
            uint8_t tmp[25] = {0};
            memcpy(tmp, data + shared_chunk_info->offset, 25);
            ws_png_chunk_IHDR IHDR = info->header;
            IHDR.width = frame_info->frame_control.width;
            IHDR.height = frame_info->frame_control.height;
            ws_png_chunk_IHDR_write(&IHDR, tmp + 8);
            *((uint32_t *)(tmp + 21)) = ws_swap_endian_uint32((uint32_t)crc32(0, tmp + 4, 17));
            memcpy(frame_data + data_offset, tmp, 25);
            data_offset += 25;
        }else {
            memcpy(frame_data + data_offset, data + shared_chunk_info->offset, shared_chunk_info->length + 12);
            data_offset += shared_chunk_info->length + 12;
        }
    }
    return frame_data;
}


@interface _WSImageDecoderFrame: WSImageFrame
@property (nonatomic, assign) BOOL hasAlpha;
@property (nonatomic, assign) BOOL isFullSize;
@property (nonatomic, assign) NSUInteger blendFromIndex;
@end

@implementation _WSImageDecoderFrame
- (id)copyWithZone:(NSZone *)zone {
    _WSImageDecoderFrame *frame = [super copyWithZone:zone];
    frame.hasAlpha = _hasAlpha;
    frame.isFullSize = _isFullSize;
    frame.blendFromIndex = _blendFromIndex;
    return frame;
}
@end

@implementation WSImageDecoder {
    pthread_mutex_t _lock;
    
    BOOL _sourceTypeDetected;
    CGImageSourceRef _source;
    ws_png_info *_apngSource;
#if WSIMAGE_WEBP_ENABLED
    WebPDemuxer *_webpSource;
#endif
    
    dispatch_semaphore_t _framesLock;
    NSArray *_frames;
    BOOL _needBlend;
}

- (instancetype)init {
    self = [super init];
    return [self initWithScale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithScale:(CGFloat)scale {
    self = [super init];
    if (scale < 0) scale = 1;
    _scale = scale;
    _framesLock = dispatch_semaphore_create(1);
    pthread_mutex_init_recursive(&_lock, true);
    return self;
}

- (WSImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    WSImageFrame *result = nil;
    pthread_mutex_lock(&_lock);
    result = [self ]
    pthread_mutex_unlock(&_lock);
}


- (WSImageFrame *)_frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeFroDisplay {
    if (index >= _frames.count) return 0;
    _WSImageDecoderFrame *frame = [(_WSImageDecoderFrame *)_frames[index] copy];
    BOOL decoded = false;
    BOOL extendToCanves = false;
    if (_type != WSImageTypeICO && decodeFroDisplay) {
        extendToCanves = true;
    }
    
    if (!_needBlend) {
        CGImageRef imageRef = [self _]
    }
}

- (CGImageRef)_newUnblendedImageAtIndex:(NSUInteger)index
                         extendToCanvas:(BOOL)extendToCanvas
                                decoded:(BOOL *)decoded CF_RETURNS_RETAINED {
    if (!_finalized && index >0) return NULL;
    if (_frames.count <= index) return NULL;
    _WSImageDecoderFrame *frame = _frames[index];
    
    if (_source) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache: @(true)});
        if (imageRef && extendToCanvas) {
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            if (width == _width && height == _height) {
                CGImageRef imageRefExtended = WSCGImageCreateDecodedCopy(imageRef, true);
                if (imageRefExtended) {
                    CFRelease(imageRef);
                    imageRef = imageRefExtended;
                    if (decoded) *decoded = true;
                }
            }else {
                CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, WSCGColorSpaceGetDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
                if (context) {
                    CGContextDrawImage(context, CGRectMake(0, _height - height, width, height), imageRef);
                    CGImageRef imageRefExtended = CGBitmapContextCreateImage(context);
                    CFRelease(context);
                    if (imageRefExtended) {
                        CFRelease(imageRef);
                        imageRef = imageRefExtended;
                        if (decoded) *decoded = true;
                    }
                }
            }
        }
        return imageRef;
    }
    
    if (_apngSource) {
        uint32_t size = 0;
        uint8_t *bytes = ws_png_copy_frame_data_at_index(_data.bytes, _apngSource, (uint32_t)index, &size);
        if (!bytes) return NULL;
        CGDataProviderRef provider = CGDataProviderCreateWithData(bytes, bytes, size, WSCGDataProviderReleaseDataCallBack);
        if (!provider) {
            free(bytes);
            return NULL;
        }
        bytes = NULL;
        
        CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (!source) {
            CFRelease(provider);
            return NULL;
        }
        CFRelease(provider);
        
        if (CGImageSourceGetCount(source) < 1) {
            CFRelease(source);
            return NULL;
        }
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache: @(true)});
        
    }
}

@end
