//
//  YKSFMDBManger.m
//  YueKangSong
//
//  Created by wkx on 15/9/28.
//  Copyright © 2015年 YKS. All rights reserved.
//

#import "YKSFMDBManger.h"
#import "GZBaseRequest.h"

static YKSFMDBManger *manager=nil;

@implementation YKSFMDBManger

+(YKSFMDBManger *)shareManger{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[YKSFMDBManger alloc]init];
    });
    \
    return manager;

}



-(BOOL)update:(NSDictionary *)dict{
    
    return NO;

}

-(instancetype)init{


    
    if (self=[super init]) {
        
        fm=[[FMDatabase alloc]initWithPath:[NSString stringWithFormat:@"%@/Documents/data.db",NSHomeDirectory()]];
        
    }
    if ([fm open]) {
        [fm executeUpdate:@"create table coupon(name,canBeUsed,canBeUsedButNot,beUsed)"];
    }
    
    return self;
}

-(BOOL)save:(NSDictionary *)dict{

    if (dict[@"name"]!=nil) {
        return  [fm executeUpdate:@"indert into coupon values (?,?,?,?)",dict[@"name"],dict[@"canBeUsed"],dict[@"canBeUsedButNot"],dict[@"beUsed"]];
        
    }
    
    return NO;

}

-(BOOL)delete:(NSString *)name{

    return [fm executeUpdate:@"delete from coupon where name =?",name];

}


-(NSMutableArray *)loadDataSQL{

    FMResultSet *result=[fm executeQuery:@"select * from coupon"];
    
    NSMutableArray *dataArray=[NSMutableArray array];
    
    while ([result next]) {
        
        
        NSString *name=[result stringForColumn:@"name"];
        
        NSString *canBeUsed=[result stringForColumn:@"canBeUsed"];
        
        NSString *canBeUsedButNot=[result stringForColumn:@"canBeUsedButNot"];
        
        NSString *beUsed=[result stringForColumn:@"beUsed"];
        
        [dataArray addObject:@{@"name":name,@"beUsed":canBeUsed,@"canBeUsedButNot":canBeUsedButNot,@"beUsed":beUsed}];
        
    }
    
    return  dataArray;

}


//网络读取购物车药品的数量
-(void)readShoppingCarCount
{
    //网络读取购物车的商品
    [GZBaseRequest shoppingcartListCallback:^(id responseObject, NSError *error) {
        NSDictionary *dic = [responseObject objectForKey:@"data"];
        NSArray *dataArray = [dic objectForKey:@"list"];
        
        CGFloat totalCount = 0;
        //循环遍历购物车药品数组
        for (NSDictionary *data in dataArray) {
            //获取药品的数量
            CGFloat dataCount = [[data objectForKey:@"gcount"] integerValue];
            //累计相加，则是后台购物车药品的总数
            totalCount = totalCount + dataCount;
        }
        NSString *total = [NSString stringWithFormat:@"%.0f",totalCount];
        self.shoppingCarCount = total;
        
    }];
    
}


//将dataCount的值转为标示角标的值shoppingCarCount
-(void)addShopCount
{
    NSString *total = [NSString stringWithFormat:@"%.0f",_dataCount];
    self.shoppingCarCount = total;
    
}


//发送通知
-(void)notiscation
{
    //通知传值
    NSDictionary *dica = [[NSDictionary alloc] initWithObjectsAndKeys:_shoppingCarCount,@"count", nil];
    NSNotification *notification = [NSNotification notificationWithName:@"tongzhi" object:nil userInfo:dica];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}





@end
