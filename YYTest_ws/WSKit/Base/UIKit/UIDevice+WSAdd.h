//
//  UIDevice+WSAdd.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/27.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (WSAdd)

+ (double)systemVersion;

@end


#ifndef kSystemVersion
#define kSystemVersion [UIDevice systemVersion]
#endif
