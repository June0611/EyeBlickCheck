//
//  ShowResultViewController.m
//  EyeBlickCheck
//
//  Created by Nile on 2017/3/18.
//  Copyright © 2017年 Nile. All rights reserved.
//

#import "ShowResultViewController.h"

@interface ShowResultViewController ()

@end

@implementation ShowResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIImageView * imageV = [[UIImageView alloc]initWithFrame:self.view.bounds];
    imageV.userInteractionEnabled = YES;
    imageV.image = self.resultImage;
    imageV.contentMode = UIViewContentModeScaleAspectFit;
    UITapGestureRecognizer *singleTap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(back)];
    [imageV addGestureRecognizer:singleTap1];
    [self.view addSubview:imageV];
}

- (void)back{
    NSLog(@"back");
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
