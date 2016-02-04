//
//  YKSTabBarViewController.m
//  YueKangSong
//
//  Created by gongliang on 15/5/12.
//  Copyright (c) 2015年 YKS. All rights reserved.
//
#import "YKSTabBarViewController.h"
#import "YKSFMDBManger.h"
#import "YKSUserModel.h"

@interface YKSTabBarViewController ()
@property(nonatomic,strong) NSString *count;
@property(nonatomic,strong) UITabBarItem *item2;
@end
@implementation YKSTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: kNavigationBar_back_color}
                                             forState:UIControlStateSelected];
    
    // Do any additional setup after loading the view.
    UITabBarItem *item1 = self.tabBar.items[0];
    [self tabbarItem:item1
           imageName:@"tabbar_home_normal"
     selectImageName:@"tabbar_home_select"];
    
    _item2 = self.tabBar.items[1];
    [self tabbarItem:_item2
           imageName:@"tabbar_cart_normal"
     selectImageName:@"tabbar_cart_select"];
    
    if ([YKSUserModel isLogin])
    {
        //读取购物车的商品数量
        [[YKSFMDBManger shareManger] readShoppingCarCount];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tongzhi:) name:@"tongzhi" object:nil];
    
    UITabBarItem *item3 = self.tabBar.items[2];
    [self tabbarItem:item3
           imageName:@"tabbar_drug_nomarl"
     selectImageName:@"tabbar_drug_select"];
    
    UITabBarItem *item4 = self.tabBar.items[3];
    [self tabbarItem:item4
           imageName:@"tabbar_my_normal"
     selectImageName:@"tabbar_my_select"];
}

//接受通知的方法，
-(void)tongzhi:(NSNotification *)test
{
    //给item购物车设置角标
    if (![test.userInfo[@"count"] isEqualToString:@"0"]) {
        [_item2 setBadgeValue:test.userInfo[@"count"]];
    }else
    {
        [_item2 setBadgeValue:nil];
    }
    
}

- (void)tabbarItem:(UITabBarItem *)item
         imageName:(NSString *)imageName
   selectImageName:(NSString *)selectImageName {
    UIImage *image = [UIImage imageNamed:imageName];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item.image = image;
    UIImage *selectImage = [UIImage imageNamed:selectImageName];
    selectImage = [selectImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item.selectedImage = selectImage;
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
