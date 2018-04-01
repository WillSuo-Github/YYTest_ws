//
//  UITapGestureRecognizer+WSAdd.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (WSAdd)


- (instancetype)initWithActionBlock:(void (^)(id sender))block;

- (void)addActionBlock:(void (^)(id sender))block;

- (void)removeAllActionBlocks;
@end
