//
//  YXUserInfo.h
//  YXLogin
//
//  Created by yu chen on 2021/11/3.
//

#import <Foundation/Foundation.h>


@interface YXUserInfo : NSObject

@property(nonatomic, strong) NSString *user;
@property(nonatomic, strong) NSString *accessToken;
@property(nonatomic, strong) NSString *imAccid;
@property(nonatomic, strong) NSString *imToken;
@property(nonatomic, strong) NSString *avatar;
@property(nonatomic, strong) NSString *avRoomUid;
@property(nonatomic, strong) NSString *nickname;
@property(nonatomic, strong) NSString *accountId;

@end
