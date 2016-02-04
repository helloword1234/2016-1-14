//
//  YKSFMDBManger.h
//  YueKangSong
//
//  Created by wkx on 15/9/28.
//  Copyright © 2015年 YKS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
@interface YKSFMDBManger : NSObject
{
    
    FMDatabase *fm;

}

@property(nonatomic,strong) NSString *shoppingCarCount;//用来标示角标值的改变值
@property(nonatomic,assign) CGFloat dataCount;//用来标示加入购物车、一键加入购物车、加减号改变药品的数量的值

+(YKSFMDBManger *)shareManger;

-(BOOL)save:(NSDictionary *)dict;

-(NSMutableArray *)loadDataSQL;

-(BOOL)delete:(NSString *)name;

//网络读取购物车药品的数量
-(void)readShoppingCarCount;
//将dataCount的值转为标示角标的值shoppingCarCount
-(void)addShopCount;
//发送通知
-(void)notiscation;


@end
