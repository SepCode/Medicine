//
//  MapSearchViewController.h
//  ILiveLocation
//
//  Created by CF on 2018/9/9.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapSearchViewController : UIViewController
/// city
@property (nonatomic, copy) NSString *city;
/// location
@property (nonatomic) CLLocationCoordinate2D location;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;

/// isBMK
@property (nonatomic) BOOL isBMK;

@end
