//
//  ViewController.h
//  Demo04_加入直播间并互动
//
//  Created by jameskhdeng(邓凯辉) on 2018/4/3.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDRCore.h"

@interface ViewController : UIViewController<PDRCoreDelegate>
{
    BOOL _isFullScreen;
    UIStatusBarStyle _statusBarStyle;
}
@property(assign, nonatomic)BOOL showLoadingView;
-(BOOL)getStatusBarHidden;
@end

