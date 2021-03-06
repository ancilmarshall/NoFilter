//
//  AppDelegate.h
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kBackgroundSessionIdentifier;

@class NFPImageManagedObjectContext;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NFPImageManagedObjectContext* managedObjectContext;
@property (nonatomic,assign) BOOL shouldPerformBackgroundTask;
@property (nonatomic,strong) NSDictionary* webAppPlistDictionary;


+ (AppDelegate*) delegate;
- (void)setRootViewControllerWithIdentifier:(NSString*)identifier;

@end

