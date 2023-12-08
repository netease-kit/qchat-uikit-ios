// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
// #import "NERtcCallKitConsts.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEHangupParam : NSObject

@property(nonatomic, strong) NSString *channelId;

@property(nonatomic, strong, nullable) NSString *extraString;

@end

NS_ASSUME_NONNULL_END
