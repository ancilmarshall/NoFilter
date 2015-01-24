//
//  AppDelegate.m
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic,strong) UIImage* image;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (void) setUserImage:(UIImage *)image;
{
    self.image = image;
}

- (UIImage*)getUserImage;
{
    return self.image;
}

@end
