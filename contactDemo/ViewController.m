//
//  ViewController.m
//  contactDemo
//
//  Created by lihongfeng on 16/6/2.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "ViewController.h"
#import "ContactListViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *mainTableView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"常用联系人";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(pushContactView)];
    self.navigationItem.rightBarButtonItem = item;
    
    self.dataSource = [NSMutableArray arrayWithArray:@[@{@"name": @"张三", @"tel": @"235934589743"},
                                                        @{@"name": @"张四", @"tel": @"2353453"},
                                                        @{@"name": @"张五", @"tel": @"2333389743"}]];
    
    
    [self.view addSubview:self.mainTableView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView:) name:@"dataChanged" object:nil];
    
}

- (void)refreshView:(NSNotification *)noti{
    self.seletedData = [NSMutableArray arrayWithArray:noti.userInfo[@"info"]];
    if (self.seletedData.count > 0) {
        [self.dataSource addObjectsFromArray:self.seletedData];
    }
    [self.mainTableView reloadData];
}

- (void)pushContactView{
    [self.navigationController pushViewController:[[ContactListViewController alloc] init] animated:YES];
}

- (UITableView *)mainTableView{
    if (_mainTableView == nil) {
        UITableView *t = [[UITableView alloc] initWithFrame:self.view.bounds];
        t.delegate = self;
        t.dataSource = self;
        [t registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _mainTableView = t;
    }
    return _mainTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.dataSource removeObjectAtIndex:indexPath.row];
        [self.mainTableView reloadData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [self addSubViewsInCell:cell AtIndexPath:indexPath];
    return cell;
}

- (void)addSubViewsInCell:(UITableViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath{
    
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    UILabel *nameLable = [[UILabel alloc] initWithFrame:CGRectMake(12, 5, 200, 30)];
    NSString *name = self.dataSource[indexPath.row][@"name"];
    nameLable.text = name;
    
    UILabel *telLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 40, 200, 30)];
    NSString *tel = self.dataSource[indexPath.row][@"tel"];
    telLabel.text = tel;
    telLabel.textColor = [UIColor lightGrayColor];
    
    [cell.contentView addSubview:nameLable];
    [cell.contentView addSubview:telLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end








