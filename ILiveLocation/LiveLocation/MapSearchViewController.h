//
//  MapSearchViewController.h
//  ILiveLocation
//
//  Created by CF on 2018/9/9.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapSearchViewController : UIViewController
/// city
@property (nonatomic, copy) NSString *city;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;

@end
