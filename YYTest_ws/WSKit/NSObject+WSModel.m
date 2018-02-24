//
//  NSObject+WSModel.m
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "NSObject+WSModel.h"
#import "WSClassInfo.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define force_inline __inline__ __attribute__((always_inline))

typedef NS_ENUM(NSUInteger, WSEncodingNSType) {
    WSEncodingTypeNSUnknown = 0,
    WSEncodingTypeNSString,
    WSEncodingTypeNSMutableString,
    WSEncodingTypeNSValue,
    WSEncodingTypeNSNumber,
    WSEncodingTypeNSDecimalNumber,
    WSEncodingTypeNSData,
    WSEncodingTypeNSMutableData,
    WSEncodingTypeNSDate,
    WSEncodingTypeNSURL,
    WSEncodingTypeNSArray,
    WSEncodingTypeNSMutableArray,
    WSEncodingTypeNSDictionary,
    WSEncodingTypeNSMutableDictionary,
    WSEncodingTypeNSSet,
    WSEncodingTypeNSMutableSet,
};

// Get the Foundation class type from property info.
static force_inline WSEncodingNSType WSClassGetNSType(Class cls) {
    if (!cls) return WSEncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return WSEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return WSEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return WSEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return WSEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return WSEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return WSEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return WSEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return WSEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return WSEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return WSEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return WSEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return WSEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return WSEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return WSEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return WSEncodingTypeNSSet;
    return WSEncodingTypeNSUnknown;
}

static force_inline BOOL WSEncodingTypeIsCNumber(WSEncodingType type) {
    switch (type & WSEncodingTypeMask) {
        case WSEncodingTypeBool:
        case WSEncodingTypeInt8:
        case WSEncodingTypeUInt8:
        case WSEncodingTypeInt16:
        case WSEncodingTypeUInt16:
        case WSEncodingTypeInt32:
        case WSEncodingTypeUInt32:
        case WSEncodingTypeInt64:
        case WSEncodingTypeUInt64:
        case WSEncodingTypeFloat:
        case WSEncodingTypeDouble:
        case WSEncodingTypeLongDouble: return YES;
        default: return NO;
    }
}

static force_inline NSNumber *WSNSNumberCreateFromID(__unsafe_unretained id value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE": @(true),
                @"True": @(true),
                @"true": @(true),
                @"FALSE": @(false),
                @"False": @(false),
                @"false": @(false),
                @"YES": @(true),
                @"Yes": @(true),
                @"yes": @(true),
                @"NO": @(false),
                @"No": @(false),
                @"no": @(false),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
        
    });
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num != nil) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }else{
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            return @(atoll(cstring));
        }
    }
    return nil;
}

static force_inline id WSValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths) {
    id value = nil;
    for (NSUInteger i = 0, max = keyPaths.count; i < max ; i ++) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            }else {
                return nil;
            }
        }
    }
    return value;
}

static force_inline id WSValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys) {
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        }else{
            value = WSValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}

@interface _WSModelPropertyMeta: NSObject {
    @package
    NSString *_name;
    WSEncodingType _type;
    WSEncodingNSType _nsType;
    BOOL _isCNumber;
    Class _cls;
    Class _genericCls;
    SEL _getter;
    SEL _setter;
    BOOL _isKVCCompatible;
    BOOL _isStructAvailableForKeyedArchiver;
    BOOL _hasCustomClassFromDictionary;
    
    NSString *_mappedToKey;
    NSArray *_mappedToKeyPath;
    NSArray *_mappedToKeyArray;
    WSClassPropertyInfo *_info;
    _WSModelPropertyMeta *_next;
}
@end;

@implementation _WSModelPropertyMeta

+ (instancetype)metaWithClassInfo:(WSClassInfo *)classInfo propertyInfo:(WSClassPropertyInfo *)propertyInfo generic:(Class)generic {
    
    // support pseudo generic class with protocol name
    if (!generic && propertyInfo.protocols) {
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
            if (cls) {
                generic = cls;
                break;
            }
        }
    }
    
    _WSModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    
    if ((meta->_type & WSEncodingTypeMask) == WSEncodingTypeObject) {
        meta->_nsType = WSClassGetNSType(propertyInfo.cls);
    }else {
        meta->_isCNumber = WSEncodingTypeIsCNumber(meta->_type);
    }
    if ((meta->_type & WSEncodingTypeMask) == WSEncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         归档引起的struct 问题吗
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = true;
        }
    }
    meta->_cls = propertyInfo.cls;
    
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }else if (meta->_cls && meta->_nsType == WSEncodingTypeUnknown) {
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instanceMethodForSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instanceMethodForSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (propertyInfo.getter && propertyInfo.setter) {
        switch (meta->_type & WSEncodingTypeMask) {
            case WSEncodingTypeBool:
            case WSEncodingTypeInt8:
            case WSEncodingTypeUInt8:
            case WSEncodingTypeInt16:
            case WSEncodingTypeUInt16:
            case WSEncodingTypeInt32:
            case WSEncodingTypeUInt32:
            case WSEncodingTypeInt64:
            case WSEncodingTypeUInt64:
            case WSEncodingTypeFloat:
            case WSEncodingTypeDouble:
            case WSEncodingTypeObject:
            case WSEncodingTypeClass:
            case WSEncodingTypeBlock:
            case WSEncodingTypeStruct:
            case WSEncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default: break;
        }
    }
    return meta;
}

@end


@interface _WSModelMeta: NSObject {
    @package
    WSClassInfo *_classInfo;
    // Key: mapped key and key path, value: _WSModelPropertyMeta.
    NSDictionary *_mapper;
    // Array<_WSModelPropertyMeta>, all property meta of this model.
    NSArray *_allPropertyMetas;
    // Array<_WSModelPropertyMeta>, property meta which is mapped to a key path.
    NSArray *_keyPathPropertyMetas;
    // Array<_WSModelPropertyMeta>, property meta which is mapped to multi keys.
    NSArray *_multiKeysPropertyMetas;
    // The number of mapped key (and key path), same to _mapper.count.
    NSUInteger _keyMappedCount;
    // Model class type
    WSEncodingNSType _nsType;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}
@end

@implementation _WSModelMeta
- (instancetype)initWithClass:(Class)cls {
    WSClassInfo *classInfo = [WSClassInfo classInfoWithClass:cls];
    if (!classInfo) return nil;
    self = [super init];
    
    //Get black list
    NSSet *blackList = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlackList)]) {
        NSArray *properties = [(id<WSModel>)cls modelPropertyBlackList];
        if (properties) {
            blackList = [NSSet setWithArray:properties];
        }
    }
    
    //Get white list
    NSSet *whiteList = nil;
    if ([cls respondsToSelector:@selector(modelPropertyWhiteList)]) {
        NSArray *properties = [(id<WSModel>)cls modelPropertyWhiteList];
        if (properties) {
            whiteList = [NSSet setWithArray:properties];
        }
    }
    
    //Get container property's generic class
    NSDictionary *genericMapper = nil;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<WSModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * _Nonnull stop) {
                if (![key isKindOfClass:[NSString class]]) return ;
                Class meta = object_getClass(obj);
                if (!meta) return;
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                }else{
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            
            }];
            genericMapper = tmp;
        }
    }
    
    // Create all property metas
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary dictionary];
    WSClassInfo *curClassInfo = classInfo;
    while (curClassInfo && curClassInfo.superCls != nil) {
        for (WSClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) continue;
            if (blackList && [blackList containsObject:propertyInfo.name]) continue;
            if (whiteList && [whiteList containsObject:propertyInfo.name]) continue;
            _WSModelPropertyMeta *meta = [_WSModelPropertyMeta metaWithClassInfo:curClassInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]];
            if (!meta || !meta->_name) continue;
            if (!meta->_getter || !meta->_setter) continue;
            if (allPropertyMetas[meta->_name]) continue;
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    if (allPropertyMetas.count) _allPropertyMetas = allPropertyMetas.allValues.copy;
    
    //create mapper
    NSMutableDictionary *mapper = [NSMutableDictionary dictionary];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray array];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray array];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id<WSModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL * _Nonnull stop) {
            _WSModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) return;
                propertyMeta->_mappedToKey = mappedToKey;
                NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:tmp];
                        keyPath = tmp;
                        break;
                    }
                }
                
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *mappedToKeyArray = [NSMutableArray array];
                for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (oneKey.length == 0) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    }else{
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                
                if (propertyMeta->_mappedToKey) return;
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _WSModelPropertyMeta *propertyMeta, BOOL * _Nonnull stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = WSClassGetNSType(cls);
    _hasCustomWillTransformFromDictionary = [cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)];
    _hasCustomTransformFromDictionary = [cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)];
    _hasCustomTransformToDictionary = [cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)];
    _hasCustomClassFromDictionary = [cls instancesRespondToSelector:@selector(modelCustomClassForDictionary:)];
    
    return self;
}

+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _WSModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!meta || meta->_classInfo.needUpdate) {
        meta = [[_WSModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}
@end


typedef struct {
    void *modelMeta;  ///< _YYModelMeta
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} ModelSetContext;

static force_inline NSDate *WSNSDateFromString(__unsafe_unretained NSString *string) {
    typedef NSDate *(^WSNSDateParseBlock) (NSString *string);
#define kParserNum 34
    static WSNSDateParseBlock blocks[kParserNum + 1] = {0}; //???
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            /*
             2014-01-20  // Google
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    WSNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
#undef kParserNum
}

static force_inline Class WSNSBlockClass() {
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = ((NSObject *)block).class;
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls;
}

static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model,
                                                  __unsafe_unretained NSNumber *num,
                                                  __unsafe_unretained _WSModelPropertyMeta *meta) {
    switch (meta->_type & WSEncodingTypeMask) {
        case WSEncodingTypeBool:{
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.boolValue);
        } break;
        case WSEncodingTypeInt8:{
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.charValue);
        } break;
        case WSEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint8_t)num.unsignedCharValue);
        } break;
        case WSEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case WSEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint16_t)num.unsignedShortValue);
        } break;
        case WSEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        }
        case WSEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint32_t)num.unsignedIntValue);
        } break;
        case WSEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.longLongValue);
            }
        } break;
        case WSEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.unsignedLongLongValue);
            }
        } break;
        case WSEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case WSEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case WSEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        } // break; commented for code coverage in next line
        default: break;
            
    }
}

static void ModelSetValueForProperty(__unsafe_unretained id model, __unsafe_unretained id value, __unsafe_unretained _WSModelPropertyMeta *meta) {
    if (meta->_isCNumber) {
        NSNumber *num = WSNSNumberCreateFromID(value);
        ModelSetNumberToProperty(model, num, meta);
        if (num != nil) [num class];// hold the number ???
    }else if (meta->_nsType) {
        if (value == (id)kCFNull) {
            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, (id)nil);
        }else {
            switch (meta->_nsType) {
                case WSEncodingTypeNSString:
                case WSEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == WSEncodingTypeNSString) {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                        }else{
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
                        }
                    }else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model,
                                                                      meta->_setter,
                                                                      (meta->_nsType == WSEncodingTypeNSString)?
                                                                      ((NSNumber *)value).stringValue :
                                                                      ((NSNumber *)value).stringValue.mutableCopy);
                    }else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, string);
                    }else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model,
                                                                      meta->_setter,
                                                                      (meta->_nsType == WSEncodingTypeNSString) ?
                                                                      ((NSURL *)value).absoluteString :
                                                                      ((NSURL *)value).absoluteString.mutableCopy);
                    }else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model,
                                                                      meta->_setter,
                                                                      (meta->_nsType == WSEncodingTypeNSString) ?
                                                                      ((NSAttributedString *)value).string :
                                                                      ((NSAttributedString *)value).string.mutableCopy);
                    }
                } break;
                case WSEncodingTypeNSValue:
                case WSEncodingTypeNSNumber:
                case WSEncodingTypeNSDecimalNumber: {
                    if (meta->_nsType == WSEncodingTypeNSNumber) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, WSNSNumberCreateFromID(value));
                    }else if (meta->_nsType == WSEncodingTypeNSDecimalNumber) {
                        if ([value isKindOfClass:[NSDecimalNumber class]]) {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                        }else if ([value isKindOfClass:[NSNumber class]]) {
                            NSDecimalNumber *decimalNum = [NSDecimalNumber decimalNumberWithDecimal:((NSNumber *)value).decimalValue];
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, decimalNum);
                        }else if ([value isKindOfClass:[NSString class]]){
                            NSDecimalNumber *decimalNum = [NSDecimalNumber decimalNumberWithString:value];
                            NSDecimal dec = decimalNum.decimalValue;
                            if (dec._length == 0 && dec._isNegative) {
                                decimalNum = nil; //NaN
                            }
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, decimalNum);
                        }
                    }else{
                        if ([value isKindOfClass:[NSValue class]]) {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                        }
                    }
                } break;
                case WSEncodingTypeNSData:
                case WSEncodingTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        if (meta->_nsType == WSEncodingTypeNSData) {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                        }else{
                            NSMutableData *mutableData = [NSMutableData dataWithData:value];
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, mutableData);
                        }
                    }else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_nsType == WSEncodingTypeNSMutableData) {
                            data = data.mutableCopy;
                        }
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, data);
                    }
                } break;
                    
                case WSEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                    }else if ([value isKindOfClass:[NSString class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, WSNSDateFromString(value));
                    }
                } break;
                    
                case WSEncodingTypeNSURL: {
                    if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                    }else if ([value isKindOfClass:[NSString class]]) {
                        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                        NSString *str = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, nil);
                        }else {
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, [[NSURL alloc] initWithString:str]);
                        }
                    }
                } break;
                    
                case WSEncodingTypeNSArray:
                case WSEncodingTypeNSMutableArray: {
                    if (meta->_genericCls) {
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]]) valueArr = value;
                        else if ([value isKindOfClass:[NSSet class]]) valueArr = ((NSSet *)value).allObjects;
                        if (valueArr) {
                            NSMutableArray *objectArr = [NSMutableArray array];
                            for (id one in valueArr) {
                                if ([one isKindOfClass:meta->_genericCls]) {
                                    [objectArr addObject:one];
                                }else if ([one isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:one];
                                        if (!cls) cls = meta->_genericCls;
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne modelSetWithDictionary:one];
                                    if (newOne) [objectArr addObject:newOne];
                                }
                            }
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, objectArr);
                        }
                    }else {
                        if ([value isKindOfClass:[NSArray class]]) {
                            if (meta->_nsType == WSEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                            }else {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, ((NSArray *)value).mutableCopy);
                            }
                        }else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_nsType == WSEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects);
                            }else {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects.mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case WSEncodingTypeNSDictionary:
                case WSEncodingTypeNSMutableDictionary: {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (meta->_genericCls) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [((NSDictionary *)value) enumerateKeysAndObjectsUsingBlock:^(NSString *oneKey, id oneValue, BOOL * _Nonnull stop) {
                                if ([oneValue isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:oneValue];
                                        if (!cls) cls = meta->_genericCls;
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne modelSetWithDictionary:oneValue];
                                    if (newOne) dic[oneKey] = newOne;
                                }
                            }];
                            ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, dic);
                        }else {
                            if (meta->_nsType == WSEncodingTypeNSDictionary) {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, value);
                            }else {
                                ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, meta->_setter, ((NSDictionary *)value).mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case WSEncodingTypeNSSet:
                case WSEncodingTypeNSMutableSet: {
                    NSSet *valueSet = nil;
                    if ([value isKindOfClass:[NSArray class]]) valueSet = [NSMutableSet setWithArray:value];
                    else if ([value isKindOfClass:[NSSet class]]) valueSet = (NSSet *)value;
                    
                    if (meta->_genericCls) {
                        NSMutableSet *set = [NSMutableSet set];
                        for (id one in valueSet) {
                            if ([one isKindOfClass:meta->_genericCls]) {
                                [set addObject:one];
                            }else if ([one isKindOfClass:[NSDictionary class]]) {
                                Class cls = meta->_genericCls;
                                if (meta->_hasCustomClassFromDictionary) {
                                    cls = [cls modelCustomClassForDictionary:one];
                                    if (!cls) cls = meta->_genericCls;
                                }
                                NSObject *newOne = [cls new];
                                [newOne modelSetWithDictionary:one];
                                if (newOne) [set addObject:newOne];
                            }
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, set);
                    }else {
                        if (meta->_nsType == WSEncodingTypeNSSet) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, valueSet);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                           meta->_setter,
                                                                           ((NSSet *)valueSet).mutableCopy);
                        }
                    }
                } //break;
                    
                default:
                    break;
            }
        }
    }else {
        BOOL isNull = (value == (id)kCFNull);
        switch (meta->_type & WSEncodingTypeMask) {
            case WSEncodingTypeObject: {
                Class cls = meta->_genericCls ?: meta->_cls;
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, nil);
                }else if ([value isKindOfClass:cls] || cls) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                }else if ([value isKindOfClass:[NSDictionary class]]) {
                    NSObject *one = nil;
                    if (meta->_getter) {
                        one = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
                    }
                    if (one) {
                        [one modelSetWithDictionary:value];
                    }else {
                        if (meta->_hasCustomClassFromDictionary) {
                            cls = [cls modelCustomClassForDictionary:value] ?: cls;
                        }
                        one = [cls new];
                        [one modelSetWithDictionary:value];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, one); //???  我觉着这个地方应该写在else的外边, 但是不知道为什么写在了里边
                    }
                }
            } break;
                
            case WSEncodingTypeClass: {
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, NULL);
                }else {
                    Class cls = nil;
                    if ([value isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(value);
                        if (cls) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, cls);
                        }
                    }else {
                        cls = object_getClass(value);
                        if (cls) {
                            if (class_isMetaClass(cls)) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            }
                        }
                    }
                }
            } break;
                
            case WSEncodingTypeSEL: {
                if (isNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)NULL);
                }else if ([value isKindOfClass:[NSString class]]) {
                    SEL sel = NSSelectorFromString(value);
                    if (sel) ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)sel);
                }
            } break;
                
            case WSEncodingTypeBlock: {
                if (isNull) {
                    ((void (*)(id, SEL, void(^)(void)))(void *) objc_msgSend)((id)model, meta->_setter, (void(^)(void))NULL);
                }else if ([value isKindOfClass:WSNSBlockClass()]) {
                    ((void (*)(id, SEL, void(^)(void)))(void *) objc_msgSend)((id)model, meta->_setter, (void(^)(void))value);
                }
            } break;
                
            case WSEncodingTypeStruct:
            case WSEncodingTypeUnion:
            case WSEncodingTypeCArray: {
                if ([value isKindOfClass:[NSValue class]]) {
                    const char *valueType = ((NSValue *)value).objCType;
                    const char *metaType = meta->_info.typeEncoding.UTF8String;
                    if (valueType && metaType && strcmp(valueType, metaType) == 0) {
                        [model setValue:value forKey:meta->_name];
                    }
                }
            } break;
                
            case WSEncodingTypePointer:
            case WSEncodingTypeCString: {
                if (isNull) {
                    ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, (void *)NULL);
                }else {
                    NSValue *nsValue = value;
                    if (nsValue.objCType && strcmp(nsValue.objCType, "^v") == 0) {
                        ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, (void *)nsValue.pointerValue);
                    }
                }
            }
            default:
                break;
        }
    }
}


static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained _WSModelMeta *meta = (__bridge _WSModelMeta *)(context->modelMeta);
    __unsafe_unretained _WSModelPropertyMeta *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
    __unsafe_unretained id model = (__bridge id)(context->model);
    while (propertyMeta) {
        if (propertyMeta->_setter) {
            ModelSetValueForProperty(model, (__bridge __unsafe_unretained id)_value, propertyMeta);
        }
        propertyMeta = propertyMeta->_next;
    };
}

static void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained _WSModelPropertyMeta *propertyMeta = (__bridge _WSModelPropertyMeta *)(_propertyMeta);
    if (!propertyMeta->_setter) return;
    id value = nil;
    
    if (propertyMeta->_mappedToKeyArray) {
        value = WSValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    }else if (propertyMeta->_mappedToKeyPath) {
        value = WSValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    }else {
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }
    
    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        ModelSetValueForProperty(model, value, propertyMeta);
    }
}

@implementation NSObject (WSModel)

+ (NSDictionary *)_ws_dictionaryWithJson:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    }else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

+ (instancetype)modelWithJson:(id)json {
    NSDictionary *dic = [self _ws_dictionaryWithJson:json];
    return [self modelWithDictionary:dic];
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary == (id)kCFNull) return nil;
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    
    Class cls = [self class];
    _WSModelMeta *modelMeta = [_WSModelMeta metaWithClass:cls];
    if (modelMeta->_hasCustomClassFromDictionary) {
        cls = [cls modelCustomClassForDictionary:dictionary] ?: cls;
    }
    
    NSObject *one = [cls new];
    if ([one modelSetWithDictionary:dictionary]) return one;
    return nil;
}

- (BOOL)modelSetWithDictionary:(NSDictionary *)dic {
    if (!dic || dic == (id)kCFNull) return false;
    if (![dic isKindOfClass:[NSDictionary class]]) return false;
    
    _WSModelMeta *modelMeta = [_WSModelMeta metaWithClass:object_getClass(self)];
    if (modelMeta->_keyMappedCount == 0) return false;
    
    if (modelMeta->_hasCustomWillTransformFromDictionary) {
        dic = [((id<WSModel>)self) modelCustomWillTransformFromDictionary:dic];
        if (![dic isKindOfClass:[NSDictionary class]]) return false;
    }
    
    ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(modelMeta);
    context.model = (__bridge void *)(self);
    context.dictionary = (__bridge void *)(dic);
    
    if (modelMeta->_keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
        CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
        if (modelMeta->_keyPathPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_keyPathPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_keyPathPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
        if (modelMeta->_multiKeysPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_multiKeysPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_multiKeysPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
    }else {
        CFArrayApplyFunction((CFArrayRef)modelMeta->_allPropertyMetas,
                             CFRangeMake(0, modelMeta->_keyMappedCount),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
    
    if (modelMeta->_hasCustomTransformFromDictionary) {
        return [((id<WSModel>)self) modelCustomTransformFromDictionary:dic];
    }
    return true;
}

@end
