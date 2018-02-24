//
//  NSObject+WSModel.h
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WSModel <NSObject>
@optional
+ (nullable NSArray<NSString *> *)modelPropertyBlackList;

+ (nullable NSArray<NSString *> *)modelPropertyWhiteList;

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *_Nullable)dictionary;

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;


@end

@interface NSObject (WSModel)

+ (nullable instancetype)modelWithJson:(id _Nullable )json;

- (BOOL)modelSetWithDictionary:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
