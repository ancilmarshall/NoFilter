//
//  AppDelegate.h
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NFPImageManagedObjectContext;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NFPImageManagedObjectContext* managedObjectContext;
+ (AppDelegate*) delegate;
@property (nonatomic,assign) BOOL isGeneratingThumbnail;

@end

