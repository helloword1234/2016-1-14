//
//  YKSOneBuyCell.m
//  YKSPharmacistRecommend
//
//  Created by ydz on 15/10/23.
//  Copyright © 2015年 ydz. All rights reserved.
//

#import "YKSOneBuyCell.h"
#import "YKSTools.h"

@interface YKSOneBuyCell ()
//显示"合计:"
@property (nonatomic,strong) UILabel *sum;
//显示总价格
@property (nonatomic,strong) UILabel *priceLabel;
//显示运费
@property (nonatomic,strong) UILabel *freightLabel;

@property(nonatomic,strong)NSArray *datas;

@end

@implementation YKSOneBuyCell
#pragma mark -- get创建控件
- (UILabel *)sum
{
    if (!_sum) {
        _sum = [[UILabel alloc] init];
    }
    return _sum;
}
- (UILabel *)priceLabel
{
    if (!_priceLabel) {
        _priceLabel = [[UILabel alloc] init];
    }
    return _priceLabel;
}
- (UILabel *)freightLabel
{
    if (!_freightLabel) {
        _freightLabel = [[UILabel alloc] init];
    }
    return _freightLabel;
}
-(NSArray *)datas{
    if (!_datas) {
        _datas = [NSArray array];
    }
    return _datas;
}
//将传来的值赋值到控件上
- (instancetype)initWithPrice:(float)price andViewFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = frame;
        self.sum.text = @"合计:";
        self.sum.font = [UIFont systemFontOfSize:14.0];
        self.sum.frame = CGRectMake(20, 5, 40, 15);
        [self addSubview:self.sum];
        
//        self.priceLabel.attributedText = [YKSTools priceString:price];
        self.priceLabel.text = [NSString stringWithFormat:@"%.2f",price];
        self.priceLabel.frame = CGRectMake(60, 5, 120, 15);
        self.priceLabel.font = [UIFont systemFontOfSize:19.0];
        self.priceLabel.textColor = [UIColor redColor];
//        self.priceLabel.textColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:0];
        [self addSubview:self.priceLabel];
        
        self.button = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.button setTitle:@"一键加入购物车" forState:UIControlStateNormal];
        [self.button setTintColor:[UIColor whiteColor]];
        //设置一键购买按钮圆角
        self.button.layer.cornerRadius = 6;
        self.button.backgroundColor = [UIColor redColor];
        self.button.titleLabel.textColor = [UIColor redColor];
        [self.button addTarget:self action:@selector(addShoppingCart:) forControlEvents:UIControlEventTouchUpInside];
        self.button.frame = CGRectMake(SCREEN_WIDTH - 140, 5, 120, 30);
        [self addSubview:self.button];
        [YKSTools showFreightPriceTextByTotalPrice:price
                                          callback:^(NSAttributedString *totalPriceString,  NSString *freightPriceString) {
                                              //self.priceLabel.attributedText = totalPriceString;
                                              self.freightLabel.text = freightPriceString;
                                          }];
        self.freightLabel.frame = CGRectMake(20, self.sum.frame.size.height + self.sum.frame.origin.y + 5, 100, 15);
        self.freightLabel.textColor = [UIColor lightGrayColor];
        self.freightLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.freightLabel];
        
    }
    return self;
}

- (void)addShoppingCart:(UIButton *)button
{
    [self.delegate addShopping:button];
}






@end
