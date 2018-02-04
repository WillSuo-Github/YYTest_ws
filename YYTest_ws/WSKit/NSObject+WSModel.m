//
//  NSObject+WSModel.m
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "NSObject+WSModel.h"
#import "WSClassInfo.h"

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
    WSEncodingType _nsType;
    
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
            
        }
    }
}
@end

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
    return <#expression#>
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary == (id)kCFNull) return nil;
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    
    Class cls = [self class];
    
}

@end
