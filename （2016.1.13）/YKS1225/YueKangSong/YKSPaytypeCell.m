//
//  YKSPaytypeCell.m
//  YueKangSong
//
//  Created by 范 on 15/12/25.
//  Copyright © 2015年 YKS. All rights reserved.
//

#import "YKSPaytypeCell.h"
@interface YKSPaytypeCell()

@end




@implementation YKSPaytypeCell

-(UIButton *)btn
{
    if (!_btn)
    {
        _btn = [UIButton buttonWithType:UIButtonTypeSystem];
        _btn.frame=CGRectMake(SCREEN_WIDTH-22-25, 15, 17, 17);
    }
    return _btn;
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
