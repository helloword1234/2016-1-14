//
//  YKSMyCollectVC.m
//  YueKangSong
//
//  Created by gongliang on 15/5/17.
//  Copyright (c) 2015年 YKS. All rights reserved.
//

#import "YKSMyCollectVC.h"
#import "YKSDrugListCell.h"
#import "GZBaseRequest.h"
#import <MJRefresh/MJRefresh.h>
#import "YKSLineView.h"
#import "YKSDrugDetailViewController.h"
#import "YKSUserModel.h"

@interface YKSMyCollectVC () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *datas;
@property (assign, nonatomic) NSInteger page;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLayout;
@property (weak, nonatomic) IBOutlet YKSTopLineView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *allSelectedButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation YKSMyCollectVC

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //取消收藏的背景颜色和用户交互设置
    self.cancelButton.backgroundColor = [UIColor grayColor];
    self.cancelButton.userInteractionEnabled = NO;
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [YKSTools insertEmptyImage:@"other_empty" text:@"你还未收藏过药品" view:self.view];
    
    _datas = [NSMutableArray new];
    _page = 1;
    [self requestDataByPage:_page];
    __weak YKSMyCollectVC *bself = self;
    [self.tableView addLegendHeaderWithRefreshingBlock:^{
        bself.page = 1;
        [bself requestDataByPage:bself.page];
    }];
    [self.tableView addLegendFooterWithRefreshingBlock:^{
        [bself requestDataByPage:bself.page++];
    }];
    self.tableView.footer.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

//上边显示的标语
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view =[[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-30, 30)];
     view.backgroundColor=[UIColor colorWithRed:(15*16+11)/255.0 green:(16*15+9)/255.0 blue:14*16/255.0 alpha:1.0];
    UILabel *lable=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-30, 30)];
    
    lable.textColor=[UIColor colorWithRed:(12*16+14)/255.0 green:(7*16+14)/255.0 blue:(16+13)/255.0 alpha:1.0];
    
    lable.textAlignment=NSTextAlignmentCenter;
    
    lable.font=[UIFont systemFontOfSize:12];
    
    lable.text=@"根据您的地址不同,显示您收藏的药品会有所差异";
    
    [view addSubview:lable];
    return view;
}

#pragma mark - custom
- (void)requestDataByPage:(NSInteger)page {
    [self showProgress];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    //取缓存地址
    NSDictionary *dic=[YKSUserModel shareInstance].currentSelectAddress;
    
    NSString *lat = nil;
    NSString *lng = nil;
    NSString *latAndLng = nil;
    if ( ! ([dic isEqualToDictionary:@{}] || (dic == nil) || ( dic == NULL) ))
    {
        //取缓存地址
        latAndLng = dic[@"community_lat_lng"];
       
    }else{
        //取定位地址
        latAndLng = [[NSUserDefaults standardUserDefaults] objectForKey:@"lat_lng"];
    }
    
    NSArray *ary = [latAndLng componentsSeparatedByString:@","];
    lat = ary[0];
    lng = ary[1];
    
    [GZBaseRequest collectListByPage:page andlat:lat andlng:lng callback:^(id responseObject, NSError *error) {
                                [self hideProgress];
                                if (page == 1) {
                                    if (self.tableView.header.isRefreshing) {
                                        [self.tableView.header endRefreshing];
                                    }
                                } else {
                                    [self.tableView.footer endRefreshing];
                                }
                                if (error) {
                                    [self showToastMessage:@"网络加载失败"];
                                    return ;
                                }
                                if (ServerSuccess(responseObject)) {
                                    
                                    NSDictionary *dic = responseObject[@"data"];
                                    if (dic.count == 1) {
                                        _datas = nil;
     　　　　　　　　　　　　　　　　　　　　  } else {
                                        if ([dic isKindOfClass:[NSDictionary class]] && dic[@"glist"]) {
                                            if (page == 1) {
                                                _datas = [responseObject[@"data"][@"glist"] mutableCopy];
                                                
                                            } else {
                                                [_datas addObjectsFromArray:responseObject[@"data"][@"glist"]
                                                 
                                                 ];
                                            }
                                            if ([dic[@"totle"] integerValue] == _datas.count) {
                                                self.tableView.footer.hidden = YES;
                                            } else {
                                                self.tableView.footer.hidden = NO;
                                            }
                                        }
                                    }
                                } else {
                                    [self showToastMessage:responseObject[@"msg"]];
                                }
                                
                                if (_datas.count > 0) {
                                    self.tableView.hidden = NO;
                                    self.navigationItem.rightBarButtonItem.enabled = YES;
                                    [self.tableView reloadData];
                                } else {
                                    self.tableView.hidden = YES;
                                }
                            }];
}

#pragma mark - IBOutlets
- (IBAction)edit:(UIBarButtonItem *)sender {
    if (self.tableView.editing) {
        [sender setTitle:@"编辑"];
        self.bottomLayout.constant = 0.f;
        self.bottomView.hidden = YES;
        [self.tableView setEditing:NO animated:YES];
    } else {
        [sender setTitle:@"完成"];
        self.bottomView.hidden = NO;
        self.bottomLayout.constant = 50.0f;
        [self.tableView setEditing:YES animated:YES];
        
        //取消收藏的背景颜色和用户交互的设置，全选默认为no
        self.cancelButton.backgroundColor = [UIColor grayColor];
        self.cancelButton.userInteractionEnabled = NO;
        self.allSelectedButton.selected = NO;
    }
}

- (IBAction)selectAllAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        //取消收藏的背景颜色和用户交互的设置
        self.cancelButton.backgroundColor = [UIColor redColor];
        self.cancelButton.userInteractionEnabled = YES;
        for (int i = 0; i < self.datas.count; i++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    } else {
        //取消收藏的背景颜色和用户交互的设置
        self.cancelButton.backgroundColor = [UIColor grayColor];
        self.cancelButton.userInteractionEnabled = NO;
        for (int i = 0; i < self.datas.count; i++) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
        }
    }
}

- (IBAction)cancelCollectAction:(id)sender {
    NSArray *array = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *gids = [NSMutableArray new];
    for (NSIndexPath *indexPath in array) {
        [gids addObject:self.datas[indexPath.row][@"gid"]];
    }
    NSLog(@"gids = %@", gids);
    
    [GZBaseRequest deleteCollectByGid:[gids componentsJoinedByString:@","]
                             callback:^(id responseObject, NSError *error) {
                                 if (error) {
                                     [self showToastMessage:@"网络加载失败"];
                                     return ;
                                 }
                                 if (ServerSuccess(responseObject)) {
                                     [self edit:self.navigationItem.rightBarButtonItem];
                                     [self requestDataByPage:1];
                                 } else {
                                     [self showToastMessage:responseObject[@"msg"]];
                                 }
                                 
                             }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKSDrugListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"drugList" forIndexPath:indexPath];
    
    cell.drugInfo = self.datas[indexPath.row];
    
    cell.multipleSelectionBackgroundView = [UIView new];
    //    UIView *selectView = [UIView new];
    //    selectView.backgroundColor = [UIColor clearColor];
    //    cell.selectedBackgroundView = selectView;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        //取消收藏的背景颜色和用户交互的设置
        self.cancelButton.backgroundColor = [UIColor redColor];
        self.cancelButton.userInteractionEnabled = YES;
        
        NSArray *array = [self.tableView indexPathsForSelectedRows];
        _allSelectedButton.selected = (array.count == _datas.count);
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        YKSDrugDetailViewController *vc = [mainBoard instantiateViewControllerWithIdentifier:@"YKSDrugDetailViewController"];
        vc.drugInfo = _datas[indexPath.row];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        NSArray *array = [self.tableView indexPathsForSelectedRows];
        _allSelectedButton.selected = (array.count == _datas.count);
        
        //判断若有选中的收藏的商品
        if (array.count != 0) {
            //取消收藏的背景颜色和用户交互的设置
            self.cancelButton.backgroundColor = [UIColor redColor];
            self.cancelButton.userInteractionEnabled = YES;
            
        }else
        {
            //取消收藏的背景颜色和用户交互的设置
            self.cancelButton.backgroundColor = [UIColor grayColor];
            self.cancelButton.userInteractionEnabled = NO;
            
        }
        

    }
}


@end
