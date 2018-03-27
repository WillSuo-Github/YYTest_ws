//
//  WSImage.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSImage.h"

@implementation WSImage

+ (WSImage *)imageNamed:(NSString *)name {
    if (name.length == 0) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = [NSBundle preferr]
}
@end
