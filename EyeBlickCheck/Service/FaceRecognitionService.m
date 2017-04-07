//
//  FaceRecognitionService.m
//  MobileCooperativeOffice
//
//  Created by Nile on 2017/1/10.
//  Copyright © 2017年 pcitc. All rights reserved.
//

#import "FaceRecognitionService.h"
#import <iflyMSC/IFlyFaceSDK.h>
#import "IFlyFaceResultKeys.h"
#import "UIImage+Extensions.h"

static NSString * const XFFACEAPPID  = @"5840e1ee";
@interface FaceRecognitionService()
<IFlyFaceRequestDelegate>

@property(nonatomic,copy)registerFaceCompleteResultBlock  registerFaceCompleteResultBlock;
@property(nonatomic,copy)vertifyFaceCompleteResultBlock vertifyFaceCompleteResultBlock;

@property (nonatomic,strong) IFlyFaceRequest * iFlySpFaceRequest;
@property (nonatomic,copy) NSString *resultStings;


@end


@implementation FaceRecognitionService

//注册
- (void)registerFaceWithImage:(UIImage *)faceImage andUserName:(NSString *)userName andCompleteBlock:(registerFaceCompleteResultBlock)registerFaceCompleteResultBlock{
    self.registerFaceCompleteResultBlock = nil;
    self.registerFaceCompleteResultBlock = registerFaceCompleteResultBlock;
    self.iFlySpFaceRequest=[IFlyFaceRequest sharedInstance];
    self.resultStings=nil;
    self.resultStings = [[NSString alloc]init];
    [self.iFlySpFaceRequest setDelegate:self];
    [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_REG] forKey:[IFlySpeechConstant FACE_SST]];
    [self.iFlySpFaceRequest setParameter:XFFACEAPPID forKey:[IFlySpeechConstant APPID]];
    NSLog(@"registerFaceWithImage =====   %@",userName);
    [self.iFlySpFaceRequest setParameter:userName forKey:@"auth_id"];
    [self.iFlySpFaceRequest setParameter:@"del" forKey:@"property"];
    //  压缩图片大小
    NSData* imgData=[faceImage compressedData];
    NSLog(@"reg image data length: %lu",(unsigned long)[imgData length]);
    [self.iFlySpFaceRequest sendRequest:imgData];


}

//验证
- (void)vertifyFaceWithImage:(UIImage *)faceImage andUserName:(NSString *)userName andGid:(NSString *)gid andCompleteBlock:(vertifyFaceCompleteResultBlock)vertifyFaceCompleteResultBlock{
    self.vertifyFaceCompleteResultBlock = nil;
    self.vertifyFaceCompleteResultBlock = vertifyFaceCompleteResultBlock;
    if (!gid) {
        NSError * error = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : @"验证出错"}];
        vertifyFaceCompleteResultBlock(@"0",error);
        return;
    }
    
    self.resultStings=nil;
    self.resultStings=[[NSString alloc] init];
    self.iFlySpFaceRequest=[IFlyFaceRequest sharedInstance];
    [self.iFlySpFaceRequest setDelegate:self];
    [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_VERIFY] forKey:[IFlySpeechConstant FACE_SST]];
    [self.iFlySpFaceRequest setParameter:XFFACEAPPID forKey:[IFlySpeechConstant APPID]];
    [self.iFlySpFaceRequest setParameter:userName forKey:@"auth_id"];
    [self.iFlySpFaceRequest setParameter:gid forKey:[IFlySpeechConstant FACE_GID]];
    [self.iFlySpFaceRequest setParameter:@"2000" forKey:@"wait_time"];
    //  压缩图片大小
    NSData* imgData=[faceImage compressedData];
    NSLog(@"verify image data length: %lu",(unsigned long)[imgData length]);
    [self.iFlySpFaceRequest sendRequest:imgData];

}



#pragma mark - Data Parser

-(void)praseRegResult:(NSString*)result{
    NSString *resultInfo = @"";
    
    @try {
        NSError* resulterror;
        NSString * gid;
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            //注册
            if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"注册错误\n错误码：%@",ret];
                    resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : resultInfo}];
                }else{
                    if(rst && [rst isEqualToString:KCIFlyFaceResultSuccess]){
                        gid=[dic objectForKey:KCIFlyFaceResultGID];
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n注册成功！"];
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n注册失败！"];
                        resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : resultInfo}];
                    }
                }
            }
        }else{
            resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : @"注册失败"}];
        }
        if (self.registerFaceCompleteResultBlock) {
            self.registerFaceCompleteResultBlock(gid,resulterror);
            self.registerFaceCompleteResultBlock = nil;
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
        self.registerFaceCompleteResultBlock = nil;
    }
    
    
}


-(void)praseVerifyResult:(NSString*)result{
    NSString *resultInfo = @"";
    NSError* resulterror;
    NSString * score;
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            
            if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"验证错误\n错误码：%@",ret];
                    resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : resultInfo}];
                }else{
                    if([rst isEqualToString:KCIFlyFaceResultSuccess]){
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n"];
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n"];
                    }
                    NSString* verf=[dic objectForKey:KCIFlyFaceResultVerf];
                    score=[dic objectForKey:KCIFlyFaceResultScore];
                    if([verf boolValue]){
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证成功!"];
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证失败!"];
                        resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : resultInfo}];
                    }
                }
                
            }
            
            
        }else{
            resulterror = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : @"验证失败"}];
        }
        
        if (self.vertifyFaceCompleteResultBlock) {
            self.vertifyFaceCompleteResultBlock(score,resulterror);
            self.vertifyFaceCompleteResultBlock = nil;
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
        self.vertifyFaceCompleteResultBlock = nil;
    }
}


#pragma mark - Perform results On UI

-(void)updateFaceImage:(NSString*)result{
    
    NSError* error;
    NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
    
    if(dic){
        NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
        
        //注册
        if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
            [self praseRegResult:result];
        }
        
        //验证
        if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
            [self praseVerifyResult:result];
        }
    }
}



#pragma mark - IFlyFaceRequestDelegate


/**
 * 消息回调
 * @param eventType 消息类型
 * @param params 消息数据对象
 */
- (void) onEvent:(int) eventType WithBundle:(NSString*) params{
    NSLog(@"onEvent | params:%@",params);
}

/**
 * 数据回调，可能调用多次，也可能一次不调用
 * @param buffer 服务端返回的二进制数据
 */
- (void) onData:(NSData* )data{
    
    NSLog(@"onData | ");
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"result:%@",result);
    
    if (result) {
        self.resultStings=[self.resultStings stringByAppendingString:result];
    }
    
}

/**
 * 结束回调，没有错误时，error为null
 * @param error 错误类型
 */
- (void) onCompleted:(IFlySpeechError*) error{
    NSLog(@"onCompleted | error:%@",[error errorDesc]);
    NSString* errorInfo=[NSString stringWithFormat:@"错误码：%d\n 错误描述：%@",[error errorCode],[error errorDesc]];
    if(0!=[error errorCode]){
        dispatch_async(dispatch_get_main_queue(), ^{
            //处理结果
            NSError * resultError = [NSError errorWithDomain:@"XFError" code:0 userInfo:@{@"errorDesc" : errorInfo}];
            if(self.registerFaceCompleteResultBlock){
                self.registerFaceCompleteResultBlock(nil,resultError);
                self.registerFaceCompleteResultBlock = nil;
            }
            if (self.vertifyFaceCompleteResultBlock) {
                self.vertifyFaceCompleteResultBlock(nil,resultError);
                self.vertifyFaceCompleteResultBlock = nil;
            }
        });
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            //处理结果
            [self updateFaceImage:self.resultStings];
        });
    }
}

@end
