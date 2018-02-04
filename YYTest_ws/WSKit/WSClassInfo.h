//
//  WSClassInfo.h
//  YYTest_ws
//
//  Created by great Lock on 2018/2/3.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_OPTIONS(NSUInteger, WSEncodingType) {
    WSEncodingTypeMask          = 0xFF,
    WSEncodingTypeUnknown       = 0,
    WSEncodingTypeVoid          = 1,
    WSEncodingTypeBool          = 2,
    WSEncodingTypeInt8          = 3,
    WSEncodingTypeUInt8         = 4,
    WSEncodingTypeInt16         = 5,
    WSEncodingTypeUInt16        = 6,
    WSEncodingTypeInt32         = 7,
    WSEncodingTypeUInt32        = 8,
    WSEncodingTypeInt64         = 9,
    WSEncodingTypeUInt64        = 10,
    WSEncodingTypeFloat         = 11,
    WSEncodingTypeDouble        = 12,
    WSEncodingTypeLongDouble    = 13,
    WSEncodingTypeObject        = 14,
    WSEncodingTypeClass         = 15,
    WSEncodingTypeSEL           = 16,
    WSEncodingTypeBlock         = 17,
    WSEncodingTypePointer       = 18,
    WSEncodingTypeStruct        = 19,
    WSEncodingTypeUnion         = 20,
    WSEncodingTypeCString       = 21,
    WSEncodingTypeCArray        = 22,
    
    WSEncodingTypeQualifierMask     = 0xFF00,
    WSEncodingTypeQualifierConst    = 1 << 8,
    WSEncodingTypeQualifierIn       = 1 << 9,
    WSEncodingTypeQualifierInout    = 1 << 10,
    WSEncodingTypeQualifierOut      = 1 << 11,
    WSEncodingTypeQualifierBycopy   = 1 << 12,
    WSEncodingTypeQualifierByref    = 1 << 13,
    WSEncodingTypeQualifierOneway   = 1 << 14,
    
    WSEncodingTypePropertyMask              = 0xFF0000,
    WSEncodingTypePropertyReadonly          = 1 << 16,
    WSEncodingTypePropertyCopy              = 1 << 17,
    WSEncodingTypePropertyRetain            = 1 << 18,
    WSEncodingTypePropertyNonatomic         = 1 << 19,
    WSEncodingTypePropertyWeak              = 1 << 20,
    WSEncodingTypePropertyCustomGetter      = 1 << 21,
    WSEncodingTypePropertyCustomSetter      = 1 << 22,
    WSEncodingTypePropertyDynamic           = 1 << 23,
    
};

NS_ASSUME_NONNULL_BEGIN

@interface WSClassIvarInfo: NSObject
@property (nonatomic, assign, readonly) Ivar ivar;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) ptrdiff_t offset;
@property (nonatomic, strong, readonly) NSString *typeEncoding;
@property (nonatomic, assign, readonly) WSEncodingType type;

- (instancetype)initWithIvar:(Ivar)ivar;
@end

@interface WSClassMethodInfo: NSObject
@property (nonatomic, assign, readonly) Method method;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) SEL sel;
@property (nonatomic, assign, readonly) IMP imp;
@property (nonatomic, strong, readonly) NSString *typeEncoding;
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings;

- (instancetype)initWithMethod:(Method)method;
@end

@interface WSClassPropertyInfo: NSObject
@property (nonatomic, assign, readonly) objc_property_t property;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) WSEncodingType type;
@property (nonatomic, strong, readonly) NSString *typeEncoding;
@property (nonatomic, strong, readonly) NSString *ivarName;
@property (nullable, nonatomic, assign, readonly) Class cls;
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols;
@property (nonatomic, assign, readonly) SEL getter;
@property (nonatomic, assign, readonly) SEL setter;

- (instancetype)initWithProperty:(objc_property_t)property;
@end

@interface WSClassInfo : NSObject
@property (nonatomic, assign, readonly) Class cls;
@property (nullable, nonatomic, assign, readonly) Class superCls;
@property (nullable, nonatomic, assign, readonly) Class metaCls;
@property (nonatomic, assign, readonly) BOOL isMeta;
@property (nonatomic, strong, readonly) NSString *name;
@property (nullable, nonatomic, strong, readonly) WSClassInfo *superClassInfo;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, WSClassIvarInfo *> *ivarInfos;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, WSClassMethodInfo *> *methodInfos;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, WSClassPropertyInfo *> *propertyInfos;

- (void)setNeedUpdate;

- (BOOL)needUpdate;

+ (nullable instancetype)classInfoWithClass:(Class)cls;

+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end


NS_ASSUME_NONNULL_END
