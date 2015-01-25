//
//  AppDelegate.h
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void) setUserImage:(UIImage*)image;
- (UIImage*) getUserImage;
+ (AppDelegate*) getDelegate;

@end

