//
//  YXService.h
//  YXLogin
//
//  Created by yu chen on 2021/11/9.
//

#import <Foundation/Foundation.h>

typedef void(^YXLoginCompletion)(NSDictionary * _Nullable data, NSError * _Nullable error);

@interface YXService : NSObject

+ (void)startTaskWithPath:(NSString *_Nonnull)path withParameter:(NSDictionary *_Nullable)parameter withCompletion:(YXLoginCompletion _Nonnull )completion;

@end

