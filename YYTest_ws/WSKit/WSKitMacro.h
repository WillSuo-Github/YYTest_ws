//
//  WSKitMacro.h
//  YYTest_ws
//
//  Created by great Lock on 2018/3/31.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/time.h>
#import <pthread.h>

#ifndef WSKitMacro_h
#define WSKitMacro_h

#ifdef __cplusplus
#define WS_EXTERN_C_BEGIN extern "C" {
#define WS_EXTERN_C_END }
#else
#define WS_EXTERN_C_BEGIN
#define WS_EXTERN_C_END
#endif

WS_EXTERN_C_BEGIN

static inline void dispatch_async_on_main_queue(void(^block)(void)) {
    if (pthread_main_np()) {
        block();
    }else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


WS_EXTERN_C_END

#endif /* WSKitMacro_h */
