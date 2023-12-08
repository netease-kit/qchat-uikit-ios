// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcSDK/NERtcSDK.h>
#import "NECallEngineConsts.h"
#import "NECallPushConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface NECallParam : NSObject

@property(nonatomic, strong) NSString *accId;

@property(nonatomic, strong, nullable) NSString *extraInfo;

@property(nonatomic, strong, nullable) NSString *rtcChannelName;

@property(nonatomic, strong, nullable) NSString *globalExtraCopy;

@property(nonatomic, assign) NECallType callType;

@property(nonatomic, strong, nullable) NECallPushConfig *pushConfig;

- (instancetype)initWithAccId:(NSString *)accId withCallType:(NECallType)callType;

@end

NS_ASSUME_NONNULL_END
