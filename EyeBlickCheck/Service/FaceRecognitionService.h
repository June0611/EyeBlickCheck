//
//  FaceRecognitionService.h
//  MobileCooperativeOffice
//
//  Created by Nile on 2017/1/10.
//  Copyright © 2017年 pcitc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^registerFaceCompleteResultBlock) (NSString * gid,NSError * error);
typedef void (^vertifyFaceCompleteResultBlock) (NSString * score,NSError * error);
@interface FaceRecognitionService : NSObject
//注册
- (void)registerFaceWithImage:(UIImage *)faceImage andUserName:(NSString *)userName andCompleteBlock:(registerFaceCompleteResultBlock)registerFaceCompleteResultBlock;

//验证
- (void)vertifyFaceWithImage:(UIImage *)faceImage andUserName:(NSString *)userName andGid:(NSString *)gid andCompleteBlock:(vertifyFaceCompleteResultBlock)vertifyFaceCompleteResultBlock;







@end
