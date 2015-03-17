//
//  TodayViewController.m
//  NoFilterTodayExtension
//
//  Created by Ancil on 3/17/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>
@property (nonatomic,strong) NSUserDefaults* appGroupUserDefaults;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:
                                 @"group.Ancil-Marshall.NoFilter"];
    
}

-(IBAction)imageTapped:(id)gesture{
    
    [self.extensionContext openURL:[NSURL URLWithString:@"nofilter://"] completionHandler:nil];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    
    NSData* imageData = (NSData*)[self.appGroupUserDefaults objectForKey:@"sharedKey"];
    UIImage* image = [UIImage imageWithData:imageData];
    self.imageView.image = image;
    
    completionHandler(NCUpdateResultNewData);
}

@end
