//
//  WSClassInfo.m
//  YYTest_ws
//
//  Created by great Lock on 2018/2/3.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSClassInfo.h"

WSEncodingType WSEncodingGetType(const char *typeEncoding) {
    char *type = (char *)typeEncoding;
    if (!type) return WSEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return WSEncodingTypeUnknown;
    WSEncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r':{
                qualifier |= WSEncodingTypeQualifierConst;
                type++;
            } break;
            case 'n':{
                qualifier |= WSEncodingTypeQualifierIn;
                type++;
            } break;
            case 'N':{
                qualifier |= WSEncodingTypeQualifierInout;
                type++;
            } break;
            case 'o':{
                qualifier |= WSEncodingTypeQualifierOut;
                type++;
            } break;
            case 'O':{
                qualifier |= WSEncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R':{
                qualifier |= WSEncodingTypeQualifierByref;
                type++;
            } break;
            case 'V':{
                qualifier |= WSEncodingTypeQualifierOneway;
                type++;
            } break;
            default: { prefix = false; } break;
        }
    }
    
    len = strlen(type);
    if (len == 0) return WSEncodingTypeUnknown | qualifier;
    
    switch (*type) {
        case 'v': return WSEncodingTypeVoid | qualifier;
        case 'B': return WSEncodingTypeVoid | qualifier;
        case 'c': return WSEncodingTypeInt8 | qualifier;
        case 'C': return WSEncodingTypeUInt8 | qualifier;
        case 's': return WSEncodingTypeInt16 | qualifier;
        case 'S': return WSEncodingTypeUInt16 | qualifier;
        case 'i': return WSEncodingTypeInt32 | qualifier;
        case 'I': return WSEncodingTypeUInt32 | qualifier;
        case 'l': return WSEncodingTypeInt32 | qualifier;
        case 'L': return WSEncodingTypeUInt32 | qualifier;
        case 'q': return WSEncodingTypeInt64 | qualifier;
        case 'Q': return WSEncodingTypeUInt64 | qualifier;
        case 'f': return WSEncodingTypeFloat | qualifier;
        case 'd': return WSEncodingTypeDouble | qualifier;
        case 'D': return WSEncodingTypeLongDouble | qualifier;
        case '#': return WSEncodingTypeClass | qualifier;
        case ':': return WSEncodingTypeSEL | qualifier;
        case '*': return WSEncodingTypeCString | qualifier;
        case '^': return WSEncodingTypePointer | qualifier;
        case '[': return WSEncodingTypeCArray | qualifier;
        case '(': return WSEncodingTypeUnion | qualifier;
        case '{': return WSEncodingTypeStruct | qualifier;
        case '@': {
            if (len == 2 && *(type + 1) == '?') {
                return WSEncodingTypeBlock | qualifier;
            }else {
                return WSEncodingTypeObject | qualifier;
            }
        }
        default: return WSEncodingTypeUnknown | qualifier;
    }
}


@implementation WSClassMethodInfo
- (instancetype)initWithMethod:(Method)method {
    if (!method) return nil;
    self = [super init];
    _method = method;
    _sel = method_getName(method);
    _imp = method_getImplementation(method);
    const char *name = sel_getName(_sel);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
        NSMutableArray *argumentTypes = [NSMutableArray array];
        for (unsigned int i = 0; i < argumentCount; i ++) {
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            [argumentTypes addObject:type ?: @""];
            if (argumentType) free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    return self;
}
@end

@implementation WSClassPropertyInfo
- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) return nil;
    self = [super init];
    _property = property;
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    WSEncodingType type = 0;
    unsigned int attrCount;
    objc_property_attribute_t *attrs =  property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i ++) {
        switch (attrs[i].name[0]) {
            case 'T':
                if (attrs[i].value) {
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    type = WSEncodingGetType(attrs[i].value);
                    
                    if ((type & WSEncodingTypeMask) == WSEncodingTypeObject && _typeEncoding.length) {
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                        if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                        
                        NSString *clsName = nil;
                        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                            if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                        }
                        
                        NSMutableArray *protocols = nil;
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString *protocol = nil;
                            if ([scanner scanUpToString:@">" intoString:&protocol]) {
                                if (protocol.length) {
                                    if (!protocols) protocols = [NSMutableArray array];
                                    [protocols addObject:protocol];
                                }
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        _protocols = protocols;
                    }
                } break;
            case 'V':{
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
            case 'R':{
                type |= WSEncodingTypePropertyReadonly;
            } break;
            case 'C':{
                type |= WSEncodingTypePropertyCopy;
            } break;
            case '&':{
                type |= WSEncodingTypePropertyRetain;
            } break;
            case 'N':{
                type |= WSEncodingTypePropertyNonatomic;
            } break;
            case 'D':{
                type |= WSEncodingTypePropertyDynamic;
            } break;
            case 'W':{
                type |= WSEncodingTypePropertyWeak;
            } break;
            case 'G':{
                type |= WSEncodingTypePropertyCustomGetter;
                if (attrs[i].value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } break;
            default: break;
        }
    }
    
    if (attrs) {
        free(attrs);
        attrs = NULL;
    }
    
    _type = type;
    if (_name.length) {
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]]);
        }
    }
                                            
    return self;
}
@end

@implementation WSClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) return nil;
    self = [super init];
    _ivar = ivar;
    const char *name = ivar_getName(ivar);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    _offset = ivar_getOffset(ivar);
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        _type = WSEncodingGetType(typeEncoding);
    }
    return self;
}
@end

@implementation WSClassInfo{
    BOOL _needUpdate;
}

+ (nullable instancetype)classInfoWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    WSClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info _update];
    }
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[WSClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

+ (instancetype)classInfoWithClassName:(NSString *)className {
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}

- (instancetype)initWithClass:(Class)cls {
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    _superCls = class_getSuperclass(cls);
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    [self _update];
    
    _superClassInfo = [self.class classInfoWithClass:_superCls];
    return self;
}

- (void)_update {
    _ivarInfos = nil;
    _methodInfos = nil;
    _propertyInfos = nil;
    
    Class cls = self.cls;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        NSMutableDictionary *methodInfos = [NSMutableDictionary dictionary];
        _methodInfos = methodInfos;
        for (unsigned int i = 0; i < methodCount; i ++) {
            WSClassMethodInfo *info = [[WSClassMethodInfo alloc] initWithMethod:methods[i]];
            if (info.name) methodInfos[info.name] = info;
        }
        free(methods);
    }
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (propertyCount) {
        NSMutableDictionary *propertyInfos = [NSMutableDictionary dictionary];
        _propertyInfos = propertyInfos;
        for ( int i = 0; i < propertyCount; i ++) {
            WSClassPropertyInfo *info = [[WSClassPropertyInfo alloc] initWithProperty:properties[i]];
            if (info.name) propertyInfos[info.name] = info;
        }
        free(properties);
    }
    
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars) {
        NSMutableDictionary *ivarInfos = [NSMutableDictionary dictionary];
        _ivarInfos = ivarInfos;
        for (unsigned int i = 0; i < ivarCount; i ++) {
            WSClassIvarInfo *info = [[WSClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (info.name) ivarInfos[info.name] = info;
        }
        free(ivars);
    }
    
    if (!_ivarInfos) _ivarInfos = @{};
    if (!_methodInfos) _methodInfos = @{};
    if (!_propertyInfos) _propertyInfos = @{};
    
    _needUpdate = false;
}

- (void)setNeedUpdate {
    _needUpdate = true;
}

- (BOOL)needUpdate{
    return _needUpdate;
}

@end
