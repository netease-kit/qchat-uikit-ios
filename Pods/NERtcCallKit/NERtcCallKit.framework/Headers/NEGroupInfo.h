// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "GroupCallMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEGroupInfo : NSObject

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, strong) GroupCallMember *callerInfo;

@property(nonatomic, strong) NSString *groupId;

@property(nonatomic, assign) NSInteger groupType;

@property(nonatomic, assign) NSInteger inviteMode;  // GroupInviteMode

@property(nonatomic, assign) NSInteger joinMode;  // GroupJoinMode

@property(nonatomic, assign) NSInteger startTimestamp;

@property(nonatomic, strong) NSString *extraInfo;

@end

NS_ASSUME_NONNULL_END
