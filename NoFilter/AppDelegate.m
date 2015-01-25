//
//  AppDelegate.m
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

// This image property can be set by other objects in the application.
// When it is set it can be observed by these other objects using KVO to perform
// some action. For example when user picks image for photo libary or the camera
@property (nonatomic,strong) UIImage* image;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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

// Helper function to get the application delegate
+ (AppDelegate*) getDelegate;
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}
@end
