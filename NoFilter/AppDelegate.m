//
//  AppDelegate.m
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "NFPImageManagedObjectContext.h"

@interface AppDelegate ()

// This image property can be set by other objects in the application.
// When it is set it can be observed by these other objects using KVO to perform
// some action. For example when user picks image for photo libary or the camera
@property (nonatomic,strong) UIImage* image;
@end

@implementation AppDelegate

#pragma mark - Initialization

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.managedObjectContext = [NFPImageManagedObjectContext contextForStoreAtURL:[self SQLiteStoreURL]];
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Failed to seed random color data: %@", error);
    }
    return YES;
}

#pragma mark - userImage Accessor methods
- (void) setUserImage:(UIImage *)image;
{
    self.image = image;
}

- (UIImage*)getUserImage;
{
    return self.image;
}

#pragma mark - Shared AppDelegate helper function
+ (AppDelegate*) delegate;
{
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    NSAssert([delegate isKindOfClass:[AppDelegate class]], @"Expected to use our app delegate class");
    return (AppDelegate *)delegate;

}

# pragma mark - CoreData helper functions
- (NSURL *)SQLiteStoreURL;
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSAssert([URLs count] > 0, @"Expected to find a document URL");
    NSURL *documentDirectory = URLs[0];
    return [[documentDirectory URLByAppendingPathComponent:@"tasks"] URLByAppendingPathExtension:@"sqlite"];
}


@end
