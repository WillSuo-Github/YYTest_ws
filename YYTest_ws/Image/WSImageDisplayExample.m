//
//  WSImageDisplayExample.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSImageDisplayExample.h"
#import "WSKit.h"
#import "WSImageExampleHelper.h"


@interface WSImageDisplayExample ()<UIGestureRecognizerDelegate>

@end

@implementation WSImageDisplayExample {
    UIScrollView *_scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    _scrollView = [UIScrollView new];
    _scrollView.frame = self.view.bounds;
    if (kSystemVersion < 7) {
        _scrollView.height -= 44;
    }
    [self.view addSubview:_scrollView];
    
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.size = CGSizeMake(self.view.width, 60);
    label.top = 30;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.text = @"Tap the image to pause/paly\n Slide on the image to forward/rewind";
    [_scrollView addSubview:label];

    [self addImageWithName:@"niconiconi" text:@"Animated gif"];
    [self addImageWithName:@"wall-e" text:@"Animated WebP"];
    [self addImageWithName:@"pia" text:@"Animated PNG (APNG)"];
    [self addFrameImageWithText:@"Frame Animation"];
    
    _scrollView.panGestureRecognizer.cancelsTouchesInView = true;
}

- (void)addImageWithName:(NSString *)name text:(NSString *)text {
    WSImage *image = [WSImage imageNamed:name];
    [self addImage:image size:CGSizeZero text:text];
}

- (void)addFrameImageWithText:(NSString *)text {
    NSString *basePath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"EmoticonWeibo.bundle/com.sina.default"];
    NSMutableArray *paths = [NSMutableArray array];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_aini@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_baibai@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_chanzui@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_chijing@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_dahaqi@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_guzhang@3x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_haha@2x.png"]];
    [paths addObject:[basePath stringByAppendingPathComponent:@"d_haixiu@3x.png"]];
    
    WSFrameImage *image = [[WSFrameImage alloc] initWithImagePaths:paths oneFrameDuration:1 loopCount:0];
    [self addImage:image size:CGSizeZero text:text];
}

- (void)addImage:(UIImage *)image size:(CGSize)size text:(NSString *)text {
    WSAnimationImageView *imageView = [[WSAnimationImageView alloc] initWithImage:image];
    
    if (size.width > 0 && size.height > 0) imageView.size = size;
    imageView.centerX = self.view.width / 2;
    imageView.top = [(UIView *)[_scrollView.subviews lastObject] bottom] + 30;
    [_scrollView addSubview:imageView];
    [WSImageExampleHelper addTapControlToAnimationedImageView:imageView];
    [WSImageExampleHelper addPanControlToAnimationedImageView:imageView];
    for (UIGestureRecognizer *g in imageView.gestureRecognizers) {
        g.delegate = self;
    }
    
    UILabel *imageLabel = [UILabel new];
    imageLabel.backgroundColor = [UIColor clearColor];
    imageLabel.frame = CGRectMake(0, 0, self.view.width, 20);
    imageLabel.top = imageView.bottom + 10;
    imageLabel.textAlignment = NSTextAlignmentCenter;
    imageLabel.text = text;
    [_scrollView addSubview:imageLabel];
    
    _scrollView.contentSize = CGSizeMake(self.view.width, imageLabel.bottom + 20);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return true;
}

@end
