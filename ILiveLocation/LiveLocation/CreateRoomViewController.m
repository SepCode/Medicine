//
//  CreateRoomViewController.m
//  Demo03_创建直播间
//
//  Created by jameskhdeng(邓凯辉) on 2018/3/30.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CreateRoomViewController.h"
#import <ILiveSDK/ILiveCoreHeader.h>
#import "LiveRoomViewController.h"

@interface CreateRoomViewController ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTF;
@property (nonatomic, strong) UIAlertController *alertCtrl;     //!< 提示框

@end

@implementation CreateRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"创建直播间";
    
    // 房间号默认值，用户也可手动输入
    self.roomIDTF.text = @"8888";
    
    // 检测音视频权限
    [self detectAuthorizationStatus];
}

// 创建房间
- (IBAction)onCreateRoom:(id)sender {
    // 1. 创建live房间页面
    LiveRoomViewController *liveRoomVC = [[LiveRoomViewController alloc] init];
    
    // 2. 创建房间配置对象
    ILiveRoomOption *option = [ILiveRoomOption defaultHostLiveOption];
    option.imOption.imSupport = NO;
    // 设置房间内音视频监听
    option.memberStatusListener = liveRoomVC;
    // 设置房间中断事件监听
    option.roomDisconnectListener = liveRoomVC;
    
    // 3. 调用创建房间接口，传入房间ID和房间配置对象
    [[ILiveRoomManager getInstance] createRoom:[self.roomIDTF.text intValue] option:option succ:^{
        // 创建房间成功，跳转到房间页
        [self presentViewController:liveRoomVC animated:YES completion:nil];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        // 创建房间失败
        self.alertCtrl.title = @"创建房间失败";
        self.alertCtrl.message = [NSString stringWithFormat:@"errId:%d errMsg:%@",errId, errMsg];
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
    }];
    
}

- (IBAction)onJoinRoom:(id)sender {
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
    [[ILiveRoomManager getInstance] joinRoom:[self.roomIDTF.text intValue] option:option succ:^{
        // 加入房间成功，跳转到房间页
        [self presentViewController:liveRoomVC animated:YES completion:nil];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        // 加入房间失败
        self.alertCtrl.title = @"加入房间失败";
        self.alertCtrl.message = [NSString stringWithFormat:@"errId:%d errMsg:%@",errId, errMsg];
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
    }];
}

#pragma mark - Custom Method
// 检测音视频权限
- (void)detectAuthorizationStatus {
    // 检测是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusRestricted || statusVideo == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取摄像头权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
        return;
    } else if (statusVideo == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
        }];
    }
    
    // 检测是否有麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusRestricted || statusAudio == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
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

@end
