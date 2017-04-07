//
//  CaptureFaceService.m
//  MobileCooperativeOffice
//
//  Created by Nile on 2017/3/7.
//  Copyright © 2017年 pcitc. All rights reserved.
//

#import "CaptureFaceService.h"

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "UIImage+OpenCV.h"
#import "PermissionDetector.h"
using namespace cv;

@interface CaptureFaceService()
{
    std::deque<int>    _eyesCounter;
    CascadeClassifier  _eyeCascade;
    CascadeClassifier  _faceCascade;
    BOOL               _haveTask;
    BOOL               _isCaptureing;
}


@property (nonatomic, strong) CvVideoCamera * videoCamera;
@property (weak,   nonatomic) UIView        * viewContainer;
@property (nonatomic, strong) NSDate        * startDate;


//回调
@property(nonatomic,copy)captureFaceProgressBlock  captureFaceProgressBlock;
@property(nonatomic,copy)captureFaceCompleteResultBlock captureFaceCompleteResultBlock;

@end

@implementation CaptureFaceService

- (void)startAutoCaptureFaceWithPreView:(UIView *)preView andCaptureFaceProgressBlock:(captureFaceProgressBlock)captureFaceProgressBlock andCompleteBlock:(captureFaceCompleteResultBlock)captureFaceCompleteResultBlock{
    self.viewContainer = preView;
    self.captureFaceProgressBlock = captureFaceProgressBlock;
    self.captureFaceCompleteResultBlock = captureFaceCompleteResultBlock;
    if(![PermissionDetector isCapturePermissionGranted]){
        [self handleCaptureProgressCallBackWithFaceProgress:0.0f andEyeProgress:0.0f andCaptureFaceStatus:captureFaceStatus_NoCamare];
        return;
    }
    
    [self setupCamre];
    [self setupDetector];
    [self start];
}


- (void)setupCamre{
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.viewContainer];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    self.videoCamera.rotateVideo = NO;
    self.videoCamera.useAVCaptureVideoPreviewLayer = YES;
}

//设置检测器
- (void)setupDetector{
    
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                ofType:@"xml"];
    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    _faceCascade.load(CASCADE_NAME);
    
    NSString *eyesCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye"
                                                                ofType:@"xml"];
    CFStringGetFileSystemRepresentation( (CFStringRef)eyesCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    
    _eyeCascade.load(CASCADE_NAME);
    free(CASCADE_NAME);
}

- (CascadeClassifier*)loadCascadeClassifier:(NSString*)path {
    return new CascadeClassifier([[[NSBundle mainBundle] pathForResource:path ofType:@"xml"] UTF8String]);
}

#pragma mark - 人脸活体检测相关
//检测超时
- (BOOL)checkCaptureFaceIsOutTime{
    if (self.startDate == nil) {
        self.startDate = [NSDate date];
    }
    NSDate * now = [NSDate date];
    NSTimeInterval captureTime = [now timeIntervalSinceDate:self.startDate];
    return (captureTime > 20.f);
}

//处理超时
- (void)handleCaptureFaceTimeOut{
    NSError * error = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : @"识别超时"}];
    [self handleCaptureCompleteCallBackWithError:error andResultImage:nil];
    [self stop];
}

//检测人脸
- (std::vector<cv::Rect>)checkFacesWithImage:(cv::Mat &)image{
    
    std::vector<cv::Rect> rects;
    Mat gray, smallImg( cvRound (image.rows), cvRound(image.cols), CV_8UC1 );
    cvtColor( image, gray, COLOR_BGR2GRAY );
    resize( gray, smallImg, smallImg.size(), 0, 0, INTER_LINEAR );
    equalizeHist( smallImg, smallImg );
    double scalingFactor = 1.1;
    int minRects = 2;
    cv::Size minSize(30,30);
    _faceCascade.detectMultiScale( smallImg, rects,
                                   scalingFactor, minRects, 0,
                                   minSize );
    return rects;
}

//检测眨眼
- (void)checkBlickWithRects:(std::vector<cv::Rect>)rects andImage:(cv::Mat &)image{
    
    cv::Rect& faceR = rects[0];
    cv::Rect faceEyeZone( cv::Point(faceR.x + 0.12f * faceR.width,
                                    faceR.y + 0.17f * faceR.height),
                         cv::Size(0.76 * faceR.width,
                                  0.4f * faceR.height));
    rects.clear();
    rectangle(image, faceR, Scalar(0,255,0));
    rectangle(image, faceEyeZone, Scalar(0,255,0));
    Mat eyeImage(image, faceEyeZone);
    _eyeCascade.detectMultiScale(eyeImage, rects, 1.2f, 5, CV_HAAR_SCALE_IMAGE,
                                  cv::Size(faceEyeZone.width * 0.2f, faceEyeZone.width * 0.2f),
                                  cv::Size(0.5f * faceEyeZone.width, 0.7f * faceEyeZone.height));
    [self registerEyesCount:(int)rects.size()];

}

//检测人脸是否符合
- (BOOL)checkFaceIsOkAndCallBackProgressWithRects:(std::vector<cv::Rect>)rects{
    if (!rects.size()) {//没有找到人脸
        [self handleCaptureProgressCallBackWithFaceProgress:0.0 andEyeProgress:0.0 andCaptureFaceStatus:captureFaceStatus_NoFace];
        [self resetDateAndTickCount];
        return NO;
    }
    
    if(rects.size() > 1){//多张人脸
        [self handleCaptureProgressCallBackWithFaceProgress:0.0 andEyeProgress:0.0 andCaptureFaceStatus:captureFaceStatus_MoreFace];
        [self resetDateAndTickCount];
        return NO;
    }
    return YES;
}

//Mat -- > UIImage
- (UIImage *)getResultImageFormMat:(cv::Mat &)image{
    Mat rgbImage;
    cvtColor( image, rgbImage, COLOR_BGR2RGB );
    return [UIImage imageFromCVMat:rgbImage];
}

//记录人眼
- (void)registerEyesCount:(int)count {
    
    NSLog(@"注册:%d",count);
    if (_eyesCounter.empty() || (_eyesCounter[_eyesCounter.size() - 1] != count))
        _eyesCounter.push_back(count);
    
    if (_eyesCounter.size() > 3)
        _eyesCounter.pop_front();
};

//检测眨眼
- (BOOL)checkBlink {
    if (_eyesCounter.size() == 3){
        return (_eyesCounter[2] > 0)
        &&
        (_eyesCounter[1] == 0)
        &&
        (_eyesCounter[0] > 0);
    }
    return NO;
};

#pragma mark - opencvdelegate
- (void)processImage:(cv::Mat &)image{
    if (!_isCaptureing) {
        return;
    }
    _haveTask = YES;
    if ([self checkCaptureFaceIsOutTime]) {
        //超时处理 -- 停止检测 -- 代理回调
        [self handleCaptureFaceTimeOut];
        _haveTask = NO;
        return;
    }
    std::vector<cv::Rect> rects = [self checkFacesWithImage:image];
    if (![self checkFaceIsOkAndCallBackProgressWithRects:rects]) {
        _haveTask = NO;
        return;
    }
    
    [self handleCaptureProgressCallBackWithFaceProgress:1.0 andEyeProgress:0.7 andCaptureFaceStatus:captureFaceStatus_NoBlink];
    [self checkBlickWithRects:rects andImage:image];
    
    if ([self checkBlink]){
        [self handleCaptureProgressCallBackWithFaceProgress:1.0 andEyeProgress:1.0 andCaptureFaceStatus:captureFaceStatus_OK];
        [self handleCaptureCompleteCallBackWithError:nil andResultImage:[self getResultImageFormMat:image]];
        [self stop];
    }
    _haveTask = NO;
}




#pragma mark - 回调---
- (void)handleCaptureProgressCallBackWithFaceProgress:(float)faceProgress
                                       andEyeProgress:(float)eyeProgress
                                 andCaptureFaceStatus:(captureFaceStatus)captureFaceStatus{
    if (self.captureFaceProgressBlock) {
        self.captureFaceProgressBlock(faceProgress,eyeProgress,captureFaceStatus);
    }
}

- (void)handleCaptureCompleteCallBackWithError:(NSError *)error andResultImage:(UIImage *)resultImage{
    if (self.captureFaceCompleteResultBlock) {
        self.captureFaceCompleteResultBlock(resultImage,error);
    }
}

#pragma mark - Start and Stop Running
- (void)resetDateAndTickCount{
    _eyesCounter.clear();
}

- (void)start{
    _isCaptureing = YES;
    [self.videoCamera start];
}

- (void)stopCaptureFace{
    [self stop];
}

- (void)stop{
    //清除回调
    _isCaptureing = NO;
    [self.videoCamera.captureSession stopRunning];
    [self removeAllCallBack];
    self.startDate = nil;
    [self resetDateAndTickCount];
}

- (void)removeAllCallBack{
    self.captureFaceCompleteResultBlock = nil;
    self.captureFaceProgressBlock = nil;
}

#pragma mark - 生命周期
- (void)dealloc{
    while (_haveTask) {}
    [self.videoCamera stop];
    NSLog(@"%s",__func__);
}

@end
