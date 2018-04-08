//
//  WSWeakProxy.h
//  YYTest_ws
//
//  Created by great Lock on 2018/4/4.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WSWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;


- (instancetype)initWithTarget:(id)target;

+ (instancetype)proxyWithTarget:(id)target;

NS_ASSUME_NONNULL_END
@end
