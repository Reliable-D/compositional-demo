//
//  ViewController.m
//  compositional-demo
//
//  Created by dengle on 2025/10/31.
//

#import "ViewController.h"
#import "CPDCompositionalLayoutController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    UIButtonConfiguration *btnConfig = [UIButtonConfiguration plainButtonConfiguration];
    btnConfig.title = @"Compositional Layout";
    btnConfig.baseForegroundColor = [UIColor redColor];
//    btnConfig.baseBackgroundColor = [UIColor blackColor];
    btnConfig.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    btnConfig.buttonSize = UIButtonConfigurationSizeMedium;
    UIAction *handlerAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        CPDCompositionalLayoutController *vc = [CPDCompositionalLayoutController new];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    UIButton *btn = [UIButton buttonWithConfiguration:btnConfig primaryAction:handlerAction];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:btn];
    [NSLayoutConstraint activateConstraints:@[
        [btn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:0],
        [btn.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:0],
    ]];
}


@end
