//
//  NSDictionary+WSAdd.m
//  YYTest_ws
//
//  Created by great Lock on 2018/3/23.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "NSDictionary+WSAdd.h"

static NSNumber *NSNumberFromID (id value) {
    static NSCharacterSet *dot;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
    });
}

#define RETRRN_VALUE(_type_)\
if (!key) return def;\
id value = self[key];\
if (!value || value == [NSNull null]) return def;\
if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value)._type_;\
if ([value isKindOfClass:[NSString class]]) return

@implementation NSDictionary (WSAdd)

- (unsigned long long)unsignedLongLongValueForKey:(NSString *)key default:(unsigned long long)def {
    
}
@end
