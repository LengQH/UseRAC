//
//  ViewController.m
//  UseRAC
//
//  Created by 冷求慧 on 2017/7/14.
//  Copyright © 2017年 冷求慧. All rights reserved.
//

#import "ViewController.h"

@interface Dog : NSObject
/**
 *  狗的名字属性
 */
@property (nonatomic,copy)NSString  *dogName;
/**
 *  狗的食物属性
 */
@property (nonatomic,copy)NSString  *dogFood;

@end

@implementation Dog
@end

@interface ViewController (){
    Dog *dog;
}
/**
 *  头部背景视图
 */
@property (weak, nonatomic) IBOutlet UIView *headBGView;
/**
 *  账号输入框
 */
@property (weak, nonatomic) IBOutlet UITextField *accountTextField;
/**
 *  密码输入框
 */
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
/**
 *  登录按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self someUISet];   // 一些UI设置
    
//    [self startRAC];
}
#pragma mark 一些UI设置
-(void)someUISet{
    self.loginButton.layer.cornerRadius=6.0;
    self.loginButton.layer.masksToBounds=YES;
}
#pragma mark 开始RAC
-(void)startRAC{
    
    // 简单的了解信号 订阅 和发送信号
    RACSignal *racSig=[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {  // 1.0  创建一个 RACSignal 信号对象
        
        [subscriber sendNext:@"发送信号"];  // 3.0 发送成功信号信息
        
        [subscriber sendError:nil];   // 发送错误信号信息
        
        [subscriber sendCompleted];   // 发送操作完成信号信息
    
        return [RACDisposable disposableWithBlock:^{   // 执行完Block后，当前信号就不在被订阅了。
             NSLog(@"信号被销毁");
        }];
    }];
    [racSig subscribeNext:^(id  _Nullable x) {    // 2.0  订阅成功信号,执行操作
        NSLog(@"订阅中接收到的信号值是:【%@】",(NSString *)x);
    }];
    [racSig subscribeError:^(NSError * _Nullable error) {  // 订阅错误信号,执行操作
        NSLog(@"得到的错误信息是:%@ ",error);
    } completed:^{
        NSLog(@"错误信息完成！！！");
    }];
    [racSig subscribeCompleted:^{                 // 订阅完成操作信号,执行操作
        NSLog(@"一个整个完整的过程执行完毕！！！");
    }];

    // 1.0 属性监听(KVO)
    dog=[[Dog alloc]init];
    
    [RACObserve(dog,dogName) subscribeNext:^(id  _Nullable x) {
        NSLog(@"宏定义里面的输出值:%@",(NSObject *)x);
    }];
    [[dog rac_valuesForKeyPath:@"dogName" observer:nil] subscribeNext:^(id  _Nullable x) {
        NSLog(@"正常里面的值:%@",(NSObject *)x);
    }];
    
    
    // 2.0 手势监听
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]init];
    [self.headBGView addGestureRecognizer:tapGesture];
    
    [[tapGesture rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        NSLog(@"单击了头视图");
    }];
    
    
    // 3.0 监听通知
    static NSString *notifaName=@"notifaNameWithTest";
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:notifaName object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"RAC 通知的监听");
    }];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:notifaName object:nil];   // 发送一个通知
    
    // 4.0 监听定时器
    [[RACSignal interval:2.0 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"RAC定时器 两秒调用一次");
    }];
    
    
    // 5.0 监听UIButton事件
    [[self.loginButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        UIButton *login=(UIButton *)x;
        NSLog(@"点击了按钮:%@",login);
    }];
    
    
    // 6.0 监听UITextFiled
    [[self.accountTextField rac_textSignal] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"账号输入框里面输入的值:%@",(NSObject *)x);
    }];
    [[self.accountTextField rac_signalForControlEvents:UIControlEventEditingDidEndOnExit] subscribeNext:^(__kindof UIControl * _Nullable x) {       // 监测对应的状态改变
        UITextField *inoutField=(UITextField *)x;
        NSLog(@"按了Return键 返回的值是:%@",inoutField.text);
    }];

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    dog.dogName=@"🐶东西";
    [self.view endEditing:YES];
}

@end
