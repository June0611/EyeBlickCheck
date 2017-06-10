# EyeBlickCheck
人脸识别--活体检测--眨眼检测

# 使用方法

```
@property(nonatomic,strong)CaptureFaceService * captureFaceService;
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
        //处理采集到的图片
        [self handleResultImage:resultImage];
    }];
}
```

# 注意:
1.去opencv 官网,下载iOS的SDK,我demo中用的是2.4版本
http://opencv.org/releases.html
2.去度娘  (haarcascade_frontalface_alt2.xml) (haarcascade_eye.xml)这两个级联分类器并下载导入到自己的项目中
