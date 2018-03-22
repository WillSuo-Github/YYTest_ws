//
//  NSDictionary+WSAdd.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/23.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (WSAdd)

- (unsigned long long)unsignedLongLongValueForKey:(NSString *)key default:(unsigned long long)def;
@end
