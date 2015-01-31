//
//  NFPDebugViewController.m
//  NoFilter
//
//  Created by Ancil on 1/25/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPDebugViewController.h"

@interface NFPDebugViewController ()
@property (weak, nonatomic) IBOutlet UIButton *regenerateButton;
@property (weak, nonatomic) IBOutlet UIButton *clearAllButton;
@end

static const float kCornerRadiusRatio = 0.4;

@implementation NFPDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Debug Menu",nil);
    self.regenerateButton.layer.cornerRadius = kCornerRadiusRatio*self.regenerateButton.bounds.size.height;
    self.clearAllButton.layer.cornerRadius = kCornerRadiusRatio*self.clearAllButton.bounds.size.height;
}


- (IBAction)dismssMe:(id)sender;
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
