//
//  YKSAddAddressVC.m
//  YueKangSong
//
//  Created by gongliang on 15/5/17.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSAddAddressVC.h"
#import "GZBaseRequest.h"
#import "YKSAddressTextField.h"
#import "YKSAreaManager.h"
#import "YKSSearchView.h"
#import "YKSSearchStreetVC.h"
#import "YKSCityViewController.h"
#import "YKSAddressListViewController.h"
#import "YKSUserModel.h"
#import "YKSMyAddressViewcontroller.h"
#import "YKSSelectAddressView.h"
#import <INTULocationManager.h>

@interface YKSAddAddressVC () <UITextFieldDelegate, UIGestureRecognizerDelegate,UIAlertViewDelegate>

@property(strong,nonatomic) NSDictionary *currentDic;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;

//所在城市
@property (weak, nonatomic) IBOutlet UILabel *City_Name;


//收货地址
@property (weak, nonatomic) IBOutlet UITextField *streetField; //街道
//门牌号
@property (weak, nonatomic) IBOutlet UITextField *detailAddressField; //收货地址


@property (strong, nonatomic) NSDictionary *areaInfo;
//删除地址
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) YKSSearchView *searchView;
@property (weak, nonatomic) IBOutlet UITableViewCell *cell;
@property (strong, nonatomic) NSString *lastSearchKey;
@property (strong, nonatomic) NSDictionary *streetDic;

@property (assign, nonatomic) BOOL isCreat;

@property (strong, nonatomic) NSDictionary *info;

@property(nonatomic,copy)NSString *fflag;

@property(nonatomic,strong)NSDictionary *dic;
@end

@implementation YKSAddAddressVC


-(void)viewDidDisappear:(BOOL)animated{

    [super viewDidDisappear:animated];
    
     [[NSNotificationCenter defaultCenter] postNotificationName:@"selectAddressVCRelodData" object:nil];
    
}

    
- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    NSDictionary *ddic=[YKSUserModel shareInstance].currentSelectAddress;
    
    if ([_addressInfo isEqualToDictionary:ddic]) {
        
        self.fflag=@"1";
        
    }
    
    //获取到当前定位到的地址
    NSDictionary *locationDic = [UIViewController selectedMyLocation];
    
    _City_Name.font=[UIFont systemFontOfSize:14];

    _phoneField.text=[YKSUserModel telePhone];
    _City_Name.text=[UIViewController selectedCityUnArchiver][@"city"];
    
    //新建收货地址街道显示当前定位的地址
    _streetField.text = locationDic[@"pois"][0][@"name"];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(gotoSearchAddress)];
    _streetField.enabled = NO;
    [_streetField.superview addGestureRecognizer:tap];
    _detailAddressField.placeholder = @"楼层，门牌号";
    
    [_streetField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    if (!_addressInfo) {
        self.tableView.tableFooterView = nil;
    } else {
        self.tableView.tableFooterView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 80);
        _nameField.text = _addressInfo[@"express_username"];
        _phoneField.text = _addressInfo[@"express_mobilephone"];
        _streetField.text = _addressInfo[@"community"];
        _detailAddressField.text = _addressInfo[@"express_detail_address"];
        _City_Name.text=_addressInfo[@"city_name"];
        
    }
    
    //判断所填写的地址是不是当前定位的地址
    if (_isCurrentLocation) {

        if (![UIViewController selectedMyLocation]) {
            
            [self startSingleLocationRequest];
            
        }
        
         NSDictionary *dic=[UIViewController selectedMyLocation];
        
        self.tableView.tableFooterView = nil;
        _nameField.text = @"";
        _phoneField.text = [YKSUserModel telePhone];
       _streetField.text = dic[@"pois"][0][@"name"];
        _City_Name.text=dic[@"addressComponent"][@"city"];
        
        self.streetDic=[UIViewController selectedMyLocation];
        
        self.streetDictionary=[UIViewController selectedMyLocation];
        
    }
    
    
    [YKSAreaManager getBeijingAreaInfo:^(NSDictionary *areaInfo) {
        NSArray *datas = areaInfo[@"county"][[areaInfo[@"city"] firstObject][@"code"]];
        //_addressField.datas = datas;
        _areaInfo = areaInfo;
        if (_addressInfo) {
            //里面的分区
            if (_addressInfo[@"district"]) {
                //_addressField.text = _addressInfo[@"district"];
                _nameField.text = @"";
            }
            //数组里面遍历出来的县城
            [datas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (_addressInfo[@"county"] ) {
                    if ([obj[@"code"] integerValue] == [_addressInfo[@"county"] integerValue]) {
                        //_addressField.text = obj[@"name"];
                        *stop = YES;
                    }
                }
                if (_isCurrentLocation){
                    if ([_addressInfo[@"district"] isEqualToString:obj[@"name"]]) {
                        _addressInfo[@"county"] = obj[@"code"];
                    }
                }
                
            }];
        }
    }];
    
    
    if (self.streetDictionary&&self.cityName) {
        
        _City_Name.text=self.cityName;
        _streetDic = self.streetDictionary;
        _streetField.text = _streetDic[@"name"];
        _detailAddressField.text=@"";
        
    }
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.tableView endEditing:YES];
    [self.superclass endEditing:YES];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [_nameField endEditing:YES];
    [_phoneField endEditing:YES];
    [_streetField endEditing:YES ];
    [_detailAddressField endEditing:YES];
    [self.tableView endEditing:YES];
}



/**
 *  获取ios设备当前位置（GPS 定位）
 */
- (void)startSingleLocationRequest {
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyNeighborhood
                                       timeout:10.0f
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             
                                             NSString *latLongString = [[NSString alloc] initWithFormat:@"%f,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
                                             
                                             //设置用户数据模型的经纬度赋值
//                                             if ([YKSUserModel shareInstance].lat == 0) {
                                                 [YKSUserModel shareInstance].lat = currentLocation.coordinate.latitude;
                                                 [YKSUserModel shareInstance].lng = currentLocation.coordinate.longitude;
//                                             }
                                             
                                             
                                             //把当前位置(经纬度)传给服务器
                                             if ([YKSUserModel isLogin]) {
                                                 [GZBaseRequest locationUploadLat:currentLocation.coordinate.latitude
                                                                              lng:currentLocation.coordinate.longitude
                                                                         callback:^(id responseObject, NSError *error) {
                                                                             
                                                                         }];
                                             }
                                             
              [[GZHTTPClient shareClient] GET:BaiduMapGeocoderApi
                                          parameters:@{
                                                       @"location": latLongString,
                                                       @"coordtype": @"wgs84ll",
                                                       @"ak": BaiduMapAK,
                                                       @"output": @"json",
                                                       @"pois":@(1)
                                                                               }
                                               
                                              
                success:^(NSURLSessionDataTask *task, id responseObject) {
                                                                         
        if (responseObject && [responseObject[@"status"] integerValue] == 0) {
         NSDictionary *dic = responseObject[@"result"];
          _dic = responseObject[@"result"];
          [UIViewController selectedCityArchiver:dic[@"addressComponent"]];
           [UIViewController setMyLocation:dic];
                                                                             
//             _streetDic=_dic;
            
//          _streetField.text =  _dic[@"addressComponent"][@"street"];
            _streetField.text =  _dic[@"pois"][0][@"name"];
            _detailAddressField.text =@"";
                                                                             
              _City_Name.text=_dic[@"addressComponent"][@"city"];

                                                                             
                                                                         }
                                                                     }
                                                                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                                         NSLog(@"error = %@", error);
                                                                     }];
                                         }];
}



- (IBAction)dingWei:(id)sender {
    
    [self startSingleLocationRequest];
    
}

#pragma mark -
- (void)gotoSearchAddress {
    [self performSegueWithIdentifier:@"gotoYKSSearchStreetVC" sender:nil];
}


-(void)textFieldChange:(UITextField *)textField
{
    if (textField == _nameField) {
        if (textField.text.length > 6) {
            textField.text = [textField.text substringToIndex:6];
        }
    }
}
#pragma mark - IBOutlets
- (IBAction)confirm:(id)sender {
    
    [self.view endEditing:YES];
    
    if (IS_EMPTY_STRING(_nameField.text)) {
        [self showToastMessage:@"请填写收货人"];
        
        return ;
    }
    NSString *name=[YKSTools nameFormatter:_nameField.text];
    _nameField.text=name;
    
    if ([name isEqualToString:@""]) {
        [self showToastMessage:@"收货人格式不允许是数字，请重新输入"];
        return;
    }
    [self textFieldChange:_nameField];
   // 这样就可以更好地限制输入长度：
    

    if (IS_EMPTY_STRING(_phoneField.text)) {
        [self showToastMessage:@"请填写手机号"];
        return;
    }
    if (![YKSTools mobilePhoneFormatter:_phoneField.text]) {
        [self showToastMessage:@"手机格式不正确"];
        return;
    }
    //    if (IS_EMPTY_STRING(_addressField.text)) {
    //        [self showToastMessage:@"请选择地区"];
    //        return ;
    //    }
    if (IS_EMPTY_STRING(_City_Name.text)) {
        [self showToastMessage:@"请填写城市"];
    }
    
    if (IS_EMPTY_STRING(_streetField.text)) {
        [self showToastMessage:@"请填写写字楼，小区，学校等地址"];
        return;
    }
    
    NSString *detail=[YKSTools detailAddress:_detailAddressField.text];
    _detailAddressField.text=detail;
    if (IS_EMPTY_STRING(_detailAddressField.text)) {
        [self showToastMessage:@"请填写详细地址"];
        return;
    }
    
    NSString *areaCode = [NSString stringWithFormat:@"%@,%@,%@", _areaInfo[@"province"][@"code"], [_areaInfo[@"city"] firstObject][@"code"], @"110105"];
    NSString *latLng = [NSString stringWithFormat:@"%@,%@", _streetDic[@"location"][@"lat"], _streetDic[@"location"][@"lng"]];
    NSString *detailAddress = [NSString stringWithFormat:@"%@",  _detailAddressField.text];
    NSString *city_name=[NSString stringWithFormat:@"%@",_City_Name.text];
    //_streetDic[@"address"], _streetDic[@"name"],
    NSLog(@"%@aaaa%@",_streetDic,_detailAddressField.text);
    
    
   
    
    
    if (!_addressInfo || _isCurrentLocation) {
        
        [GZBaseRequest addAddressExpressArea:areaCode
                                   community:_streetField.text
                             communityLatLng:latLng
                               detailAddress:detailAddress
                                    contacts:_nameField.text
                                   telePhone:_phoneField.text
                                    cityName:city_name
                                    callback:^(id responseObject, NSError *error) {
                                        
                                        
                                        [self hideProgress];
                                        if (error) {
                                            
                                            [self showToastMessage:@"网络加载失败"];
                                            return ;
                                        }
                                        if (ServerSuccess(responseObject)) {
                                            
                                            if ([responseObject[@"data"][@"sendable"] boolValue]) {
                                                
                                                [YKSUserModel shareInstance].addressID = responseObject[@"data"][@"addressid"];
                                                NSArray *array = [latLng componentsSeparatedByString:@","];
                                                [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                                                [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                                                //网络获取地址列表
                                                [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
                                                    
                                                    if (responseObject) {
                                                        NSArray *dataArr = responseObject[@"data"][@"addresslist"];
                                                        
                                                        for (NSDictionary *dataDic in dataArr) {
                                                            
                                                            
                                                            
                                                            //判断，地址id
                                                            if ([dataDic[@"id"] isEqualToString:[YKSUserModel shareInstance].addressID]) {
                                                                
                                                                if (![dataDic[@"didinfo"][@"id"] isEqualToString:[YKSUserModel shareInstance].currentSelectAddress[@"didinfo"][@"id"]]) {
                                                                    //清空购物车
                                                                    [GZBaseRequest restartShoppingCartBygids:nil callback:^(id responseObject, NSError *error) {
                                                                        
                                                                        if (ServerSuccess(responseObject))
                                                                        {
                                                                            
                                                                        }
                                                                    }];
                                                                    
                                                                }
                                                                [YKSUserModel shareInstance].currentSelectAddress = dataDic;
                                                                //这里就是了,拿到地址,删除旧地址
                                                                
                                                                [UIViewController deleteFile];
                                                                [UIViewController selectedAddressArchiver:dataDic];
                                                                
                                                            }
                                                        }
                                                        [self.navigationController popToRootViewControllerAnimated:YES];
                                                        
                                                    }
                                                }];
                                                
                                                
                                                
                                            }
                                            else{
                                                [self.navigationController showToastMessage:@"添加成功，但此地区暂不支持配送"];
                                            }
                                            
                                            
                                            
                                            if (_callback) {
                                                _callback();
                                            }
                                            //                                            UIStoryboard *storyBD=[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                                            //                                            YKSAddressListViewController *list=[storyBD instantiateViewControllerWithIdentifier:@"YKSAddressListViewController"];
                                            
                                            
                                            
                                            //                                            [self.navigationController pushViewController:list animated:YES];
//                                            if ([self.flag isEqualToString:@"2"]) {
//                                                
//                                                [self.navigationController popViewControllerAnimated:YES];
//                                                return;
//                                                
//                                            }
//                                            
//                                            
//                                            [self showAddressView];
                                            
                                            //                                            [self.navigationController popViewControllerAnimated:YES];
                                            NSLog(@"添加成功收货地址 = %@", responseObject);
                                        } else {
                                            [self showToastMessage:responseObject[@"msg"]];
                                        }
                                    }];
    } else {
        
        //判断用户是否修改收货地址，与传过来的地址匹配
        if ([_nameField.text isEqualToString:_addressInfo[@"express_username"]] && [_phoneField.text isEqualToString:_addressInfo[@"express_mobilephone"]] && [_streetField.text isEqualToString:_addressInfo[@"community"]] && [_detailAddressField.text isEqualToString:_addressInfo[@"express_detail_address"]] && [_City_Name.text isEqualToString:_addressInfo[@"city_name"]]) {
            //用户没有修改收货地址，直接返回到上一页
            [self.navigationController popViewControllerAnimated:YES];
        }else
        {
            YKSSelectAddressView *selectAddressView = nil;
            //修改地址
            [GZBaseRequest editAddressById:_addressInfo[@"id"]
                               expressArea:areaCode
                                 community:_streetField.text
                           communityLatLng:latLng
                             detailAddress:detailAddress
                                  contacts:_nameField.text
                                 telePhone:_phoneField.text
                                  cityName:_City_Name.text
                                  callback:^(id responseObject, NSError *error) {
                                      [self hideProgress];
                                      if (error) {
                                          [self showToastMessage:@"网络加载失败"];
                                          return ;
                                      }
                                      if (ServerSuccess(responseObject)) {
                                          //                                      [self.navigationController showToastMessage:@"更新成功"];
                                          //用户修改地址成功，弹出保存成功
                                          [self showToastMessage:@"保存成功"];
                                          
                                          
                                          if ([[YKSUserModel shareInstance].currentSelectAddress[@"community_lat_lng"] isEqualToString:_addressInfo[@"community_lat_lng"]]) {
                                          
                                          //获取列表
                                          [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
                                              if (error) {
                                                  [self showToastMessage:@"网络加载失败"];
                                                  return ;
                                              }
                                              if (ServerSuccess(responseObject)) {
                                                  NSArray *dataArr = responseObject[@"data"][@"addresslist"];
                                                  for (_currentDic in dataArr) {
                                                      if ([_currentDic[@"id"] isEqualToString:_addressInfo[@"id"]]) {
                                                          
                                                          NSArray *array = [_currentDic[@"community_lat_lng"] componentsSeparatedByString:@","];
                                                          [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                                                          [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                                                          
                        
                                                          if (![_currentDic[@"didinfo"][@"name"] isEqualToString:[YKSUserModel shareInstance].currentSelectAddress[@"didinfo"][@"name"]]) {
                                                              //清空购物车
                                                              [GZBaseRequest restartShoppingCartBygids:nil callback:^(id responseObject, NSError *error) {
                                                                  
                                                                  if (ServerSuccess(responseObject))
                                                                  {
                                                                      
                                                                  }
                                                              }];
                                                              
                                                          }

                                            
                                                          
                                                          [YKSUserModel shareInstance].currentSelectAddress = _currentDic;
                                                          //这里就是了,拿到地址,删除旧地址
                                                          
                                                          [UIViewController deleteFile];
                                                          [UIViewController selectedAddressArchiver:_currentDic];
                                                          
                                                          
                                                          //    [selectAddressView reloadData];
                                                          selectAddressView.removeViewCallBack = ^{
                                                              
                                                          };
                                                          [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
                                                              if (ServerSuccess(responseObject)) {
                                                                  NSDictionary *dic = responseObject[@"data"];
                                                                  if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                                                                      selectAddressView.datas = [dic[@"addresslist"] mutableCopy];
                                                                      [YKSUserModel shareInstance].addressLists = selectAddressView.datas;
                                                                      if (!selectAddressView.datas) {
                                                                          selectAddressView.datas = [NSMutableArray array];
                                                                      }
                                                                      [selectAddressView.datas insertObject:[self currentAddressInfo] atIndex:0];
                                                                      [selectAddressView reloadData];
                                                                  }
                                                              }
                                                          }];
                                                          
                                                          //产品详情选择地址之后回到首页
                                                          self.tabBarController.selectedIndex=0;
                                                          [self.navigationController popToRootViewControllerAnimated:YES];
                                                          
                                                      }
                                                  }
                                              } else {
                                                  [self showToastMessage:responseObject[@"msg"]];
                                              }
                                          }];
                                          
                                          }
                                          
                                          
                                          //停留两秒以后，返回上一页
                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                              [self.navigationController popViewControllerAnimated:YES];
                                          });
                                          NSLog(@"更改收货地址成功 = %@", responseObject);
                                      } else {
                                          //此处弹出“操作频繁”，一定时间段内用户只能修改一次地址
                                          [self showToastMessage:responseObject[@"msg"]];
                                      }
                                  }];
            
        }
        
    }
    if ([self.fflag isEqualToString:@"1"]) {
      
        

    }
    

}
//管理收货地址删除按钮
- (IBAction)deleteAction:(id)sender {
    
    
    
    if ([YKSUserModel shareInstance].currentSelectAddress) {
        
        NSString *str=[YKSUserModel shareInstance].currentSelectAddress[@"id"];
        
        if (!IS_EMPTY_STRING(str)) {
            
            if ([str isEqualToString:_addressInfo[@"id"]]) {
                
                [self showToastMessage:@"不能删除当前选择的收货地址!"];
                
                return;
            }
            
        }
    }
    
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确定删除"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"取消", @"确定", nil];
    [alertView show];
    [alertView callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self showProgress];
            [GZBaseRequest deleteAddressById:_addressInfo[@"id"]
             
                                    callback:^(id responseObject, NSError *error) {
                                        [self hideProgress];
                                        if (error) {
                                            [self showToastMessage:@"网络加载失败"];
                                            return ;
                                        }
                                        if (ServerSuccess(responseObject)) {
                                            [self.navigationController showToastMessage:@"删除成功"];
                                            [self.navigationController popViewControllerAnimated:YES];
                                            
                                            NSLog(@"删除收货地址成功 = %@", responseObject);
                                            
                                        } else {
                                            
                                            
                                            [self showToastMessage:responseObject[@"msg"]];
                                        }
                                    }];
        }
    }];
    
    
    [UIViewController deleteFile];
    
    
}

- (IBAction)tapAction:(id)sender {
    NSLog(@"self.streetField.isFirstResponder = %d", self.streetField.isFirstResponder);
    if (!self.streetField.isFirstResponder) {
        self.searchView.hidden = YES;
    }
    [self.view endEditing:YES];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *street = textField.text;
    if (![_lastSearchKey isEqualToString:textField.text]) {
        NSLog(@"text = %@", textField.text);
        _lastSearchKey = textField.text;
        if (street.length > 0) {
            [[GZHTTPClient shareClient] GET:BaiduMapPlaceApi
                                 parameters:@{@"region": @"北京",
                                              @"query": _lastSearchKey,
                                              @"ak": BaiduMapAK,
                                              @"output": @"json"
                                              
                                              }
             
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        if (responseObject && [responseObject[@"status"] integerValue] == 0) {
                                            _searchView.hidden = NO;
                                            _searchView.searchDatas = responseObject[@"results"];
                                            [_searchView.tableView reloadData];
                                        }
                                        NSLog(@"responseObject %@", responseObject);
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error) {
                                        NSLog(@"error = %@", error);
                                    }];
        } else {
            _searchView.hidden = YES;
        }
    }
    
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });
    
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.searchView] || [touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"gotoYKSSearchStreetVC"]) {
        YKSSearchStreetVC *vc = segue.destinationViewController;
        vc.cityName=_City_Name.text;
        vc.hidesBottomBarWhenPushed = YES;
        
        vc.streetName=self.streetField.text;
        
        
        //         YKSSearchStreetVC *vc = (YKSSearchStreetVC *)[navigationController topViewController];
        vc.callback = ^(NSDictionary *street){
            _streetDic = street;
            _streetField.text = _streetDic[@"name"];
//            _phoneField.text=[YKSUserModel telePhone];
            _detailAddressField.text=@"";
        };
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        YKSCityViewController * cityVC = [[YKSCityViewController alloc]initWithBlock:^(NSString *cityName) {
            
            _City_Name.font=[UIFont systemFontOfSize:15];
            _City_Name.text=cityName;
            
            self.streetField.text=@"";
            
            self.detailAddressField.text=@"";
            
        }];
        
//        self.phoneField.text=[YKSUserModel telePhone];
        
        
        [self.navigationController pushViewController:cityVC animated:YES];
    }
}


//显示地址
- (void)showAddressView {
    
    // 不允许
    if (![YKSUserModel isLogin]) {
        [YKSTools login:self];
        return ;
    }
    __weak id bself = self;
    YKSSelectAddressView *selectAddressView = nil;
    
    YKSMyAddressViewcontroller *myVC=[[YKSMyAddressViewcontroller alloc]init];
    
    myVC.hidesBottomBarWhenPushed=YES;
    
    [self.navigationController pushViewController:myVC animated:YES];
    
    selectAddressView = [YKSSelectAddressView showAddressViewToView:myVC.view
                                                              datas:@[[self currentAddressInfo]]
                                                           callback:^(NSDictionary *info, BOOL isCreate) {
                                                               //新添
                                                               self.info=info;
                                                               
                                                               self.isCreat=isCreate;
                                                               
                                                               [UIViewController selectedAddressArchiver:info];
                                                               
                                                               if (![[[YKSUserModel shareInstance]currentSelectAddress][@"id"]isEqualToString:info[@"id"]]) {
                                                                   
                                                                   NSString *name =[YKSUserModel shareInstance].currentSelectAddress[@"didinfo"][@"name"];
                                                                   NSString *name1 = info[@"didinfo"][@"name"];
                                                                   
                                                                   if (![name isEqualToString:name1]) {
                                                                       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"修改地址？" message:@"确认修改地址将清空购物车" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                                                                       [alert show];
                                                                       
                                                                       return ;
                                                                   
                                                                   }
                                                                   else{
                                                                       [self.navigationController popToRootViewControllerAnimated:YES];
                                                                   }

                                                                   //                                                              [alert callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                                   //                                                                  if (buttonIndex == 1) {
                                                                   //
                                                                   //                                                                  }
                                                                   //                                                              }];
                                                               }
                                                               if (info) {
                                                                   if (info[@"community_lat_lng"]) {
                                                                       NSArray *array = [info[@"community_lat_lng"] componentsSeparatedByString:@","];
                                                                       [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                                                                       [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                                                                   }
                                                                   if (![YKSUserModel shareInstance].currentSelectAddress) {
                                                                       [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                   }
                                                                   
                                                               }
                                                               if (isCreate) {
                                                                   
                                                                   
                                                                   [bself gotoAddressVC:info];
                                                               } else {
                                                                   
                                                                   [YKSUserModel shareInstance].currentSelectAddress = info;
                                                                   //这里就是了,拿到地址,删除旧地址
                                                                   
                                                                   [UIViewController deleteFile];           [UIViewController selectedAddressArchiver:info];
                                                                   
                                                                   
                                                                   
                                                               }
                                                           }];
    //    [selectAddressView reloadData];
    selectAddressView.removeViewCallBack = ^{
        
        
    };
    [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject)) {
            NSDictionary *dic = responseObject[@"data"];
            if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                selectAddressView.datas = [dic[@"addresslist"] mutableCopy];
                [YKSUserModel shareInstance].addressLists = selectAddressView.datas;
                if (!selectAddressView.datas) {
                    selectAddressView.datas = [NSMutableArray array];
                }
                
                [selectAddressView.datas insertObject:[self currentAddressInfo] atIndex:0];
                [selectAddressView reloadData];
            }
        }
    }];
    
}

- (NSDictionary *)currentAddressInfo {
    
    NSDictionary *dic=[UIViewController selectedMyLocation];
    
    NSString *district = dic[@"addressComponent"][@"district"];
    NSString *street = dic[@"addressComponent"][@"street"];
    NSString *street_number = dic[@"addressComponent"][@"street_number"];
    NSString *formatted_address = dic[@"formatted_address"];
    
    
    NSString  *a=(NSString *)dic[@"sendable"];
    if (IS_EMPTY_STRING(a)) {
        return @{@"province": @"11",
                 @"district": district ? district : @"",
                 @"street":  street ? street : @"",
                 @"street_number":  street_number ? street_number : @"",
                 @"express_username": @"我的位置",
                 @"express_mobilephone": @"",
                 @"express_detail_address":  formatted_address? formatted_address : @""
                 };
    }
    
    return @{@"province": @"11",
             @"district": district ? district : @"",
             @"street":  street ? street : @"",
             @"street_number":  street_number ? street_number : @"",
             @"express_username": @"我的位置",
             @"express_mobilephone": @"",
             @"express_detail_address":  formatted_address? formatted_address : @"",
             @"sendable":a
             };
}


- (void)gotoAddressVC:(NSDictionary *)addressInfo {
    
    if (![YKSUserModel isLogin]) {
        [YKSTools login:self];
        return;
    }
    
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    YKSAddAddressVC *vc = [mainBoard instantiateViewControllerWithIdentifier:@"YKSAddAddressVC"];
    
    vc.addressInfo = [addressInfo mutableCopy];
    vc.isCurrentLocation = YES;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        __weak id bself = self;
        YKSSelectAddressView *selectAddressView = nil;
        {
            //新添
            NSDictionary *info = self.info;
            BOOL isCreate = self.isCreat;
            
            
            if (info) {
                if (info[@"community_lat_lng"]) {
                    NSArray *array = [info[@"community_lat_lng"] componentsSeparatedByString:@","];
                    [YKSUserModel shareInstance].lat = [[array firstObject] floatValue];
                    [YKSUserModel shareInstance].lng = [[array lastObject] floatValue];
                }
                
                
            }
            if (isCreate) {
                [bself gotoAddressVC:[UIViewController selectedMyLocation]];
                
                return;
            } else {
                //清空购物车
                [GZBaseRequest restartShoppingCartBygids:nil callback:^(id responseObject, NSError *error) {
                    
                    if (ServerSuccess(responseObject))
                    {
                        
                    }
                }];

                
                
                [YKSUserModel shareInstance].currentSelectAddress = info;
                //这里就是了,拿到地址,删除旧地址
                
                [UIViewController deleteFile];           [UIViewController selectedAddressArchiver:info];
            }
        };
        //    [selectAddressView reloadData];
        selectAddressView.removeViewCallBack = ^{
            
        };
        [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
            if (ServerSuccess(responseObject)) {
                NSDictionary *dic = responseObject[@"data"];
                if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                    selectAddressView.datas = [dic[@"addresslist"] mutableCopy];
                    [YKSUserModel shareInstance].addressLists = selectAddressView.datas;
                    if (!selectAddressView.datas) {
                        selectAddressView.datas = [NSMutableArray array];
                    }
                    [selectAddressView.datas insertObject:[self currentAddressInfo] atIndex:0];
                    [selectAddressView reloadData];
                }
            }
        }];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
        
    }
    
    
    
    
}




@end
