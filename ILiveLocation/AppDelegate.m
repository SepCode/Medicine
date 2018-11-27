//
//  AppDelegate.m
//  Demo04_加入直播间并互动
//
//  Created by jameskhdeng(邓凯辉) on 2018/4/3.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "AppDelegate.h"
#import <ILiveSDK/ILiveSDK.h>
#import <BMKLocationkit/BMKLocationComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
@import GoogleMaps;
@import GooglePlaces;
#import "PDRCore.h"
#import "PDRCommonString.h"
#import "ViewController.h"

static  const int kSDKAppID = 1400110444;
static  const int kAccountType = 31110;

@interface AppDelegate () <BMKGeneralDelegate, BMKLocationAuthDelegate>
@property (nonatomic, strong) BMKMapManager *mapManager; //主引擎类

@property (strong, nonatomic) ViewController *h5ViewContoller;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 初始化SDK
    [[ILiveSDK getInstance] initSdk:kSDKAppID accountType:kAccountType];
    
    // 初始化定位SDK
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:@"4zkOAQZZTcKOKmHA7wLkwNjGkF0KQXDe" authDelegate:self];
    //要使用百度地图，请先启动BMKMapManager
    _mapManager = [[BMKMapManager alloc] init];
    
    /**
     百度地图SDK所有API均支持百度坐标（BD09）和国测局坐标（GCJ02），用此方法设置您使用的坐标类型.
     默认是BD09（BMK_COORDTYPE_BD09LL）坐标.
     如果需要使用GCJ02坐标，需要设置CoordinateType为：BMK_COORDTYPE_COMMON.
     */
    if ([BMKMapManager setCoordinateTypeUsedInBaiduMapSDK:BMK_COORDTYPE_BD09LL]) {
        NSLog(@"经纬度类型设置成功");
    } else {
        NSLog(@"经纬度类型设置失败");
    }
    
    //启动引擎并设置AK并设置delegate
    BOOL result = [_mapManager start:@"4zkOAQZZTcKOKmHA7wLkwNjGkF0KQXDe" generalDelegate:self];
    if (!result) {
        NSLog(@"启动引擎失败");
    }
    
    /////////////////////////////////////////////
    //googlemap
    
    [GMSPlacesClient provideAPIKey:@"AIzaSyDG26kaonKtG8TDcS2PVJtf1NqKjQFYo2U"];
    [GMSServices provideAPIKey:@"AIzaSyDG26kaonKtG8TDcS2PVJtf1NqKjQFYo2U"];
    
    /////////////////////////////////////////////////////////////////////////////////
    
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window = window;
    
    ViewController *viewController = [[ViewController alloc] init];
    self.h5ViewContoller = viewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.navigationBarHidden = YES;
    [self startMainApp];
    self.h5ViewContoller.showLoadingView = YES;
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    
    
    
    return [PDRCore initEngineWihtOptions:launchOptions
                              withRunMode:PDRCoreRunModeNormal withDelegate:self];;
}

- (void)startMainApp {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[PDRCore Instance] start];
    });
}

- (void)onGetNetworkState:(int)iError {
    if (0 == iError) {
        NSLog(@"联网成功");
    } else {
        NSLog(@"联网失败：%d", iError);
    }
}

/**
 鉴权结果回调
 
 @param iError 鉴权结果错误码信息，0代表鉴权成功
 */
- (void)onGetPermissionState:(int)iError {
    if (0 == iError) {
        NSLog(@"授权成功");
    } else {
        NSLog(@"授权失败：%d", iError);
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void(^)(BOOL succeeded))completionHandler{
    [PDRCore handleSysEvent:PDRCoreSysEventPeekQuickAction withObject:shortcutItem];
    completionHandler(true);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventBecomeActive withObject:nil];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventResignActive withObject:nil];
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventEnterBackground withObject:nil];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [PDRCore handleSysEvent:PDRCoreSysEventEnterForeGround withObject:nil];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [PDRCore destoryEngine];
}

#pragma mark -
#pragma mark URL

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    [self application:application handleOpenURL:url];
    return YES;
}

/*
 * @Summary:程序被第三方调用，传入参数启动
 *
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [PDRCore handleSysEvent:PDRCoreSysEventOpenURL withObject:url];
    return YES;
}

/*
 * @Summary:远程push注册成功收到DeviceToken回调
 *
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"application--didRegisterForRemoteNotificationsWithDeviceToken[%@]", deviceToken);
    [PDRCore handleSysEvent:PDRCoreSysEventRevDeviceToken withObject:deviceToken];
}

/*
 * @Summary: 远程push注册失败
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [PDRCore handleSysEvent:PDRCoreSysEventRegRemoteNotificationsError withObject:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PDRCore handleSysEvent:PDRCoreSysEventRevRemoteNotification withObject:userInfo];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [self application:application didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}


/*
 * @Summary:程序收到本地消息
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [PDRCore handleSysEvent:PDRCoreSysEventRevLocalNotification withObject:notification];
}

@end

@implementation UINavigationController(Orient)

-(BOOL)shouldAutorotate{
    return ![PDRCore Instance].lockScreen;
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if([self.topViewController isKindOfClass:[ViewController class]])
        return [self.topViewController supportedInterfaceOrientations];
    return UIInterfaceOrientationMaskPortrait;
}
@end
