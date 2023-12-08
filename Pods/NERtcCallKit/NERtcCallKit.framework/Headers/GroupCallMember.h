// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "GroupHeader.h"

@interface GroupCallMember : NSObject

@property(nonatomic, strong) NSString *imAccid;

@property(nonatomic, assign) int64_t rtcUid;
/**
 多人通话用户状态 {@link GroupHeader}
 */
@property(nonatomic, assign) NSInteger state;
/**
 多人通话用户行为 {@link GroupHeader}
 */
@property(nonatomic, strong) NSString *action;
/**
 扩展字段，主叫透传被叫
 */
@property(nonatomic, strong) NSString *extraInfo;

@property(nonatomic, assign) BOOL isOpenVideo;

@end
