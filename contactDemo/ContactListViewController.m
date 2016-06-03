//
//  ContactListViewController.m
//  contactDemo
//
//  Created by lihongfeng on 16/6/2.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "ContactListViewController.h"
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import "ViewController.h"

@interface ContactListViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *mainTableView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) NSMutableArray *selectDataSource;

@end

@implementation ContactListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"添加联系人";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"< 返回" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = item;
    
    [self.view addSubview:self.mainTableView];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [self fetchAddressBookOnIOS9AndLater];
    }else{
        [self fetchAddressBookBeforeIOS9];
    }
    
}

- (void)back{
    
    self.selectDataSource = [NSMutableArray array];
    for (NSMutableDictionary *dic in self.dataSource) {
        if ([dic[@"selected"] isEqualToString:@"yes"]) {
            [self.selectDataSource addObject:dic];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataChanged" object:nil userInfo:@{@"info": self.selectDataSource}];
    
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)fetchAddressBookBeforeIOS9{
    ABAddressBookRef addressBook = ABAddressBookCreate();
    //首次访问需用户授权
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {//首次访问通讯录
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (!error) {
                if (granted) {//允许
                    NSLog(@"已授权访问通讯录");
                    NSArray *contacts = [self fetchContactWithAddressBook:addressBook];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //----------------主线程 更新 UI-----------------
                        NSLog(@"contacts:%@", contacts);
                        
                        self.dataSource = [NSMutableArray arrayWithArray:contacts];
                        [self.mainTableView reloadData];
                        
                    });
                }else{//拒绝
                    NSLog(@"拒绝访问通讯录");
                }
            }else{
                NSLog(@"发生错误!");
            }
        });
    }else{//非首次访问通讯录
        NSArray *contacts = [self fetchContactWithAddressBook:addressBook];
        dispatch_async(dispatch_get_main_queue(), ^{
            //----------------主线程 更新 UI-----------------
            NSLog(@"contacts:%@", contacts);
            
            self.dataSource = [NSMutableArray arrayWithArray:contacts];
            [self.mainTableView reloadData];
            
        });
    }
}

- (NSMutableArray *)fetchContactWithAddressBook:(ABAddressBookRef)addressBook{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {////有权限访问
        //获取联系人数组
        NSArray *array = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableArray *contacts = [NSMutableArray array];
        for (int i = 0; i < array.count; i++) {
            //获取联系人
            ABRecordRef people = CFArrayGetValueAtIndex((__bridge ABRecordRef)array, i);
            //获取联系人详细信息,如:姓名,电话,住址等信息
            NSString *firstName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge NSString *)ABRecordCopyValue(people, kABPersonLastNameProperty);
            ABMutableMultiValueRef *phoneNumRef = ABRecordCopyValue(people, kABPersonPhoneProperty);
            NSString *phoneNumber =  ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneNumRef)).lastObject;
            [contacts addObject:[NSMutableDictionary dictionaryWithDictionary:@{@"name": [firstName stringByAppendingString:lastName], @"tel": phoneNumber, @"selected": @"no"}]];
        }
        return contacts;
    }else{//无权限访问
        NSLog(@"无权限访问通讯录");
        return nil;
    }
}

- (void)fetchAddressBookOnIOS9AndLater{
    //创建CNContactStore对象
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    //首次访问需用户授权
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined) {//首次访问通讯录
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!error){
                if (granted) {//允许
                    NSLog(@"已授权访问通讯录");
                    NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //----------------主线程 更新 UI-----------------
                        NSLog(@"contacts:%@", contacts);
                        
                        self.dataSource = [NSMutableArray arrayWithArray:contacts];
                        [self.mainTableView reloadData];
                        
                    });
                }else{//拒绝
                    NSLog(@"拒绝访问通讯录");
                }
            }else{
                NSLog(@"发生错误!");
            }
        }];
    }else{//非首次访问通讯录
        NSArray *contacts = [self fetchContactWithContactStore:contactStore];//访问通讯录
        dispatch_async(dispatch_get_main_queue(), ^{
            //----------------主线程 更新 UI-----------------
            NSLog(@"contacts:%@", contacts);
            
            self.dataSource = [NSMutableArray arrayWithArray:contacts];
            [self.mainTableView reloadData];
            
        });
    }
}

- (NSMutableArray *)fetchContactWithContactStore:(CNContactStore *)contactStore{
    //判断访问权限
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {//有权限访问
        NSError *error = nil;
        //创建数组,必须遵守CNKeyDescriptor协议,放入相应的字符串常量来获取对应的联系人信息
        NSArray <id<CNKeyDescriptor>> *keysToFetch = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey];
        //获取通讯录数组
        NSArray<CNContact*> *arr = [contactStore unifiedContactsMatchingPredicate:nil keysToFetch:keysToFetch error:&error];
        if (!error) {
            NSMutableArray *contacts = [NSMutableArray array];
            for (int i = 0; i < arr.count; i++) {
                CNContact *contact = arr[i];
                NSString *givenName = contact.givenName;
                NSString *familyName = contact.familyName;
                NSString *phoneNumber = ((CNPhoneNumber *)(contact.phoneNumbers.lastObject.value)).stringValue;
                [contacts addObject:[NSMutableDictionary dictionaryWithDictionary:@{@"name": [givenName stringByAppendingString:familyName], @"tel": phoneNumber, @"selected": @"no"}]];
            }
            return contacts;
        }else {
            return nil;
        }
    }else{//无权限访问
        NSLog(@"无权限访问通讯录");
        return nil;
    }
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
    NSMutableDictionary *dic = self.dataSource[indexPath.row];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        [dic setValue:@"yes" forKey:@"selected"];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        [dic setValue:@"no" forKey:@"selected"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [self.mainTableView reloadData];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
