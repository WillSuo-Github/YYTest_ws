//
//  NSString+WSAdd.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "NSString+WSAdd.h"

@implementation NSString (WSAdd)

- (NSString *)stringByAppendingNameScale:(CGFloat)scale {
    if (fabs(scale - 1) <= __FLT_EPSILON__ || self.length == 0 || [self hasPrefix:@"/"]) return self.copy;
    return [self stringByAppendingFormat:@"@%@x", @(scale)];
}
@end
