// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEGroupCallInfo.h"
#import "NEGroupInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface GroupBaseResult : NSObject

@property(nonatomic, assign) NSInteger code;

@end

@interface GroupCallResult : GroupBaseResult

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, assign) NSInteger callerUid;

@property(nonatomic, assign) NSInteger startTimestamp;

@property(nonatomic, assign) uint64_t channelId;

@end

@interface GroupHangupResult : GroupBaseResult

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, assign) NSInteger reason;

@end

@interface GroupAcceptResult : GroupBaseResult

@property(nonatomic, strong) NEGroupCallInfo *groupCallInfo;

@property(nonatomic, assign) uint64_t channelId;

@end

@interface GroupInviteResult : GroupBaseResult

@property(nonatomic, strong) NSString *callId;

@end

@interface GroupJoinResult : GroupBaseResult

@property(nonatomic, strong) NEGroupCallInfo *groupCallInfo;

@property(nonatomic, assign) uint64_t channelId;

@end

@interface GroupQueryCallInfoResult : GroupBaseResult

@property(nonatomic, strong) NEGroupInfo *groupCallInfo;

@end

@interface GroupQueryMembersResult : GroupBaseResult

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, strong) GroupCallMember *callerInfo;

@property(nonatomic, strong) NSArray<GroupCallMember *> *calleeList;

@end

NS_ASSUME_NONNULL_END
