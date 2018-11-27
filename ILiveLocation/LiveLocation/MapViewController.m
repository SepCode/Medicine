//
//  MapViewController.m
//  ILiveLocation
//
//  Created by CF on 2018/9/8.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "MapViewController.h"
#import "MapSearchViewController.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BMKLocationKit/BMKLocationComponent.h>
#import <Masonry.h>
#import "UIView+Frame.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapViewController () <BMKMapViewDelegate, BMKLocationManagerDelegate, UISearchBarDelegate, GMSMapViewDelegate>
@property (nonatomic, strong) MapSearchViewController *search;
@property (nonatomic, strong) UIButton *searchBtn;
/// searchBar
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) BMKMapView *mapView; //当前界面的mapView
@property (nonatomic, strong) BMKLocationManager *locationManager; //定位对象
@property (nonatomic, strong) BMKUserLocation *userLocation; //当前位置对象

/// gmsMapView
@property (nonatomic, strong) GMSMapView *gmsMapView;
/// location
@property (nonatomic, strong) CLLocation *location;
/// firstLocationUpdate
@property (nonatomic) BOOL firstLocationUpdate;

/// isBMK
@property (nonatomic) BOOL isBMK;

@end

@implementation MapViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    //当mapView即将被显示的时候调用，恢复之前存储的mapView状态
    [self.mapView viewWillAppear];
    
//    self.searchBar.text = self.search.searchBar.text;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:NO];
    //当mapView即将被隐藏的时候调用，存储当前mapView的状态
    [self.mapView viewWillDisappear];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationItem.title = @"导航";
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navBackGround"] forBarMetrics:UIBarMetricsDefault];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
//    self.navigationController.navigationBar.topItem.title = @"";
    
    // Do any additional setup after loading the view from its nib.
    
    // 开始定位
    self.isBMK = YES;
    //开启定位服务
    [self.locationManager startUpdatingLocation];
    
    
    [self setBaseView];
    
}

- (void)setBaseView {
    
    self.search = [MapSearchViewController new];
    // 搜索框
    [self setSearchBar];
    // 搜索按钮
    self.searchBtn = [[UIButton alloc] init];
    [self.searchBtn setImage:[UIImage imageNamed:@"searchBtn"] forState:UIControlStateNormal];
    [self.searchBtn addTarget:self action:@selector(searchBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchBtn];
    // 定位按钮
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"location"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    CGFloat barH = 45;
    CGFloat btnWH = 40;
    
    
    // 布局
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(5);
        make.bottom.offset(-barH * 2);
        make.height.equalTo(@(barH));
        make.right.equalTo(self.searchBtn.mas_left);
    }];
    
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.searchBtn.mas_height);
        make.bottom.height.equalTo(self.searchBar);
        make.right.offset(-5);
    }];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@(btnWH));
        make.right.offset(-5);
        make.bottom.offset(-barH * 5);
    }];
    
}

- (void)setSearchBar {
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"请输入您查找的地址";
    self.searchBar.backgroundImage = [UIImage new];
    self.searchBar.delegate = self;

    [self.view addSubview:self.searchBar];
    
}

- (void)searchBtnClick {
    [self.searchBar becomeFirstResponder];
}

- (void)btnClick {

    if (self.isBMK) {
        [self.mapView setCenterCoordinate:self.userLocation.location.coordinate animated:YES];
        
    } else {
        self.gmsMapView.camera = [GMSCameraPosition cameraWithTarget:self.location.coordinate
                                                            zoom:14];
    }
    
}

- (void)backClick {
    [self.navigationController popViewControllerAnimated:YES];
    self.navigationController.navigationBarHidden = YES;
}

// MARK: - uisearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.navigationController pushViewController:self.search animated:NO];
    [searchBar endEditing:YES];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - BMKLocationManagerDelegate
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didFailWithError:(NSError * _Nullable)error {
    NSLog(@"定位失败");
    
}
- (void)BMKLocationManager:(BMKLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    if (!heading) {
        return;
    }
    NSLog(@"用户方向更新");
    
    self.userLocation.heading = heading;
    [_mapView updateLocationData:self.userLocation];
}

- (void)BMKLocationManager:(BMKLocationManager *)manager didUpdateLocation:(BMKLocation *)location orError:(NSError *)error {
    if (error) {
        NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
    }
    if (!location) {
        return;
    }
    
    self.userLocation.location = location.location;
    
    self.isBMK = [BMKLocationManager BMKLocationDataAvailableForCoordinate:self.userLocation.location.coordinate withCoorType:BMKLocationCoordinateTypeBMK09LL];
    self.search.isBMK = self.isBMK;
    // 判断是否在国内
    if (self.isBMK) {
        
        if (_gmsMapView) {
            [self.gmsMapView removeFromSuperview];
        }
        //将mapView添加到当前视图中
        [self.view insertSubview:self.mapView belowSubview:self.searchBar];
        
        [self.locationManager startUpdatingHeading];
        
        //实现该方法，否则定位图标不出现
        [self.mapView updateLocationData:self.userLocation];
        
        self.search.city = location.rgcData.city;
        self.search.location = location.location.coordinate;
        
    } else {
        
        [self.locationManager stopUpdatingLocation];
        if (_mapView) {
            [self.mapView removeFromSuperview];
        }
        [self.view insertSubview:self.gmsMapView belowSubview:self.searchBar];
    }
    
}
#pragma mark - Lazy loading
- (BMKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[BMKMapView alloc] initWithFrame:self.view.bounds];
        //设置定位模式为定位跟随模式
        _mapView.userTrackingMode = BMKUserTrackingModeFollow;
        //显示定位图层
        _mapView.showsUserLocation = YES;
        //设置mapView的代理
        _mapView.delegate = self;
        
        
    }
    return _mapView;
}
- (BMKLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[BMKLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.allowsBackgroundLocationUpdates = NO;
        _locationManager.locationTimeout = 10;
    }
    return _locationManager;
}

- (BMKUserLocation *)userLocation {
    if (!_userLocation) {
        _userLocation = [[BMKUserLocation alloc] init];
    }
    return _userLocation;
}

/// 懒加载
- (GMSMapView *)gmsMapView
{
    if(!_gmsMapView)
    {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                                longitude:151.2086
                                                                     zoom:12];
        
        _gmsMapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
        _gmsMapView.delegate = self;
        _gmsMapView.settings.compassButton = YES;
//        _gmsMapView.settings.myLocationButton = YES;
        
        
        // Listen to the myLocation property of GMSMapView.
        [_gmsMapView addObserver:self
                   forKeyPath:@"myLocation"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        
        // Ask for My Location data after the map has already been added to the UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            _gmsMapView.myLocationEnabled = YES;
        });
    }
    return _gmsMapView;
}


- (void)dealloc {
    
    if (!self.isBMK) {
        [self.gmsMapView removeObserver:self
                             forKeyPath:@"myLocation"
                                context:NULL];
    }
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!_firstLocationUpdate) {
        // If the first location update has not yet been received, then jump to that
        // location.
        _firstLocationUpdate = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        _gmsMapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:14];
        self.search.location = location.coordinate;
        self.location = location;
    }
}

@end
