//
//  CALayer+WSAdd.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "CALayer+WSAdd.h"

@implementation CALayer (WSAdd)

- (CGFloat)transformScale {
    NSNumber *v = [self valueForKeyPath:@"transform.scale"];
    return v.floatValue;
}

- (void)setTransformScale:(CGFloat)transformScale {
    [self setValue:@(transformScale) forKey:@"transform.scale"];
}
@end
