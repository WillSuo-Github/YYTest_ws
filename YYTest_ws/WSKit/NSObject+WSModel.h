//
//  NSObject+WSModel.h
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WSModel <NSObject>
@optional
+ (nullable NSArray<NSString *> *)modelPropertyBlackList;

+ (nullable NSArray<NSString *> *)modelPropertyWhiteList;

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

@end

@interface NSObject (WSModel)

+ (nullable instancetype)modelWithJson:(id)json;

@end
