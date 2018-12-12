//
//  MapSearchViewController.m
//  ILiveLocation
//
//  Created by CF on 2018/9/9.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "MapSearchViewController.h"
#import "UIView+Frame.h"
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import <Masonry.h>
#import <GooglePlaces/GooglePlaces.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MapSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, BMKSuggestionSearchDelegate, BMKMapViewDelegate, BMKPoiSearchDelegate, GMSMapViewDelegate>
/// data
@property (nonatomic, strong) NSMutableArray *data;

/// search
@property (nonatomic, strong) BMKSuggestionSearch *search;
/// poi
@property (nonatomic, strong) BMKPoiSearch *poi;

@property (nonatomic, strong) BMKMapView *mapView; //当前界面的mapView


/// gmsMapView
@property (nonatomic, strong) GMSMapView *gmsMapView;

@end

static NSString *kCell = @"cell";

@implementation MapSearchViewController

- (instancetype)init {
    
    if (self = [super init]) {
        _isBMK = YES;
        _city = @"北京";
        _location = CLLocationCoordinate2DMake(39.90868, 116.3956);
        [self setSearchBar];
    }
    return self;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.searchBar endEditing:YES];
    
    //当mapView即将被隐藏的时候调用，存储当前mapView的状态
    [_mapView viewWillDisappear];
}

- (void)viewWillAppear:(BOOL)animated {
    //当mapView即将被显示的时候调用，恢复之前存储的mapView状态
    [_mapView viewWillAppear];
    [self.searchBar becomeFirstResponder];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.titleView = self.searchBar;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    
    // Do any additional setup after loading the view from its nib.
    
    
    [self createMapView];
    
    
    
    CGSize size = self.view.frame.size;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.tableView.rowHeight = 50;
//    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCell];
    
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.equalTo(self.view);
    }];
    
    
}


- (void)createMapView {
    
    
    if (self.isBMK) {
        //将mapView添加到当前视图中
        [self.view addSubview:self.mapView];
        self.poi = [BMKPoiSearch new];
        self.poi.delegate = self;
        
        self.search = [BMKSuggestionSearch new];
        self.search.delegate = self;
        
    } else {
        [self.view addSubview:self.gmsMapView];
    }
    
    
}


- (void)setSearchBar {
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"请输入您查找的地址";
    self.searchBar.backgroundImage = [UIImage new];
    self.searchBar.delegate = self;
    
}

- (void)backClick {
    
    self.searchBar.text = @"";
    [self.data removeAllObjects];
    [self.tableView reloadData];
    [self layoutTbisFullScreen:YES];
    [self.navigationController popViewControllerAnimated:NO];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section  {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCell];
    }
    cell.imageView.image = [UIImage imageNamed:@"historyLocation"];
    
    cell.textLabel.text = [self getTitle:indexPath];
    cell.detailTextLabel.text = [self getDetailTitle:indexPath];
    
    
    if (!cell.accessoryView) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"showSearchLoc"] forState:UIControlStateNormal];
        [btn sizeToFit];
        [btn addTarget:self action:@selector(openNav:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = btn;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.searchBar.isFirstResponder) {
        
        NSString *name = [self getTitle:indexPath];
        [self searchAddress:name];
        self.searchBar.text = name;
        [self.searchBar endEditing:YES];
        
        [self layoutTbisFullScreen:NO];
        
    } else {
        
        
        [self insertAnnotation:indexPath];
        
        
    }
    
}
// MARK: - 布局

- (void)layoutTbisFullScreen:(BOOL)isFullScreen {
    
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        if (isFullScreen) {
            make.top.bottom.left.right.equalTo(self.view);
        } else {
            make.top.equalTo(self.isBMK ? self.mapView.mas_bottom : self.gmsMapView.mas_bottom);
            make.bottom.left.right.equalTo(self.view);
        }
        
    }];
    
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.tableView layoutIfNeeded];
    }];
    
}

// MARK: - 导航

- (void)openNav:(UIButton *)btn {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)btn.superview];
    
    if (self.isBMK) {
        [self openBaiduNav:indexPath];
        
    } else {
        [self openGMSNav:indexPath];
    }
    
}

- (void)openGMSNav:(NSIndexPath *)indexPath {
    
    GMSAutocompletePrediction* result = self.data[indexPath.row];
    [GMSPlacesClient.sharedClient lookUpPlaceID:result.placeID callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
        
        NSString *str = [NSString stringWithFormat:@"comgooglemaps://?daddr=%f,%f&directionsmode=driving&zoom=17",result.coordinate.latitude,result.coordinate.longitude];
        if ([[UIApplication sharedApplication] canOpenURL:
             [NSURL URLWithString:@"comgooglemaps://"]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str] options:@{} completionHandler:nil];
        }
        
        
    }];
 
    
}


- (void)openBaiduNav:(NSIndexPath *)indexPath {
    
    //初始化调起百度地图驾车路线参数类
    BMKOpenDrivingRouteOption *option = [[BMKOpenDrivingRouteOption alloc] init];
    //指定返回自定义scheme
    option.appScheme = @"baidumapsdk://mapsdk.baidu.com";
    //调起百度地图客户端失败后，是否支持调起web地图，默认：YES
    option.isSupportWeb = YES;
    //实例化线路检索节点信息类对象
    BMKPlanNode *start = [[BMKPlanNode alloc]init];
    //指定起点经纬度
    start.pt = self.location;
    //指定起点名称
    start.name = @"我的位置";
    //所在城市
    //    start.cityName = @"北京";
    //指定起点
    option.startPoint = start;
    //实例化线路检索节点信息类对象
    BMKPlanNode *end = [[BMKPlanNode alloc]init];
    //终点坐标
    end.pt = [self getCoordinate:indexPath];
    //指定终点名称
    end.name = [self getTitle:indexPath];
    //城市名
    end.cityName = @" ";
    //终点节点
    option.endPoint = end;
    
    [BMKOpenRoute openBaiduMapDrivingRoute:option];
    
}

// MARK: - 位置


- (void)insertAnnotation:(NSIndexPath *)indexPath {
    
    if (self.isBMK) {
        
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        //初始化标注类BMKPointAnnotation的实例
        BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc]init];
        //设置标注的经纬度坐标
        annotation.coordinate = [self getCoordinate:indexPath];
        //设置标注的标题
        annotation.title = [self getTitle:indexPath];
        //将一组标注添加到当前地图View中
        [_mapView addAnnotation:annotation];
        //设置当前地图的中心点
        _mapView.centerCoordinate = annotation.coordinate;
        
    } else {
        
        [self.gmsMapView clear];
        
        GMSAutocompletePrediction* result = self.data[indexPath.row];
        [GMSPlacesClient.sharedClient lookUpPlaceID:result.placeID callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
            
            [self insertMarker:result];
            
        }];
        
    }
    
    
    
}

- (void)insertMarker:(GMSPlace *)place {
    if (!place) return;
    [self.gmsMapView clear];
    GMSMarker *marker = [GMSMarker markerWithPosition:place.coordinate];
    marker.title = place.name;
    marker.map = self.gmsMapView;
    GMSCameraPosition *sydney = [GMSCameraPosition cameraWithLatitude:place.coordinate.latitude
                                                            longitude:place.coordinate.longitude
                                                                 zoom:10];
    self.gmsMapView.camera = sydney;
}



- (NSString *)getTitle:(NSIndexPath *)indexPath {
    
    id info = self.data[indexPath.row];
    if ([info isKindOfClass:BMKSuggestionInfo.class]) {
        return ((BMKSuggestionInfo *)info).key;
    } else if ([info isKindOfClass:BMKPoiInfo.class]) {
        return ((BMKPoiInfo *)info).name;
    } else if ([info isKindOfClass:GMSAutocompletePrediction.class]) {
        return ((GMSAutocompletePrediction *)info).attributedPrimaryText.string;
    }
    return @"";
}

- (NSString *)getDetailTitle:(NSIndexPath *)indexPath {
    
    id info = self.data[indexPath.row];
    if ([info isKindOfClass:BMKSuggestionInfo.class]) {
        return ((BMKSuggestionInfo *)info).address;
        
    } else if ([info isKindOfClass:GMSAutocompletePrediction.class]) {
        if (self.searchBar.isFirstResponder) {
            return @"";
            
        } else {
            return ((GMSAutocompletePrediction *)info).attributedFullText.string;
        }
    }
    return @"";

}

- (CLLocationCoordinate2D)getCoordinate:(NSIndexPath *)indexPath {
    
    id info = self.data[indexPath.row];
    if ([info isKindOfClass:BMKSuggestionInfo.class]) {
        return ((BMKSuggestionInfo *)info).location;
    } else {
        return ((BMKPoiInfo *)info).pt;
    }
}

// MARK: - search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    [self suggesAddress:searchText];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
    [self suggesAddress:searchBar.text];
    
    [self layoutTbisFullScreen:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"searchButton");
    [self searchAddress:searchBar.text];
    [searchBar endEditing:YES];
    
    [self layoutTbisFullScreen:NO];
    
}

// MARK: - google

- (void)placeAutocomplete:(NSString *)text insertAn:(BOOL)insertAn {
    
    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterNoFilter;
    
    [GMSPlacesClient.sharedClient autocompleteQuery:text
                              bounds:nil
                              filter:filter
                            callback:^(NSArray *results, NSError *error) {
                                if (error != nil) {
                                    NSLog(@"Autocomplete error %@", [error localizedDescription]);
                                    return;
                                }
                                
                                for (GMSAutocompletePrediction* result in results) {
                                    NSLog(@"Result '%@' with placeID %@", result.attributedFullText.string, result.placeID);
                                }
                                
                                if (insertAn) {
                                    GMSAutocompletePrediction* result = results[0];
                                    [GMSPlacesClient.sharedClient lookUpPlaceID:result.placeID callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
                                        
                                        [self insertMarker:result];
                                        
                                    }];
                                    
                                }
                                
                                
                                self.data = (NSMutableArray *)results;
                                [self.tableView reloadData];
                                
                            }];
}


// MARK: - 百度

- (void)onGetSuggestionResult:(BMKSuggestionSearch *)searcher result:(BMKSuggestionSearchResult *)result errorCode:(BMKSearchErrorCode)error {

    self.data = [result.suggestionList mutableCopy];
    [self.tableView reloadData];
}

- (void)suggesAddress:(NSString *)address {
    
    
    if (self.isBMK) {
        BMKSuggestionSearchOption *option = [BMKSuggestionSearchOption new];
        option.cityname = self.city;
        option.keyword = address;
        BOOL flag = [self.search suggestionSearch:option];
        if(flag) {
            NSLog(@"关键词检索成功");
        } else {
            NSLog(@"关键词检索失败");
        }
        
    } else {
        
        [self placeAutocomplete:address insertAn:NO];
        
    }
    
}

- (void)searchAddress:(NSString *)address {
    
    if (self.isBMK) {
        
        BMKPOICitySearchOption *cityOption = [[BMKPOICitySearchOption alloc]init];
        //检索关键字，必选。举例：天安门
        cityOption.keyword = address;
        //区域名称(市或区的名字，如北京市，海淀区)，最长不超过25个字符，必选
        cityOption.city = self.city;
        
        BOOL flag = [self.poi poiSearchInCity:cityOption];
        if(flag) {
            NSLog(@"POI城市内检索成功");
        } else {
            NSLog(@"POI城市内检索失败");
        }

    } else {
    
        [self placeAutocomplete:address insertAn:YES];
        
    }
    
    
}

- (void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPOISearchResult *)poiResult errorCode:(BMKSearchErrorCode)error {
    /**
     移除一组标注
     
     @param annotations 要移除的标注数组
     */
    [_mapView removeAnnotations:_mapView.annotations];
    //BMKSearchErrorCode错误码，BMK_SEARCH_NO_ERROR：检索结果正常返回
    if (error == BMK_SEARCH_NO_ERROR) {
        //POI信息类的实例
        BMKPoiInfo *POIInfo = poiResult.poiInfoList[0];
        //初始化标注类BMKPointAnnotation的实例
        BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc]init];
        //设置标注的经纬度坐标
        annotation.coordinate = POIInfo.pt;
        //设置标注的标题
        annotation.title = POIInfo.name;
        //将一组标注添加到当前地图View中
        [_mapView addAnnotation:annotation];
        //设置当前地图的中心点
        _mapView.centerCoordinate = annotation.coordinate;
    }
    
    self.data = [poiResult.poiInfoList mutableCopy];
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//MARK: - 懒加载

- (BMKMapView *)mapView {
    if (!_mapView) {
        CGSize size = self.view.frame.size;
        _mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height * 2.0 / 5.0)];
        //设置mapView的代理
        _mapView.delegate = self;
    }
    return _mapView;
}

- (GMSMapView *)gmsMapView
{
    if(!_gmsMapView)
    {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                                longitude:151.2086
                                                                     zoom:12];
        CGSize size = self.view.frame.size;
        _gmsMapView = [GMSMapView mapWithFrame:CGRectMake(0, 0, size.width, size.height * 2.0 / 5.0) camera:camera];
        _gmsMapView.delegate = self;

    }
    return _gmsMapView;
}



- (NSMutableArray *)data
{
    if(!_data)
    {
        NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:@"history"];
        if (!array) {
            array  = [NSArray new];
        }
        _data = [array mutableCopy];
    }
    return _data;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
