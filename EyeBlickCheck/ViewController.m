//
//  ViewController.m
//  EyeBlickCheck
//
//  Created by Nile on 2017/3/17.
//  Copyright © 2017年 Nile. All rights reserved.
//

#import "ViewController.h"
#import "FaceRecognitionService.h"
#import "CaptureFaceService.h"
#import "ShowResultViewController.h"
@interface ViewController ()
@property(nonatomic,strong)FaceRecognitionService * recognitionService;
@property(nonatomic,strong)CaptureFaceService * captureFaceService;
@property (weak, nonatomic) IBOutlet UIView *vidioView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}



- (IBAction)start:(id)sender {
    [self startCaptureFace];
}

- (IBAction)stop:(id)sender {
    [self.captureFaceService stopCaptureFace];
}

- (CaptureFaceService *)captureFaceService{
    if (!_captureFaceService) {
        _captureFaceService = [CaptureFaceService new];
    }
    return _captureFaceService;
}

- (void)startCaptureFace{
    __weak typeof(self)weakSelf = self;
    [self.captureFaceService startAutoCaptureFaceWithPreView:self.vidioView andCaptureFaceProgressBlock:^(float faceProgress, float eyeProgress, captureFaceStatus captureFaceStatus) {
        [weakSelf changeTipTextWithCaptureFaceStatus:captureFaceStatus];
    } andCompleteBlock:^(UIImage *resultImage, NSError *error) {
        if (error) {
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"检测人脸失败,请重试" message: nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [weakSelf startCaptureFace];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [weakSelf presentViewController:alertController animated:YES completion:nil];
            return ;
        }
        [self handleResultImage:resultImage];
    }];
}


- (void)handleResultImage:(UIImage *)resultImage{
    dispatch_async(dispatch_get_main_queue(), ^{
        ShowResultViewController * v = [[ShowResultViewController alloc]init];
        v.resultImage = resultImage;
        [self presentViewController:v animated:YES completion:nil];
    
    });
}

- (void)changeTipTextWithCaptureFaceStatus:(captureFaceStatus)captureFaceStatus{
    NSString * title = @"";
    switch (captureFaceStatus) {
        case captureFaceStatus_NoFace:
            title = @"请正对相机,保证光线充足";
            break;
        case captureFaceStatus_MoreFace:
            title = @"请保证只有一张人脸";
            break;
        case captureFaceStatus_NoBlink:
            title = @"请眨眼";
            break;
        case captureFaceStatus_OK:
            title = @"正在验证,请稍后";
            break;
        case captureFaceStatus_NoCamare:
            title = @"没有相机权限";
            break;
        default:
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = title;
        if (captureFaceStatus == captureFaceStatus_NoCamare) {
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"没有相机权限" message: nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
}



@end
