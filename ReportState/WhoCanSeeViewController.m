//
//  WhoCanSeeViewController.m
//  MyFamily
//
//  Created by 陆洋 on 15/7/14.
//  Copyright (c) 2015年 maili. All rights reserved.
//

#import "WhoCanSeeViewController.h"
#import "UITableView+Improve.h"
#import "UIImage+ReSize.h"
@interface WhoCanSeeViewController ()

@end

@implementation WhoCanSeeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"谁可以看";
    
    //nav右边发布按钮
    UIButton *finishButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    finishButton.frame = CGRectMake(0, 0, 30, 20);
    [finishButton setTitle:@"完成" forState:normal];
    [finishButton addTarget:self action:@selector(finishWhoCanSee:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *finishButtonItem = [[UIBarButtonItem alloc] initWithCustomView:finishButton];
    self.navigationItem.rightBarButtonItem = finishButtonItem;
    
    [self.tableView improveTableView];
    [self.tableView setBackgroundColor:[UIColor colorWithRed:246.0/255 green:247.0/255 blue:247.0/255 alpha:1]];

}

-(void)finishWhoCanSee:(id)sender
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"WhoCanSee";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.detailTextLabel.textColor = [UIColor colorWithRed:152/255.0 green:152/255.0 blue:152/255.0 alpha:1];
    cell.imageView.image = [[UIImage imageNamed:@"choose"] reSizeImagetoSize:CGSizeMake(20, 20)];
    cell.imageView.hidden = YES;

    if (indexPath.row == 0) {
        cell.textLabel.text = @"公开";
        cell.detailTextLabel.text = @"所有朋友可见";
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = @"私密";
        cell.detailTextLabel.text = @"仅自己可见";
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = @"部分可见";
        cell.detailTextLabel.text = @"选中的朋友可见";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.textLabel.text = @"不给谁看";
        cell.detailTextLabel.text = @"选中的朋友不可见";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView reloadData]; //数据不多，直接reloadData消除已有的勾
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.hidden = NO;
}

@end
