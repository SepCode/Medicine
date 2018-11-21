//
//  PluginTest.m
//  HBuilder-Hello
//
//  Created by Mac Pro on 14-9-3.
//  Copyright (c) 2014年 DCloud. All rights reserved.
//

#import "PGPluginTest.h"
#import "PDRCoreAppFrame.h"
#import "H5WEEngineExport.h"
#import "PDRToolSystemEx.h"
#import <ILiveSDK/ILiveLoginManager.h>
#import "MapViewController.h"
// 扩展插件中需要引入需要的系统库
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>
#import "LiveRoomViewController.h"



@interface PGPluginTest ()
@property (nonatomic, strong) UIAlertController *alertCtrl;
@end

@implementation PGPluginTest



#pragma mark 这个方法在使用WebApp方式集成时触发，WebView集成方式不触发

/*
 * WebApp启动时触发
 * 需要在PandoraApi.bundle/feature.plist/注册插件里添加autostart值为true，global项的值设置为true
 */
- (void) onAppStarted:(NSDictionary*)options{
   
    NSLog(@"5+ WebApp启动时触发");
    // 可以在这个方法里向Core注册扩展插件的JS
    
}

// 监听基座事件事件
// 应用退出时触发
- (void) onAppTerminate{
    //
    NSLog(@"APPDelegate applicationWillTerminate 事件触发时触发");
}

// 应用进入后台时触发
- (void) onAppEnterBackground{
    //
    NSLog(@"APPDelegate applicationDidEnterBackground 事件触发时触发");
}

// 应用进入前天时触发
- (void) onAppEnterForeground{
    //
    NSLog(@"APPDelegate applicationWillEnterForeground 事件触发时触发");
}

#pragma mark 以下为插件方法，由JS触发， WebView集成和WebApp集成都可以触发


- (void)PluginTestFunction:(PGMethod*)commands
{
	if ( commands ) {
        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
        NSString* cbId = [commands.arguments objectAtIndex:0];
        
        // 用户的参数会在第二个参数传回
        NSString* pArgument1 = [commands.arguments objectAtIndex:1];
        NSString* pArgument2 = [commands.arguments objectAtIndex:2];
        NSString* pArgument3 = [commands.arguments objectAtIndex:3];
        NSString* pArgument4 = [commands.arguments objectAtIndex:4];
        
        
        
        // 如果使用Array方式传递参数
        NSArray* pResultString = [NSArray arrayWithObjects:pArgument1, pArgument2, pArgument3, pArgument4, nil];
        
        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
        // PDRCommandStatusOK 表示触发JS层成功回调方法
        // PDRCommandStatusError 表示触发JS层错误回调方法
        
        // 如果方法需要持续触发页面回调，可以通过修改 PDRPluginResult 对象的keepCallback 属性值来表示当前是否可重复回调， true 表示可以重复回调   false 表示不可重复回调  默认值为false

        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray: pResultString];

        // 如果Native代码运行结果和预期不同，需要通过回调通知JS层出现错误，并返回错误提示
        //PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsString:@"惨了! 出错了！ 咋(wu)整(liao)"];

        // 通知JS层Native层运行结果
        [self toCallback:cbId withReslut:[result toJSONString]];
    }
}


// 调用指纹解锁
- (void)AuthenticateUser:(PGMethod*)command
{
    if (nil == command) {
        return;
    }
    BOOL isSupport = false;
    NSString* pcbid = [command.arguments objectAtIndex:0];
    NSError* error = nil;
    NSString* LocalReason = @"HBuilder指纹验证";
    
    // Touch ID 是IOS 8 以后支持的功能
    if ([PTDeviceOSInfo systemVersion] >= PTSystemVersion8Series) {
        LAContext* context = [[LAContext alloc] init];
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            isSupport = true;
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:LocalReason reply:^(BOOL success, NSError * _Nullable error) {
                PDRPluginResult * pResult = nil;
                
                if (success) {
                    
                    pResult = [PDRPluginResult resultWithStatus: PDRCommandStatusOK messageAsDictionary:@{@"state":@(0), @"message":@"成功"}];
                }
                else{
                    NSDictionary* pStringError = nil;
                    switch (error.code) {
                        case LAErrorSystemCancel:
                        {
                            pStringError = @{@"state":@(-1), @"message":@"系统取消授权(例如其他APP切入)"};
                            break;
                        }
                        case LAErrorUserCancel:
                        {
                            pStringError = @{@"state":@(-2), @"message":@"用户取消Touch ID授权"};
                            break;
                        }
                        case LAErrorUserFallback:
                        {
                            pStringError  = @{@"state":@(-3), @"message":@"用户选择输入密码"};
                            break;
                        }
                        case LAErrorTouchIDNotAvailable:{
                            pStringError  = @{@"state":@(-4), @"message":@"设备Touch ID不可用"};
                            break;
                        }
                        case LAErrorTouchIDLockout:{
                            pStringError  = @{@"state":@(-5), @"message":@"Touch ID被锁"};
                            break;
                        }
                        case LAErrorAppCancel:{
                            pStringError  = @{@"state":@(-6), @"message":@"软件被挂起取消授权"};
                            break;
                        }
                        default:
                        {
                            pStringError  = @{@"state":@(-7), @"message":@"其他错误"};
                            break;
                        }
                    }
                    pResult = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsDictionary:pStringError];
                    
                }
                
                [self toCallback:pcbid withReslut:[pResult toJSONString]];
            }];
        }
        else{
            NSDictionary* pStringError = nil;
            switch (error.code) {
                case LAErrorTouchIDNotEnrolled:
                {
                    pStringError  = @{@"state":@(-11), @"message":@"设备Touch ID不可用"};
                    break;
                }
                case LAErrorPasscodeNotSet:
                {
                    pStringError  = @{@"state":@(-12), @"message":@"用户未录入Touch ID"};
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
   
    if (!isSupport) {
        PDRPluginResult* pResult = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsString:@"Device Not Support"];
        [self toCallback:pcbid withReslut:[pResult toJSONString]];
    }
}


- (NSData*)PluginTestFunctionSync:(PGMethod*)command
{
    // 根据传入获取参数
    NSString* pArgument1 = [command.arguments objectAtIndex:0];
    NSString* pArgument2 = [command.arguments objectAtIndex:1];
    NSString* pArgument3 = [command.arguments objectAtIndex:2];
    NSString* pArgument4 = [command.arguments objectAtIndex:3];
    
    // 拼接成字符串
    NSString* pResultString = [NSString stringWithFormat:@"%@ %@ %@ %@", pArgument1, pArgument2, pArgument3, pArgument4];

    // 按照字符串方式返回结果
    return [self resultWithString: pResultString];
}


- (NSData*)PluginTestFunctionSyncArrayArgu:(PGMethod*)command
{
    // 根据传入参数获取一个Array，可以从中获取参数
    NSArray* pArray = [command.arguments objectAtIndex:0];
    
    // 创建一个作为返回值的NSDictionary
    NSDictionary* pResultDic = [NSDictionary dictionaryWithObjects:pArray forKeys:[NSArray arrayWithObjects:@"RetArgu1",@"RetArgu2",@"RetArgu3", @"RetArgu4", nil]];

    // 返回类型为JSON，JS层在取值是需要按照JSON进行获取
    return [self resultWithJSON: pResultDic];
}



- (NSData*)openMap:(PGMethod*)commands {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        MapViewController * vc = [[MapViewController alloc] init];
        [(UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController pushViewController:vc animated:YES];
        vc.navigationController.navigationBarHidden = NO;
        
    });
    
    
    return nil;
}


- (void)loginILive:(PGMethod*)commands {
    
    if ( commands ) {
        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
        NSString* cbId = [commands.arguments objectAtIndex:0];
        
        // 用户的参数会在第二个参数传回
        NSString* pArgument1 = [commands.arguments objectAtIndex:1];
        NSString* pArgument2 = [commands.arguments objectAtIndex:2];
        
        // 如果使用Array方式传递参数
        //登录sdk
        [[ILiveLoginManager getInstance] iLiveLogin:pArgument1 sig:pArgument2 succ:^{
            
            // 登录成功
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray: nil];
            [self toCallback:cbId withReslut:[result toJSONString]];
            
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            // 登录失败
            NSArray* pResultString = [NSArray arrayWithObjects:module, @(errId), errMsg, nil];
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsArray: pResultString];
            [self toCallback:cbId withReslut:[result toJSONString]];
        }];
        
        
        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
        // PDRCommandStatusOK 表示触发JS层成功回调方法
        // PDRCommandStatusError 表示触发JS层错误回调方法
        
        // 如果方法需要持续触发页面回调，可以通过修改 PDRPluginResult 对象的keepCallback 属性值来表示当前是否可重复回调， true 表示可以重复回调   false 表示不可重复回调  默认值为false
        
        
    }
    
    
}



- (void)joinRoom:(PGMethod*)commands {
    
    [self detectAuthorizationStatus];
    
    if ( commands ) {
        // CallBackid 异步方法的回调id，H5+ 会根据回调ID通知JS层运行结果成功或者失败
        NSString* cbId = [commands.arguments objectAtIndex:0];
        
        // 用户的参数会在第二个参数传回
        NSString* pArgument1 = [commands.arguments objectAtIndex:1];
        NSString* pArgument2 = [commands.arguments objectAtIndex:2];
        
        UINavigationController *nv = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        
        
        // 运行Native代码结果和预期相同，调用回调通知JS层运行成功并返回结果
        // PDRCommandStatusOK 表示触发JS层成功回调方法
        // PDRCommandStatusError 表示触发JS层错误回调方法
        
        // 如果方法需要持续触发页面回调，可以通过修改 PDRPluginResult 对象的keepCallback 属性值来表示当前是否可重复回调， true 表示可以重复回调   false 表示不可重复回调  默认值为false
        
        // 1. 创建live房间页面
        LiveRoomViewController *liveRoomVC = [[LiveRoomViewController alloc] init];
        
        // 2. 创建房间配置对象
        ILiveRoomOption *option = [ILiveRoomOption defaultHostLiveOption];
        option.imOption.imSupport = NO;
        // 不自动打开摄像头
        option.avOption.autoCamera = NO;
        // 不自动打开mic
        option.avOption.autoMic = NO;
        // 设置房间内音视频监听
        option.memberStatusListener = liveRoomVC;
        // 设置房间中断事件监听
        option.roomDisconnectListener = liveRoomVC;
        
        // 该参数代表进房之后使用什么规格音视频参数，参数具体值为客户在腾讯云实时音视频控制台画面设定中配置的角色名（例如：默认角色名为user, 可设置controlRole = @"user"）
        option.controlRole = @"user";
        
        // 3. 调用创建房间接口，传入房间ID和房间配置对象
        [[ILiveRoomManager getInstance] joinRoom:[pArgument1 intValue] option:option succ:^{
            
            // 加入房间成功
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray: nil];
            [self toCallback:cbId withReslut:[result toJSONString]];
            // 加入房间成功，跳转到房间页
            [nv presentViewController:liveRoomVC animated:YES completion:nil];
            
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            
            // 加入房间失败
            NSArray* pResultString = [NSArray arrayWithObjects:module, @(errId), errMsg, nil];
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusError messageAsArray: pResultString];
            [self toCallback:cbId withReslut:[result toJSONString]];
        }];
        
    }
    
    
    
}

#pragma mark - Custom Method
// 检测音视频权限
- (void)detectAuthorizationStatus {
    
    UINavigationController *nv = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    
    // 检测是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusRestricted || statusVideo == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取摄像头权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [nv presentViewController:self.alertCtrl animated:YES completion:nil];
        return;
    } else if (statusVideo == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
        }];
    }
    
    // 检测是否有麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusRestricted || statusAudio == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [nv presentViewController:self.alertCtrl animated:YES completion:nil];
        return;
    } else if (statusAudio == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
    }
}

#pragma mark - Accessor
- (UIAlertController *)alertCtrl {
    if (!_alertCtrl) {
        _alertCtrl = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }] ;
        [_alertCtrl addAction:action];
    }
    return _alertCtrl;
}

static NSString * const kUserName = @"cf";
static NSString * const kUserSig = @"eJxlz1FLwzAQwPH3foqS14lemgRF2MOwIpW1dK5QfAppm7anNevSWN3E7y6rAwve6*9-HPfl*b5PsvX2UpXl7t046Q69Jv6tT4Bc-GHfYyWVk8xW-1B-9mi1VLXTdkIqhAgA5g1W2jis8VyU9cyG6lVOB36XOQClwDmfJ9hMGN9v7qLQihSLPGTYBk16ZZ7VzV49GVDF2h7aMe501mx0VoxRtsJVlw5hwthLnsTxuFjshyPtskcHbU6TGpM*d0X3sI04HD*Wy9lJh2-6-A2jLADGr2c6ajvgzkxBAFTQgMFpiPft-QDyyFx6" ;
static NSString * const kUserName1 = @"fc";
static NSString * const kUserSig1 = @"eJxlz0FrgzAUwPG7nyLk2rEmMdF1sIPYbna0w9YOdJfgNEqqi5pmMin77mO2MGHv*vs-Hu9sAQDgYRPdplnWfCrDzdAKCO4BRPDmD9tW5jw13Nb5PxRfrdSCp4URekTMGCMITRuZC2VkIa9FkU3slFd8PHBZpghhjCil00SWI25Xr-46qHdlUjtv3ZP28N7fL2jRd6F2Z97j3WYwfUSZKdN4FixfPLnyNE5JrLKQrbc6OcyTY33sniunWdY*iYqODfMwiFVXvZPdw*SkkR-i*o1NHExcl020F-okGzUGBGGGiY1*B1rf1g9njVto" ;

@end
