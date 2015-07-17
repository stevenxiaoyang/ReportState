//
//  LocationViewController.m
//  MyFamily
//
//  Created by 陆洋 on 15/7/14.
//  Copyright (c) 2015年 maili. All rights reserved.
//只需要传经纬度给服务器，服务器传附近的地点

#import "LocationViewController.h"
#import <CoreLocation/CoreLocation.h>
@interface LocationViewController ()<CLLocationManagerDelegate>
@property (strong,nonatomic)CLLocationManager *locationManager;
@property (strong,nonatomic)CLLocation *checkInLocation;
@property (strong,nonatomic)NSString *currentLatitude; //纬度
@property (strong,nonatomic)NSString *currentLongitude; //经度
@property (strong,nonatomic)CLGeocoder *geocoder;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"所在位置";
    
    //nav右边发布按钮
    UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    reportButton.frame = CGRectMake(0, 0, 30, 20);
    [reportButton setTitle:@"发布" forState:normal];
    [reportButton addTarget:self action:@selector(reportState:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *reportButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reportButton];
    self.navigationItem.rightBarButtonItem = reportButtonItem;
    
    //定位管理器
    _locationManager=[[CLLocationManager alloc]init];
    
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"定位服务当前可能尚未打开，请设置打开！");
        return;
    }
    
    //如果没有授权则请求用户授权
    if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined){
        [_locationManager requestWhenInUseAuthorization];
    }else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedWhenInUse){
        //设置代理
        _locationManager.delegate=self;
        //设置定位精度
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        //定位频率,每隔多少米定位一次
        CLLocationDistance distance=10.0;//十米定位一次
        _locationManager.distanceFilter=distance;
        //启动跟踪定位
        [_locationManager startUpdatingLocation];
    }
}

-(CLGeocoder *)geocoder
{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc]init];
    }
    return _geocoder;
}

#pragma mark 根据坐标(经纬度)取得地名
-(void)getAddressByLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude{
    //反地理编码
    CLLocation *location=[[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark=[placemarks firstObject];
        NSLog(@"详细信息:%@",placemark.addressDictionary);
    }];
}

#pragma mark - 发布状态
-(void)reportState:(id)sender
{
    
}

#pragma mark - locationManager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.checkInLocation = [locations lastObject];
    CLLocationCoordinate2D cool = self.checkInLocation.coordinate;
    self.currentLatitude  = [NSString stringWithFormat:@"%.4f",cool.latitude];
    self.currentLongitude = [NSString stringWithFormat:@"%.4f",cool.longitude];
    
    NSLog(@"%@,%@",self.currentLatitude,self.currentLongitude);
    [self getAddressByLatitude:[self.currentLatitude doubleValue] longitude:[self.currentLongitude doubleValue]];
    //如果不需要实时定位，使用完即使关闭定位服务
    [self.locationManager stopUpdatingLocation];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
