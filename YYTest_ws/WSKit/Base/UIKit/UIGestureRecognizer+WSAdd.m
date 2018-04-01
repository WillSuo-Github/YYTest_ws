//
//  UITapGestureRecognizer+WSAdd.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "UIGestureRecognizer+WSAdd.h"
#import <objc/runtime.h>

static const int block_key;

@interface _WSUIGestureRecognizerBlockTarget : NSObject

@property (nonatomic, copy) void (^block)(id sender);

- (id)initWithBlock:(void (^)(id sender))block;
- (void)invoke:(id)sender;
@end

@implementation _WSUIGestureRecognizerBlockTarget

- (id)initWithBlock:(void (^)(id sender))block {
    ///??? 为什么有的init方法需要判断self  有的就不会
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

- (void)invoke:(id)sender {
    if (_block) _block(sender);
}
@end


@implementation UIGestureRecognizer (WSAdd)

- (instancetype)initWithActionBlock:(void (^)(id))block {
    self = [self init];
    [self addActionBlock:block];
    return self;
}

- (void)addActionBlock:(void (^)(id sender))block {
    _WSUIGestureRecognizerBlockTarget *target = [[_WSUIGestureRecognizerBlockTarget alloc] initWithBlock:block];
    [self addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self __ws_allUIGestureRecognizerBlockTargets];
    [targets addObject:target];
}

- (void)removeAllActionBlocks {
    NSMutableArray *targets = [self __ws_allUIGestureRecognizerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id  _Nonnull target, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

- (NSMutableArray *)__ws_allUIGestureRecognizerBlockTargets {
    NSMutableArray *targets = objc_getAssociatedObject(self, &block_key);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, &block_key, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}
@end
