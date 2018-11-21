//
//  LiveRoomViewController.m
//  Demo03_创建直播间
//
//  Created by jameskhdeng(邓凯辉) on 2018/3/30.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LiveRoomViewController.h"

@interface LiveRoomViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *top;
@property (weak, nonatomic) IBOutlet UIButton *upVideoButton;
@property (nonatomic, weak) UIView *maxSizeView;
@end

@implementation LiveRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"直播间";
    self.view.layer.cornerRadius = 15;
    
    
    if ([UIScreen mainScreen].bounds.size.height >= 812.0) {
        self.top.constant = 20 + 24;
    } else {
        self.top.constant = 20;
    }
    
    
    
    
    // 上麦，打开摄像头和麦克风
    [[ILiveRoomManager getInstance] enableCamera:CameraPosFront enable:YES succ:^{
        NSLog(@"打开摄像头成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"打开摄像头失败");
    }];
    
    [[ILiveRoomManager getInstance] enableMic:YES succ:^{
        NSLog(@"打开麦克风成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"打开麦克风失败");
    }];
}

// 房间销毁时记得调用退出房间接口
- (void)dealloc {
    [[ILiveRoomManager getInstance] quitRoom:^{
        NSLog(@"退出房间成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"退出房间失败 %d : %@", errId, errMsg);
    }];
}


- (IBAction)micBtnClick:(UIButton *)sender {
    BOOL enable = [[ILiveRoomManager getInstance] getCurMicState];
    
    
    [[ILiveRoomManager getInstance] enableMic:!enable succ:^{
        
        if (enable) {
            [sender setImage:[UIImage imageNamed:@"micClose"] forState:UIControlStateNormal];
        } else {
            [sender setImage:[UIImage imageNamed:@"micOpen"] forState:UIControlStateNormal];
        }
        
        NSLog(@"打开麦克风成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"打开麦克风失败");
    }];
}


//- (IBAction)camBtnClick:(UIButton *)sender {
//    
//    BOOL enable = [[ILiveRoomManager getInstance] getCurCameraState];
//    
//    
//    
//    [[ILiveRoomManager getInstance] enableCamera:CameraPosFront enable:!enable succ:^{
//        
//        if (enable) {
//            [sender setImage:[UIImage imageNamed:@"camClose"] forState:UIControlStateNormal];
//        } else {
//            [sender setImage:[UIImage imageNamed:@"camOpen"] forState:UIControlStateNormal];
//        }
//        
//        NSLog(@"打开摄像头成功");
//    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        NSLog(@"打开摄像头失败");
//    }];
//}


// 上/下麦
- (IBAction)upToVideo:(id)sender {
    
    // 下麦，关闭摄像头和麦克风
    [[ILiveRoomManager getInstance] enableCamera:CameraPosFront enable:NO succ:^{
        NSLog(@"打开摄像头成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"打开摄像头失败");
    }];
    
    [[ILiveRoomManager getInstance] enableMic:NO succ:^{
        NSLog(@"打开麦克风成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"打开麦克风失败");
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Custom Action

// 房间内上麦用户数量变化时调用，重新布局所有渲染视图，这里简单处理，从上到下等分布局
- (void)onCameraNumChange {
    // 获取当前所有渲染视图
    NSArray *allRenderViews = [[[ILiveRoomManager getInstance] getFrameDispatcher] getAllRenderViews];
    
    // 检测异常情况
    if (allRenderViews.count == 0) {
        return;
    }
    
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    
    // 计算并设置每一个渲染视图的frame
    CGFloat margin = 10.0;
    CGFloat renderViewWidth = (screenW - 4 * margin) / 3;
    CGFloat renderViewHeight = renderViewWidth * 4.0 / 3;
    
    __block CGFloat renderViewY = 0.f;
    __block CGFloat renderViewX = 0.f;
    
    [allRenderViews enumerateObjectsUsingBlock:^(ILiveRenderView *renderView, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!idx) {
            renderView.frame = self.view.bounds;
            [self.view sendSubviewToBack:renderView];
            self.maxSizeView = renderView;
        } else {
            
            
            renderViewX = (renderViewWidth + margin) * idx - renderViewWidth;
            renderViewY = screenH - renderViewHeight - margin;
            
            CGRect frame = CGRectMake(renderViewX, renderViewY, renderViewWidth, renderViewHeight);
            renderView.frame = frame;
            
        }
        

        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewClick:)];
        [renderView addGestureRecognizer:tap];
        
    }];
}


- (void)viewClick:(UITapGestureRecognizer *)tap {
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    [self.view sendSubviewToBack:tap.view];
    [UIView animateWithDuration:0.25 animations:^{
        self.view.userInteractionEnabled = NO;
        if (tap.view.frame.size.width != screenW) {
            self.maxSizeView.frame = tap.view.frame;
            tap.view.frame = self.view.bounds;
            self.maxSizeView = tap.view;
        }
        
    } completion:^(BOOL finished) {
        self.view.userInteractionEnabled = YES;
    }];
    
}

#pragma mark - ILiveMemStatusListener
// 音视频事件回调
- (BOOL)onEndpointsUpdateInfo:(QAVUpdateEvent)event updateList:(NSArray *)endpoints {
    if (endpoints.count <= 0) {
        return NO;
    }
    for (QAVEndpoint *endpoint in endpoints) {
        switch (event) {
            case QAV_EVENT_ID_ENDPOINT_HAS_CAMERA_VIDEO:
            {
                /*
                 创建并添加渲染视图，传入userID和渲染画面类型，这里传入 QAVVIDEO_SRC_TYPE_CAMERA（摄像头画面）,
                 */
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier:endpoint.identifier srcType:QAVVIDEO_SRC_TYPE_CAMERA];
                
                [self.view addSubview:renderView];
                [self.view sendSubviewToBack:renderView];
                // 房间内上麦用户数量变化，重新布局渲染视图
                [self onCameraNumChange];
            }
                break;
            case QAV_EVENT_ID_ENDPOINT_NO_CAMERA_VIDEO:
            {
                // 移除渲染视图
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher removeRenderViewFor:endpoint.identifier srcType:QAVVIDEO_SRC_TYPE_CAMERA];
                [renderView removeFromSuperview];
                 // 房间内上麦用户数量变化，重新布局渲染视图
                 [self onCameraNumChange];
            }
                break;
            default:
                break;
        }
    }
    return YES;
}

#pragma mark - ILiveRoomDisconnectListener
/**
 SDK主动退出房间提示。该回调方法表示SDK内部主动退出了房间。SDK内部会因为30s心跳包超时等原因主动退出房间，APP需要监听此退出房间事件并对该事件进行相应处理
 
 @param reason 退出房间的原因，具体值见返回码
 
 @return YES 执行成功
 */
- (BOOL)onRoomDisconnect:(int)reason {
    NSLog(@"房间异常退出：%d", reason);
    return YES;
}

@end

