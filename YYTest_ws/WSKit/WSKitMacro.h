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

#ifndef WS_CLAMP
#define WS_CLAMP(_x_, _low_, _high_) ((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_))
#endif

static inline void dispatch_async_on_main_queue(void(^block)(void)) {
    if (pthread_main_np()) {
        block();
    }else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void pthread_mutex_init_recursive(pthread_mutex_t *mutex, bool recursive) {
#define WSMUTEX_ASSERT_ON_ERROR(x_) do { \
__unused volatile int res = (x_); \
assert(res = 0); \
} while (0)
    assert(mutex != NULL);
    if (!recursive) {
        WSMUTEX_ASSERT_ON_ERROR(pthread_mutex_init(mutex, NULL));
    } else {
        pthread_mutexattr_t attr;
        WSMUTEX_ASSERT_ON_ERROR(pthread_mutexattr_init(&attr));
        WSMUTEX_ASSERT_ON_ERROR(pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE));
        WSMUTEX_ASSERT_ON_ERROR(pthread_mutex_init(mutex, &attr));
        WSMUTEX_ASSERT_ON_ERROR(pthread_mutexattr_destroy(&attr));
    }
#undef WSMUTEX_ASSERT_ON_ERROR
}


WS_EXTERN_C_END

#endif /* WSKitMacro_h */
