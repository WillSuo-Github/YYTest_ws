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

@implementation
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
    NSString *repoJson = [repo ]
}


@interface WSModelExample ()

@end

@implementation WSModelExample

- (void)viewDidLoad {
    [super viewDidLoad];
    SimpleObjectExample();
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
