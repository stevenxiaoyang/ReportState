//
//  ImagePickerChooseView.m
//  MyFamily
//
//  Created by 陆洋 on 15/7/15.
//  Copyright (c) 2015年 maili. All rights reserved.
//

#import "ImagePickerChooseView.h"
#import "HeaderContent.h"
#import "ImagePickerChooseCell.h"
@interface ImagePickerChooseView()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,weak)UIView *tapView;
@property (nonatomic,weak)UITableView *chooseTableView;
@property (nonatomic,strong)ImagePickerBlock ImagePickerblock;
@end
@implementation ImagePickerChooseView

//一定要这种方式添加背景，不然响应不了tap,还没想清楚为什么
-(id)initWithFrame:(CGRect)frame andAboveView:(UIView *)bgView
{
    self = [super initWithFrame:frame];
    if (self) {
        //初始化背景
        UIView *tapView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,screenWidth, screenHeight)];
        tapView.backgroundColor = [UIColor blackColor];
        tapView.alpha = 0.4;
        tapView.userInteractionEnabled = YES;
        [bgView addSubview:tapView];
        self.tapView = tapView;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(disappear)];
        [self.tapView addGestureRecognizer:tapGesture];
    }
    return self;
}

-(void)addImagePickerChooseView
{
    UITableView *chooseTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    chooseTableView.delegate = self;
    chooseTableView.dataSource = self;
    [self addSubview:chooseTableView];
    self.chooseTableView = chooseTableView;
}

#define IPCViewHeight 120
-(void)disappear
{
    ((UITableView *)self.superview).scrollEnabled = YES;
    [self.tapView removeFromSuperview];
    self.tapView = nil;
    [UIView animateWithDuration:0.25f animations:^{
        self.frame = CGRectMake(0, screenHeight - 64, screenWidth, IPCViewHeight);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - tableview delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImagePickerChooseCell *cell = [ImagePickerChooseCell cellWithTableView:tableView];
    if (indexPath.row == 0) {
        cell.imagePickerName.text =@"拍照";
    }
    else if (indexPath.row == 1)
    {
        cell.imagePickerName.text =@"从手机相册选择";
    }
    else
    {
        cell.imagePickerName.text = @"取消";
    }
    return cell;
}

-(void)setImagePickerBlock:(ImagePickerBlock)block
{
    self.ImagePickerblock = block;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //拍照
    if (indexPath.row == 0) {
        
    }
    //从手机相册选择
    else if (indexPath.row == 1)
    {
        self.ImagePickerblock();
    }
    else
    {
        [self disappear];
    }
}



@end
