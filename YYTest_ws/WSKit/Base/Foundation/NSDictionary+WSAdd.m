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
    if (!value || value == [NSNull null]) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = ((NSString *)value).lowercaseString;
        if (([lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"])) return @(true);
        if ([lower isEqualToString:@"false"] || [lower isEqualToString:@"no"]) return @(false);
        if ([lower isEqualToString:@"nil"] || [lower isEqualToString:@"null"]) return nil;
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            return @(((NSString *)value).doubleValue);
        }else {
            return @(((NSString *)value).longLongValue);
        }
    }
    return nil;
}

#define RETURN_VALUE(_type_)                                                     \
if (!key) return def;                                                            \
id value = self[key];                                                            \
if (!value || value == [NSNull null]) return def;                                \
if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value)._type_;   \
if ([value isKindOfClass:[NSString class]]) return NSNumberFromID(value)._type_; \
return def;

@implementation NSDictionary (WSAdd)

- (unsigned long long)unsignedLongLongValueForKey:(NSString *)key default:(unsigned long long)def {
    RETURN_VALUE(unsignedLongLongValue);
}
@end
