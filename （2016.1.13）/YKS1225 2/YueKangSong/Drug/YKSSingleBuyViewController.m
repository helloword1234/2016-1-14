//
//  YKSSingleBuyViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/21.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSSingleBuyViewController.h"
#import "YKSBuyCell.h"
#import "YKSConstants.h"
#import "YKSTools.h"
#import "GZBaseRequest.h"
#import "YKSAddressListViewController.h"
#import "YKSOrderConfirmView.h"
#import "YKSCloseButton.h"
#import "YKSCouponViewController.h"
#import "YKSUserModel.h"
#import "YKSCouponViewController.h"
#import "MBProgressHUD.h"

#import "YKSAppDelegate.h"
#import "Pingpp.h"

#import "YKSPaytypeCell.h"

#define kWaiting          @"正在获取支付凭据,请稍后..."
#define kNote             @"提示"
#define kConfirm          @"确定"
#define kErrorNet         @"网络错误"
#define kResult           @"支付结果：%@"

#define KUrlScheme  @"wxdd50133f4733fe7c"//@"demoapp001"  //  这个是你定义的 URL Scheme，支付宝、微信支付和测试模式需要。
#define kUrl       @"http://218.244.151.190/demo/charge" // 服务器的地址

@interface YKSSingleBuyViewController () <
UITableViewDataSource,
UITableViewDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIActionSheetDelegate,UIAlertViewDelegate>
{
    NSTimer *theTimer;
}
//@property (weak, nonatomic) IBOutlet UILabel *youhuiquanlabel;
//@property (weak, nonatomic) IBOutlet UILabel *youhuilabel;
@property (nonatomic,strong) YKSPaytypeCell *payCell;

//这个是表哥
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//价格标签
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;
@property (assign, nonatomic) BOOL isPrescription; //是否是处方药
@property (assign, nonatomic) NSInteger buyCount;
@property (strong, nonatomic) NSDictionary *addressInfos;
//这里有一个优惠券信息
@property (strong, nonatomic) NSDictionary *couponInfo;
@property (strong, nonatomic) NSMutableArray *uploadImages;
//这个是更新图片
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

//目前总价,需要从网络上获取,我们已经有了
@property (assign, nonatomic) CGFloat totalPrice;
@property (assign, nonatomic) CGFloat originTotalPrice;
@property (assign, nonatomic) CGFloat youhuiquanjiage;

@property (weak, nonatomic) IBOutlet UILabel *freightLabel;

@property(nonatomic,strong)NSMutableArray *paytypeArray;

@property NSInteger Count;// 优惠券数量；

@property(strong,nonatomic)NSMutableArray *couponArray2;

//@property(nonatomic,strong)NSMutableArray *couponArray; // 优惠券

@property (strong,nonatomic) NSMutableArray *neverDatas; // 未使用的数据
@property(strong,nonatomic)  NSMutableArray *didDatas;   // 已使用的数据
@property(strong,nonatomic)  NSMutableArray *pastDatas;  // 已过期的数据


@property NSInteger flag;
@end


@implementation YKSSingleBuyViewController
@synthesize channel;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewDidLoad {
    self.channel=@"cash";
    self.flag =0;
    [self requestAddressData];
    
    [super viewDidLoad];
         _uploadImages = [NSMutableArray array];
    
    NSLog(@"_drugInfo = %@", _drugInfo);
    _isPrescription = [_drugInfo[@"gtag"] boolValue];
    _confirmButton.layer.masksToBounds = YES;
    _confirmButton.layer.cornerRadius = 5.0f;
    
    if (_isPrescription) {
        [_confirmButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [_confirmButton setTitle:@"含处方药，请医师与我联系" forState:UIControlStateNormal];
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 5.0f;
        [_confirmButton setBackgroundImage:nil forState:UIControlStateNormal];
    }
    _buyCount = 1;
    _totalPrice = [_drugInfo[@"gprice"] floatValue] * _buyCount;
    _originTotalPrice = _totalPrice;
    [YKSTools showFreightPriceTextByTotalPrice:_totalPrice callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
        _totalPriceLabel.attributedText = totalPriceString;
        _freightLabel.text = freightPriceString;
    }];
    
    if ([YKSUserModel shareInstance].currentSelectAddress) {
        _addressInfos = [[YKSUserModel shareInstance] currentSelectAddress];
    }
    
   [self requestDataByPage:1];
  //  _Count = _neverDatas.count;
   
    [self getpay];
    
    [self.tableView reloadData];

}
-(void)requestAddressData{

    [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject)) {
            NSDictionary *dic = responseObject[@"data"];
            if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                
                NSArray *array = [dic[@"addresslist"] mutableCopy];
                
                NSDictionary *dict1=[YKSUserModel shareInstance].currentSelectAddress;
                
                for (NSDictionary *dict in array) {
                    
                    NSNumber *a=dict[@"id"];
                    NSNumber *b=dict1[@"id"];
                    
                    if ([a isEqual:b]) {
                        [YKSUserModel shareInstance].currentSelectAddress=dict;
                        [self.tableView reloadData];
                    }
                }
            }
        }
    }];

}


// 优惠券数据请求
- (void)requestDataByPage:(NSInteger)page
{
    
    [GZBaseRequest couponList:page callback:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject))
        {
            
            NSArray *array= responseObject[@"data"][@"couponlist"];
            _couponArray2=[NSMutableArray arrayWithArray:array];
            
            _neverDatas=[NSMutableArray array];
            [_couponArray2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj[@"is_out_of_date"] integerValue]==1) {
                    //[_pastDatas addObject:obj];
                }else{
                    if ([obj[@"is_used"] integerValue]==1) {
                        //[_didDatas addObject:obj];
                    }
                    else{
                        
                        [_neverDatas addObject:obj];
                    }
                }
            }];
        
            NSMutableArray  *Carray=[[NSMutableArray alloc] init];
            
              [_neverDatas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                 
                  NSString *a =[NSString stringWithFormat:@"%@",obj[@"fileLimit"]];
                 // NSLog(@"+++++++++++++++++++%@",obj[@"fileLimit"]);
                       //  CGFloat limit = [obj[@"fileLimit"] floatValue];
                  
                  if([a isEqualToString: @"<null>"])
                  {
                    a=@"0";
                  }
                  CGFloat b=[a floatValue];
                if ([obj[@"condition"]isEqualToString:@""]||(_originTotalPrice >= b))
                      {
                          
                          [Carray addObject:obj];
                      }
                 }];
            NSLog(@"%@",Carray);
             _Count = Carray.count;
      
             [self.tableView reloadData];
            
        }
    }];
}



// 优惠券数量判断
-(void)coupon
{
    NSMutableArray  *Carray=[[NSMutableArray alloc] init];
    
    [_neverDatas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *a =[NSString stringWithFormat:@"%@",obj[@"fileLimit"]];

        
        if([a isEqualToString: @"<null>"])
        {
            a=@"0";
        }
        CGFloat b=[a floatValue];
        if ([obj[@"condition"]isEqualToString:@""]||(_originTotalPrice >= b))
        {
            
            [Carray addObject:obj];
        }
    }];
    NSLog(@"%@",Carray);
    _Count = Carray.count;
    

}

// 获得支付渠道
-(void)getpay
{
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:HUD];
    HUD.labelText = @"正在获取";
    HUD.mode = MBProgressHUDModeIndeterminate;
    [HUD show:YES];
    
    
    [GZBaseRequest getpaytype:^(id responseObject, NSError *error) {
        
        if (ServerSuccess(responseObject))
            
        {
            [HUD hide:YES afterDelay:3];
            _paytypeArray =[NSMutableArray arrayWithArray:responseObject[@"data"]];
            [self.tableView reloadData];
            
        }
        else
        {
            [self showToastMessage:responseObject[@"msg"]];
            
        }
    }];
}


#pragma mark - custom
- (void)addImageAction:(YKSCloseButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"拍照", @"从相册选取", nil];
    [actionSheet showInView:self.view];
}

- (void)removeUpdaloadImage:(UIButton *)sender {
    YKSCloseButton *closeButton = (YKSCloseButton *)sender.superview;
    [_uploadImages removeObject:closeButton.imageView.image];
    [self.tableView reloadData];
}

#pragma mark - IBOutlets
- (IBAction)buyAction:(id)sender {
    if (!_addressInfos) {
        [self showToastMessage:@"请选择收货地址"];
        return ;
    }
    if (_isPrescription && _uploadImages.count == 0) {
        [self showToastMessage:@"处方药请上传医嘱说明"];
        return;
    }
    UIAlertView *buyAlert = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"根据新版GSP（卫生部第90号令）第一百七十七条规定，药品除质量原因外，一经售出，不得退换。悦康送所售药品及保健品除质量问题外不支持退货。是否确认下单？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil ];
    [buyAlert show];
    [buyAlert callBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        
        if (buttonIndex == 1)
        {
            if (![self.channel isEqualToString:@"cash"])
            {

                NSDictionary *dict =@{@"channel" : self.channel};
                
                    // NSString *paytype =dic[@"pay_type"];
                
                YKSSingleBuyViewController *__weak weakSelf = self;
                //[self showAlertWait];
                
                [GZBaseRequest submitOrderContrast:@[@{@"gid": _drugInfo[@"gid"],
                                                       @"gcount": @(_buyCount),
                                                       @"gtag": _drugInfo[@"gtag"]}]
                                          couponid:_couponInfo ? _couponInfo[@"id"] : nil
                                         addressId:_addressInfos[@"id"]
                                            images:_uploadImages
                                            charge:dict
                                          pay_type:self.channel
                                          callback:^(id responseObject, NSError *error) {
                                              
                                              if (error) {
                                                  [self showToastMessage:@"网络加载失败"];
                                                  return ;
                                              }
                                             //在线支付渠道
                                            if (ServerSuccess(responseObject)){
                                                  [self showToastMessage:kWaiting];
                                                  NSString * charge1 = responseObject[@"data"][@"charge"];
                                                
                                                  NSData *data=[NSJSONSerialization dataWithJSONObject:charge1 options:0 error:nil];
                                                  NSString *charge=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                                
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [Pingpp createPayment:charge  viewController:weakSelf appURLScheme:KUrlScheme withCompletion:^(NSString *result, PingppError *error) {
                                                          
                                                          NSLog(@"completion block: %@",result);
                                                          if ([result isEqualToString:@"success"])//error == nil)
                                                          {
                                                              
                                                              // NSLog(@"PingppEdrror is  nil");
                                                              
                                                              [YKSOrderConfirmView showOrderToView:self.view.window orderId:responseObject[@"data"][@"orderid"] callback:^{
                                                                  
                                                                  [self dismissViewControllerAnimated:NO completion:nil];
                                                                  if (self.navigationController.presentingViewController) {
                                                                      if ([self.navigationController.presentingViewController isKindOfClass:[UITabBarController class]]) {
                                                                          [(UITabBarController *)self.navigationController.presentingViewController setSelectedIndex:2];
                                                                      }
                                                                      [self.navigationController dismissViewControllerAnimated:NO completion:^{
                                                                      }];
                                                                  } else {
                                                                      self.tabBarController.selectedIndex = 2;
                                                                      [self.navigationController popToRootViewControllerAnimated:NO];
                                                                  }
                                                              }];
                                                          }
                                                          else
                                                          {
                                                              
                                                              [weakSelf showAlertMessage:result];
                                                              NSLog(@"PingppError : code =%lu msg=%@",(unsigned long)error.code,[error getMsg]);
                                                          }
                                                      }];
                                                  });
                                              }else
                                              {
                                                  [self showToastMessage:responseObject[@"msg"]];
                                              }
                                          }];
                return ;
            }
            //请求网络获取药品处方药非处方药详情
            [self showProgress];
            
            NSDictionary *dict=@{@"channel":@"cash"};
         
          //  NSDictionary *dic = [_cashArray objectAtIndex:0];

            [GZBaseRequest submitOrderContrast:@[@{@"gid": _drugInfo[@"gid"],
                                                   @"gcount": @(_buyCount),
                                                   @"gtag": _drugInfo[@"gtag"]}]
                                      couponid:_couponInfo ? _couponInfo[@"id"] : nil
                                     addressId:_addressInfos[@"id"]
                                        images:_uploadImages
                                        charge:dict
                                      pay_type:@"cash"
             
                                      callback:^(id responseObject, NSError *error) {
                                          [self hideProgress];
                                          
                                          if (error) {
                                              
                                              [self showToastMessage:@"网络加载失败"];
                                              return ;
                                          }
                                          //这里都提交订单了,里面应该有价格提交吧
                                          
                                          if (ServerSuccess(responseObject)) {
                                              NSLog(@"订单处理中 %@", responseObject);
                                              [YKSOrderConfirmView showOrderToView:self.view.window orderId:responseObject[@"data"][@"orderid"] callback:^{
                                                  
                                                  [self dismissViewControllerAnimated:NO completion:nil];
                                                  if (self.navigationController.presentingViewController) {
                                                      if ([self.navigationController.presentingViewController isKindOfClass:[UITabBarController class]]) {
                                                          [(UITabBarController *)self.navigationController.presentingViewController setSelectedIndex:2];
                                                      }
                                                      [self.navigationController dismissViewControllerAnimated:NO completion:^{
                                                      }];
                                                  } else {
                                                      self.tabBarController.selectedIndex = 2;
                                                      [self.navigationController popToRootViewControllerAnimated:NO];
                                                  }
                                              }];
                                          } else {
                                              
                                              [self showToastMessage:responseObject[@"msg"]];
                                          }
                                          
                                          
                                      }];
        }
    }];
    
    
}
- (void)showAlertWait
{
    mAlert = [[UIAlertView alloc] initWithTitle:kWaiting message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    [mAlert show];
    UIActivityIndicatorView* aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    aiv.center = CGPointMake(mAlert.frame.size.width / 2.0f - 15, mAlert.frame.size.height / 2.0f + 10 );
    [aiv startAnimating];
    [mAlert addSubview:aiv];
}
//在线支付凭据
- (void)showAlertMessage:(NSString*)msg
{
    if ([msg isEqualToString:@"cancel"]) {
        msg=@"您已取消支付";
    }
    if ([msg isEqualToString:@"fail"]) {
        msg=@"支付失败";
    }
    if ([msg isEqualToString:@"success"]) {
        msg=@"支付成功";
    }
    
    mAlert = [[UIAlertView alloc] initWithTitle:kNote message:msg delegate:nil cancelButtonTitle:kConfirm otherButtonTitles:nil, nil];
    [mAlert show];
}

- (void)hideAlert
{
    if (mAlert != nil)
    {
        [mAlert dismissWithClickedButtonIndex:0 animated:YES];
        mAlert = nil;
    }
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { //拍照
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else if (buttonIndex == 1) { //从相册选取
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [_uploadImages addObject:image]; //imageView为自己定义的UIImageView
    [self.tableView reloadData];
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 73.f;
    } else if (indexPath.section == 1) {
        return 148;
    } else if (indexPath.section == 2) {
        if (_isPrescription) {
            return 69;
        } else {
            return 44;
        }
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //这里他慢了
    NSDictionary *dic = [_paytypeArray objectAtIndex:indexPath.row];
    NSDictionary *currentAddr = [YKSUserModel shareInstance].currentSelectAddress;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (currentAddr) {
            if ([currentAddr[@"sendable"] integerValue] == 1) {
                return ;
            }
        }
        //[self performSegueWithIdentifier:@"gotoYKSAddressListViewController" sender:nil];
    }
    
    if(_isPrescription)
    {
        if (indexPath.section == 4)
        {
            self.flag = indexPath.row;
            [self.tableView reloadData];
            NSString *channel = dic[@"pay_type"];
            self.channel = channel;
        }
    }
    if (!(_isPrescription))
    {
        if (indexPath.section == 3)
        {
            self.flag = indexPath.row;
            [self.tableView reloadData];
            NSString *channel = dic[@"pay_type"];
            self.channel = channel;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //    if (indexPath.section == 0) {
    //        if ([[YKSUserModel shareInstance] currentSelectAddress]) {
    //            if ([[YKSUserModel shareInstance].currentSelectAddress[@"sendable"] integerValue] == 1) {
    //                return ;
    //            }
    //        }
    //        [self performSegueWithIdentifier:@"gotoYKSAddressListViewController" sender:nil];
    //    }
    //    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}





#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _isPrescription ? 5 : 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  
    if (_isPrescription) {
        if (section == 4)
        {

            return _paytypeArray.count;
        }
    }
    
    if (!_isPrescription)
        {
            if (section==3)
            {

                return _paytypeArray.count;
            }
         }
    return 1;
}
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *currentAddr = [YKSUserModel shareInstance].currentSelectAddress;
    
    if (indexPath.section == 0)
    {
        YKSBuyAddressCell *addressCell = [tableView dequeueReusableCellWithIdentifier:@"BuyAddressCell" forIndexPath:indexPath];
        addressCell.userInteractionEnabled = NO;
        
        if (currentAddr) {
            if ([currentAddr[@"sendable"] integerValue] == 1) {
                addressCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        NSDictionary *dic = currentAddr;
        
        //        if ([[YKSUserModel shareInstance] currentSelectAddress]) {
        //            if ([[YKSUserModel shareInstance].currentSelectAddress[@"sendable"] integerValue] == 1) {
        //                addressCell.accessoryType = UITableViewCellAccessoryNone;
        //            }
        //        }
        //        NSDictionary *dic = _addressInfos;
        if (!dic) {
            addressCell.nameLabel.text = @"点击进入选择收货地址";
            addressCell.phoneLabel.text = @"";
            addressCell.addressLabel.text = @"";
        }
        else {
            addressCell.nameLabel.text = DefuseNUllString(dic[@"express_username"]);
            addressCell.phoneLabel.text = DefuseNUllString(dic[@"express_mobilephone"]);
            addressCell.addressLabel.text = [NSString stringWithFormat:@"%@%@", dic[@"community"], dic[@"express_detail_address"]];
        }
        return addressCell;
    }
    else if (indexPath.section == 1) {
        YKSBuyDrugCell *drugCell = [tableView dequeueReusableCellWithIdentifier:@"BuyDrugCell" forIndexPath:indexPath];
        [drugCell.logoImageView sd_setImageWithURL:[NSURL URLWithString:_drugInfo[@"glogo"]] placeholderImage:[UIImage imageNamed:@"default160"]];
        drugCell.recipeFlagView.hidden = ![_drugInfo[@"gtag"] boolValue];
        drugCell.titleLabel.text = _drugInfo[@"gtitle"];
        drugCell.priceLabel.attributedText = [YKSTools priceString:[_drugInfo[@"gprice"] floatValue]];
        drugCell.countLabel.text = [[NSString alloc] initWithFormat:@"x%@", @(_buyCount)];
        drugCell.centerCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(_buyCount)];
        [drugCell.addButton addTarget:self action:@selector(addCount:) forControlEvents:UIControlEventTouchUpInside];
        [drugCell.minusButton addTarget:self action:@selector(minusCount:) forControlEvents:UIControlEventTouchUpInside];
        return drugCell;
    }
    else if (indexPath.section == 2)
    {
        if (_isPrescription)
        {
            YKSBuyLabelCell *labelCell = [tableView dequeueReusableCellWithIdentifier:@"BuyLabelCell" forIndexPath:indexPath];
            [labelCell.rightButton addTarget:self
                                      action:@selector(addImageAction:)
                            forControlEvents:UIControlEventTouchUpInside];
            [labelCell.leftButton.closeButton addTarget:self
                                                 action:@selector(removeUpdaloadImage:)
                                       forControlEvents:UIControlEventTouchUpInside];
            [labelCell.centerButton.closeButton addTarget:self
                                                   action:@selector(removeUpdaloadImage:)
                                         forControlEvents:UIControlEventTouchUpInside];
            [labelCell.rightButton.closeButton addTarget:self
                                                  action:@selector(removeUpdaloadImage:)
                                        forControlEvents:UIControlEventTouchUpInside];
            
            labelCell.centerButton.hidden = NO;
            labelCell.leftButton.hidden = NO;
            labelCell.rightButton.closeButton.hidden = NO;
            if (_uploadImages.count > 0) {
                [labelCell.centerButton setImage:[_uploadImages firstObject] forState:UIControlStateNormal];
                if (_uploadImages.count > 1) {
                    [labelCell.leftButton setImage:_uploadImages[1] forState:UIControlStateNormal];
                } else {
                    labelCell.leftButton.hidden = YES;
                }
                if (_uploadImages.count > 2) {
                    [labelCell.rightButton setImage:_uploadImages[2] forState:UIControlStateNormal];
                } else {
                    labelCell.rightButton.closeButton.hidden = YES;
                    [labelCell.rightButton setImage:[UIImage imageNamed:@"add_image"] forState:UIControlStateNormal];
                }
            }
            else {
                labelCell.centerButton.hidden = YES;
                labelCell.leftButton.hidden = YES;
                labelCell.rightButton.closeButton.hidden = YES;
                [labelCell.rightButton setImage:[UIImage imageNamed:@"add_image"] forState:UIControlStateNormal];
            }
            return labelCell;
        }
        else
        {
            YKSBuyCouponCell *couponCell = [tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:indexPath];
                       if (_couponInfo) {
           
//                
//                NSString *a =[NSString stringWithFormat:@"%@",self.couponInfo[@"fileLimit"]];
//                if([a isEqualToString: @"<null>"])
//                {
//                    a=@"0";
//                }
//                CGFloat b=[a floatValue];
//                if ([self.couponInfo[@"condition"]isEqualToString:@""]||(_originTotalPrice >= b))
//                 
//                {
                           couponCell.detailTextLabel.text=@"aaaaaaa";
                                    couponCell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f优惠劵", [_couponInfo[@"faceprice"] floatValue]];
                
                
                
              //  }
//                else
//                {
//                    
//                    NSString *couponCount = [NSString stringWithFormat:@"您有%ld张优惠券可以使用",_Count];
//                    couponCell.detailTextLabel.textColor=[UIColor redColor];
//                    couponCell.detailTextLabel.text = couponCount;
//                }


                
            }else{
                
//                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:2];
//                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationFade];
                
                NSString *couponCount = nil;
                if (_Count == 0) {
                    couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
                }else
                {
                    couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",(long)_Count];
                }
                
                couponCell.detailTextLabel.textColor=[UIColor redColor];
                couponCell.detailTextLabel.text = couponCount;
            } 
            return couponCell;
        }
    }
    else if(_isPrescription)
    {
        
        if (indexPath.section==3) {
            YKSBuyCouponCell *couponCell = [tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:indexPath];
            if (_couponInfo) {
               couponCell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f优惠劵", [_couponInfo[@"faceprice"] floatValue]];
//                NSString *couponCount = [NSString stringWithFormat:@"您有%ld张优惠券可以使用",_Count];
//                couponCell.detailTextLabel.textColor=[UIColor redColor];
//                couponCell.detailTextLabel.text = couponCount;

            }
            
            else{
                
                NSString *couponCount = nil;
                if (_Count == 0) {
                    couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
                }else
                {
                    couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",_Count];
                }
                couponCell.detailTextLabel.textColor=[UIColor redColor];

                couponCell.detailTextLabel.text = couponCount;
            }
            
            return couponCell;
        }
        else{
//            NSString *iden=@"onetwothree";
//            
//            UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:iden];
//            
//            if (!cell) {
//                cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:iden];
//            }
            YKSPaytypeCell *payCell = [tableView dequeueReusableCellWithIdentifier:@"iden"];
            if (!payCell) {
                payCell = [[YKSPaytypeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"iden"];
               
            }
            
            NSDictionary *dic =[_paytypeArray objectAtIndex:indexPath.row];
            
            NSString *payName =dic[@"description"];
            payCell.textLabel.text=payName;
             NSString *channel = dic[@"pay_type"];
            if (indexPath.row == self.flag)
            {
                [payCell.btn setBackgroundImage:[UIImage imageNamed:@"pay_ok"] forState:UIControlStateNormal];
                self.channel =channel;
            }
            else
            {
                [payCell.btn setBackgroundImage:[UIImage imageNamed:@"pay"] forState:UIControlStateNormal];
            }
            [payCell.contentView addSubview:payCell.btn];
            return payCell;
        }
        
    }
    else
    {
        YKSPaytypeCell *payCell = [tableView dequeueReusableCellWithIdentifier:@"iden"];
        if (!payCell) {
            payCell = [[YKSPaytypeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"iden"];
            
        }
        
        NSDictionary *dic =[_paytypeArray objectAtIndex:indexPath.row];
        
        NSString *payName =dic[@"description"];
        payCell.textLabel.text=payName;
        NSString *channel = dic[@"pay_type"];
        if (indexPath.row == self.flag)
        {
            [payCell.btn setBackgroundImage:[UIImage imageNamed:@"pay_ok"] forState:UIControlStateNormal];
            self.channel = channel;
        }
        else
        {
            [payCell.btn setBackgroundImage:[UIImage imageNamed:@"pay"] forState:UIControlStateNormal];
        }
        [payCell.contentView addSubview:payCell.btn];

        return payCell;
    }

}



#pragma mark - UITableView Action
- (void)addCount:(UIButton *)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    YKSBuyDrugCell *drugCell = (YKSBuyDrugCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    _buyCount++;
    
    if (_drugInfo[@"repertory"] && _buyCount > [_drugInfo[@"repertory"] integerValue]) {
        [YKSTools showToastMessage:@"已超出最大库存" inView:[[[UIApplication sharedApplication] delegate] window]];
        _buyCount--;
        return;
    }
    _originTotalPrice = [_drugInfo[@"gprice"] floatValue] *_buyCount;
    
    [self coupon];
    if (_originTotalPrice>[self.couponInfo[@"fileLimit"] floatValue]) {
        self.couponInfo = nil;
        if (_isPrescription)
        {
            YKSBuyCouponCell *couponCell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
            
            NSString *couponCount = nil;
            if (_Count == 0) {
                couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
            }else
            {
                couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",_Count];
            }
            
            couponCell.detailTextLabel.textColor=[UIColor redColor];
            couponCell.detailTextLabel.text = couponCount;
        }
        else
            
        {
            
            YKSBuyCouponCell *couponCell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
            
            NSString *couponCount = nil;
            if (_Count == 0) {
                couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
            }else
            {
                couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",(long)_Count];
            }
            
            
            couponCell.detailTextLabel.textColor=[UIColor redColor];
            couponCell.detailTextLabel.text = couponCount;
            
            
        }
        
    }

    [self showPirce:drugCell];
    
     [self.tableView reloadData];
}

- (void)minusCount:(UIButton *)sender {
    //_couponInfo = nil;
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    YKSBuyDrugCell *drugCell = (YKSBuyDrugCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    _buyCount--;
    
    if(_buyCount == 0)
    {
        _buyCount = 1;
        return ;
    }
    if (_buyCount  < 1)
    {
        _buyCount = 1;
    }
    _originTotalPrice = [_drugInfo[@"gprice"] floatValue] *_buyCount;

    
//    if (_originTotalPrice<[self.couponInfo[@"faceprice"] floatValue]) {
//        self.couponInf`o = nil;
//        
//#pragma kkkk
//        //        YKSBuyCouponCell *couponCell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
//        //        couponCell.detailTextLabel.text = @"";
//        
//    }
    [self coupon];
    if (_originTotalPrice<[self.couponInfo[@"fileLimit"] floatValue] || _originTotalPrice > [self.couponInfo[@"fileLimit"] floatValue]) {
        self.couponInfo = nil;
        if (_isPrescription)
        {
            YKSBuyCouponCell *couponCell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
            
            NSString *couponCount = nil;
            if (_Count == 0) {
                couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
            }else
            {
                couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",_Count];
            }
            
            couponCell.detailTextLabel.textColor=[UIColor redColor];
            couponCell.detailTextLabel.text = couponCount;
        }
        else
        {
            
            YKSBuyCouponCell *couponCell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCouponCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
            
            NSString *couponCount = nil;
            if (_Count == 0) {
                couponCount = [NSString stringWithFormat:@"无可用的优惠劵"];
            }else
            {
                couponCount = [NSString stringWithFormat:@"%ld张优惠券可用",(long)_Count];
            }
            
            
            couponCell.detailTextLabel.textColor=[UIColor redColor];
            couponCell.detailTextLabel.text = couponCount;
            
            
        }
        
    }
    
    [self.tableView reloadData];
    
    [self showPirce:drugCell];
}

- (void)showPirce:(YKSBuyDrugCell *)drugCell {
    drugCell.countLabel.text = [[NSString alloc] initWithFormat:@"x%@", @(_buyCount)];
    drugCell.centerCountLabel.text = [[NSString alloc] initWithFormat:@"%@", @(_buyCount)];
    _totalPrice = [_drugInfo[@"gprice"] floatValue] * _buyCount;
    
    [YKSTools showFreightPriceTextByTotalPrice:_originTotalPrice
                                      callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
                                          
                                          
                                          NSString *a =[NSString stringWithFormat:@"%@",self.couponInfo[@"fileLimit"]];
                                          
                                          
                                          if([a isEqualToString: @"<null>"])
                                          {
                                              a=@"0";
                                          }
                                          CGFloat b=[a floatValue];
                                          if ([self.couponInfo[@"condition"]isEqualToString:@""]||(_originTotalPrice >= b))
                                          {
                                              CGFloat price = [totalPriceString.string substringFromIndex:1].floatValue-[self.couponInfo[@"faceprice"] floatValue];
                                              
                                              price = price<0?0:price;
                                              
                                              _totalPriceLabel.attributedText = [YKSTools priceString:price  ];
                                              _freightLabel.text = freightPriceString;

                                          }
                                          else
                                          {
                                              CGFloat price = [totalPriceString.string substringFromIndex:1].floatValue;
                                              
                                              price = price<0?0:price;
                                              
                                              _totalPriceLabel.attributedText = [YKSTools priceString:price  ];
                                              _freightLabel.text = freightPriceString;

                                              
                                          }

                                       }];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"gotoYKSAddressListViewController"]) {
        YKSAddressListViewController *vc = segue.destinationViewController;
        vc.callback = ^(NSDictionary *info){
            _addressInfos = info;
            [self.tableView reloadData];
        };
        
        //优惠券
    } else if ([segue.identifier isEqualToString:@"gotoYKSCouponViewController"]) {
        YKSCouponViewController *vc = segue.destinationViewController;
        vc.totalPirce = _originTotalPrice;
        //        if (!_couponInfo) {
        //            vc.totalPirce = _totalPrice;
        //        } else {
        //            vc.totalPirce = _totalPrice + [_couponInfo[@"faceprice"] floatValue];
        //        }
        
//        [vc returnText:^(NSMutableArray *couponArray) {
//            
//            self.couponArray2 = couponArray;
//        }];
        
     
        
        vc.callback = ^(NSDictionary *info) {
            _couponInfo = info;
            if (_couponInfo && _couponInfo[@"faceprice"]) {
                //                _totalPrice = _originTotalPrice - [self.couponInfo[@"faceprice"] floatValue];
                [YKSTools showFreightPriceTextByTotalPrice:_originTotalPrice callback:^(NSAttributedString *totalPriceString, NSString *freightPriceString) {
                    CGFloat freightPrice = [totalPriceString.string substringFromIndex:1].floatValue;
                    CGFloat price = freightPrice - [self.couponInfo[@"faceprice"] floatValue];
                    _totalPriceLabel.attributedText = [YKSTools priceString:price];
                    _freightLabel.text = freightPriceString;
                }];
            }
            [self.tableView reloadData];
        };
    }
}


@end
