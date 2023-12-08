#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "YXLogin.h"
#import "AuthorManager.h"
#import "ImageManager.h"
#import "LanguageManager.h"
#import "YXConfig.h"
#import "YXUserInfo.h"
#import "AuthorServiceProtocol.h"

FOUNDATION_EXPORT double YXLoginVersionNumber;
FOUNDATION_EXPORT const unsigned char YXLoginVersionString[];

