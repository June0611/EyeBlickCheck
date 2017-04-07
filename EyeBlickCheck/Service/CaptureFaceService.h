//
//  CaptureFaceService.h
//  MobileCooperativeOffice
//
//  Created by Nile on 2017/3/7.
//  Copyright © 2017年 pcitc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
typedef enum
{
    captureFaceStatus_NoFace,       //未检测到脸
    captureFaceStatus_MoreFace,     //有多张脸
    captureFaceStatus_NoBlink,      //未眨眼
    captureFaceStatus_IllegalData,  //检测非法
    captureFaceStatus_OK,           //检测完成
    captureFaceStatus_NoCamare     //检测完成

}captureFaceStatus;

typedef void (^captureFaceProgressBlock ) (float faceProgress,float eyeProgress,captureFaceStatus captureFaceStatus);
typedef void (^captureFaceCompleteResultBlock) (UIImage *resultImage,NSError * error);
@interface CaptureFaceService : NSObject <CvVideoCameraDelegate>


/**
 开启智能扫描人脸(包含活体检测--眨眼)

 @param preView 视频预览区域
 @param captureFaceProgressBlock 过程回调
 @param captureFaceCompleteResultBlock 完成回调
 */
- (void)startAutoCaptureFaceWithPreView:(UIView *)preView andCaptureFaceProgressBlock:(captureFaceProgressBlock)captureFaceProgressBlock andCompleteBlock:(captureFaceCompleteResultBlock)captureFaceCompleteResultBlock;


/**
 停止采集
 */
- (void)stopCaptureFace;
@end
