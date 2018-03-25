//
//  WSModelExample.m
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "WSModelExample.h"
#import "WSKit.h"

#pragma mark Simple Object Example
@interface WSBook: NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger pages;
@property (nonatomic, strong) NSDate *publishDate;
@end

@implementation WSBook
@end

static void SimpleObjectExample() {
    WSBook *book = [WSBook modelWithJson:@"     \
    {                                           \
       \"name\": \"Harry Potter\",              \
       \"pages\": 512,                          \
       \"publishDate\": \"2010-01-01\"          \
    }"];
    NSLog(@"%@", book);
}

#pragma mark Next Object Example
@interface WSUser: NSObject
@property (nonatomic, assign) uint64_t uid;
@property (nonatomic, copy) NSString *name;
@end

@implementation WSUser
@end

@interface WSRepo: NSObject
@property (nonatomic, assign) uint64_t rid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSData *createTime;
@property (nonatomic, strong) WSUser *owner;
@end

@implementation WSRepo
@end

static void NextObjectExample() {
    WSRepo *repo = [WSRepo modelWithJson:@"         \
    {                                               \
        \"rid\": 123456789,                         \
        \"name\": \"YYKit\",                        \
        \"createTime\" : \"2011-06-09T06:24:26Z\",  \
        \"owner\": {                                \
            \"uid\" : 989898,                       \
            \"name\" : \"ibireme\"                  \
        }                                           \
    }"];
    NSString *repoJson = [repo modelToJSONString];
    NSLog(@"Repo: %@", repoJson);
}

#pragma mark Container Object Example
@interface WSPhoto: NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *desc;
@end

@implementation WSPhoto
@end

@interface WSAlbum: NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) NSDictionary *likedUsers;
@property (nonatomic, strong) NSSet *likedUserIds;
@end

@implementation WSAlbum
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"photos": WSPhoto.class,
             @"likedUsers": WSUser.class,
             @"likedUserIds": NSNumber.class};
}
@end

static void ContainerObjectExample() {
    WSAlbum *album = [WSAlbum modelWithJson:@"          \
    {                                                   \
    \"name\" : \"Happy Birthday\",                      \
    \"photos\" : [                                      \
        {                                               \
            \"url\":\"http://example.com/1.png\",       \
            \"desc\":\"Happy~\"                         \
        },                                              \
        {                                               \
            \"url\":\"http://example.com/2.png\",       \
            \"desc\":\"Yeah!\"                          \
        }                                               \
    ],                                                  \
    \"likedUsers\" : {                                  \
        \"Jony\" : {\"uid\":10001,\"name\":\"Jony\"},   \
        \"Anna\" : {\"uid\":10002,\"name\":\"Anna\"}    \
    },                                                  \
    \"likedUserIds\" : [10001,10002]                    \
    }"];
    NSString *albumJson = [album modelToJSONString];
    NSLog(@"%@", albumJson);
}


#pragma mark Custom Mapper Example

@interface WSMessage: NSObject
@property (nonatomic, assign) uint64_t messageId;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *time;
@end

@implementation WSMessage

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"messageId": @"i",
             @"content": @"c",
             @"time": @"t",};
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    uint64_t timestamp = [dic unsignedLongLongValueForKey:@"t" default:0];
    self.time = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
    return true;
}

- (void)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    dic[@"t"] = @([self.time timeIntervalSince1970] * 1000).description;
}
@end

static void CustomMapperExample() {
    WSMessage *message = [WSMessage modelWithJson:@"{\"i\":\"2000000001\",\"c\":\"Hello\",\"t\":\"1437237598000\"}"];
    NSString *messageJson = [message modelToJSONString];
    NSLog(@"message: %@", messageJson);
}

#pragma mark - Coding/Coping/hash/equal Example
@interface WSShadow: NSObject<NSCoding, NSCopying>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) UIColor *color;
@end

@implementation WSShadow
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self modelEncodeWithCoder:aCoder];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    [self modelInitWithCoder:aDecoder];
}

- (id)copyWithZone:(NSZone *)zone {
    
}
@end


@interface WSModelExample ()

@end

@implementation WSModelExample

- (void)viewDidLoad {
    [super viewDidLoad];
//    SimpleObjectExample();
//    NextObjectExample();
//    ContainerObjectExample();
//    CustomMapperExample();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
