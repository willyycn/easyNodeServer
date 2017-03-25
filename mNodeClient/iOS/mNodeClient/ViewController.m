//
//  ViewController.m
//  mNodeClient
//
//  Created by willyy on 2017/2/27.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "ViewController.h"
#import "NetworkHandler.h"
@interface ViewController ()
{
    __weak IBOutlet UITextView *monitorText;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginByAuthcode:(id)sender {
    NSDictionary *dic = @{@"username":@"willyy",@"authcode":@"7788"}.copy;
    [[NetworkHandler sharedHandler]Login:dic withHandler:^(NSDictionary *res, NSError *error) {
        if (res) {
            NSLog(@"res %@",res);
            NSString *str = monitorText.text;
            str = [[[res description] stringByAppendingString:@"\n"] stringByAppendingString:str];
            ;
            [monitorText setText:str];
        }
    }];
}
- (IBAction)loginByPassword:(id)sender {
    NSDictionary *dic = @{@"username":@"willyy",@"password":@"pass123"}.copy;
    [[NetworkHandler sharedHandler]Login:dic withHandler:^(NSDictionary *res, NSError *error) {
        if (res) {
            NSLog(@"res %@",res);
            NSString *str = monitorText.text;
            str = [[[res description] stringByAppendingString:@"\n"] stringByAppendingString:str];
            ;
            [monitorText setText:str];
        }
    }];
}

- (IBAction)sayHello:(id)sender {
    NSDictionary *dic = @{@"hello":@"willyy"}.copy;
    NSDate *now = [NSDate date];
    __block NSInteger i = now.timeIntervalSince1970;
    [[NetworkHandler sharedHandler]postHello:dic withHandler:^(NSDictionary *res, NSError *error) {
        if (res) {
            NSLog(@"respone in %f s",[NSDate date].timeIntervalSince1970 - i);
            NSLog(@"res %@",res);
            NSString *str = monitorText.text;
            str = [[[res description] stringByAppendingString:@"\n"] stringByAppendingString:str];
            ;
            [monitorText setText:str];
        }
        if (error) {
            NSLog(@"error %@",error);
        }
    }];
}

@end
