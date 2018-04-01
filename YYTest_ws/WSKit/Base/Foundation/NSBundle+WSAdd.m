//
//  NSBundle+WSAdd.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "NSBundle+WSAdd.h"
#import "NSString+WSAdd.h"

@implementation NSBundle (WSAdd)

+ (NSArray *)preferredScales {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1, @2, @3];
        }else if (screenScale <= 2) {
            scales = @[@2, @3, @1];
        }else {
            scales = @[@3, @2, @1];
        }
    });
    return scales;
}
@end
