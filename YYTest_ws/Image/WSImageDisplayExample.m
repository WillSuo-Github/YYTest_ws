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
    
    _scrollView.panGestureRecognizer.cancelsTouchesInView = true;
}

- (void)addImageWithName:(NSString *)name text:(NSString *)text {
    WSImage *image = [WSImage imageNamed:name];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
