//
//  RootViewController.m
//  YYTest_ws
//
//  Created by great Lock on 2018/2/1.
//  Copyright © 2018年 great Lock. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *classNames;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configSubViews];
    [self configSourceData];
}

#pragma mark -
#pragma mark - layout
- (void)configSubViews {
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        [self.view addSubview:tableView];
        tableView;
    });
}

- (void)configSourceData {
    [self addCell:@"model" className:@"WSModelExample"];
    [self addCell:@"image" className:@"WSImageExample"];
    
    [_tableView reloadData];
}

#pragma mark -
#pragma mark - other
- (void)addCell:(NSString *)cellName className:(NSString *)className {
    [self.titles addObject:cellName];
    [self.classNames addObject:className];
}

#pragma mark -
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *className = self.classNames[indexPath.row];
    Class class = NSClassFromString(className);
    UIViewController *viewController = [[class alloc] init];
    [self.navigationController pushViewController:viewController animated:true];
}

#pragma mark -
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.titles[indexPath.row];
    return cell;
}

#pragma mark -
#pragma mark - getter and setter
- (NSMutableArray *)titles {
    if (_titles == nil) {
        _titles = [NSMutableArray array];
    }
    return _titles;
}

- (NSMutableArray *)classNames {
    if (_classNames == nil) {
        _classNames = [NSMutableArray array];
    }
    return _classNames;
}

@end
