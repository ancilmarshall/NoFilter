//
//  AppDelegate.m
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "NFPImageManagedObjectContext.h"
#import "NFPServerManager.h"

#if 0 && defined(DEBUG)
#define APP_DELEGATE_DEBUG_LOG(format, ...) NSLog(@"OPERATION: " format, ## __VA_ARGS__)
#else
#define APP_DELEGATE_DEBUG_LOG(format, ...)
#endif

extern NSString* const kUserDefaultUsername;
extern NSString* const kUserDefaultRememberLogin;

NSString* const kBackgroundSessionIdentifier = @"BackgroundSessionIdentifier";

@interface AppDelegate ()
@property (atomic,assign) UIBackgroundTaskIdentifier backgroundOperationTask;
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
    
    self.shouldPerformBackgroundTask = NO;
    self.backgroundOperationTask = UIBackgroundTaskInvalid;
    [self registerShouldPerformBackgroundTaskObserver];
    
    self.window.backgroundColor = [UIColor clearColor];
    [self setRootViewControllerWithIdentifier:@"NFPLoginViewController"];
    
    //setup user defaults and register with notification center to synchronize
    [[NSUserDefaults standardUserDefaults]
         registerDefaults:@{kUserDefaultUsername:@"",
                            kUserDefaultRememberLogin:@(NO)}];
    
    [[NSNotificationCenter defaultCenter]
         addObserverForName:NSUserDefaultsDidChangeNotification
         object:[NSUserDefaults standardUserDefaults]
         queue:[NSOperationQueue mainQueue]
         usingBlock:^(NSNotification *note)
         {
             [[NSUserDefaults standardUserDefaults] synchronize];
         }
     ];
    
    
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
    [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
    
    return YES;
}

/*
 * This function is called by the system when it wakes up our app into the background
 * to handle some background url session. The system actually passes us the completion
 * handler so that we can call it when we are finished, which in turn calls the system
 * to let it know we are finished. Its a hook back into the system.
 */

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
{
    NSLog(@"Application awoken to handle background url session task");
    
    //ensure that we are waken up with the correct identifier.
    NSParameterAssert([identifier isEqualToString:kBackgroundSessionIdentifier]);
    
    //create the same background session with this identifier.
    [[NFPServerManager sharedInstance] createBackgroundDownloadSessionIfNeeded];
    
    //hold on to the completion handler for later use, since we are not ready yet
    [NFPServerManager sharedInstance].backgroundDownloadCompletionHandler = completionHandler;
}

#pragma mark - Shared AppDelegate helper function
+ (AppDelegate*) delegate;
{
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    NSAssert([delegate isKindOfClass:[AppDelegate class]], @"Expected to use our app delegate class");
    return (AppDelegate *)delegate;

}

- (void)setRootViewControllerWithIdentifier:(NSString*)identifier;
{
    //add the new view controller
    UIStoryboard* storyboad = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController* navController = [storyboad instantiateViewControllerWithIdentifier:identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [((UINavigationController*)self.window.rootViewController) pushViewController:navController.topViewController animated:YES];
    
        if ([identifier isEqualToString:@"NFPLoginViewController"]){
            [((UINavigationController*)self.window.rootViewController)
                setViewControllers:@[navController.topViewController] animated:NO];
            
        } else {
            [((UINavigationController*)self.window.rootViewController)
                setViewControllers:@[navController.topViewController] animated:YES];
        }
        
    });
  
}

# pragma mark - CoreData helper functions
- (NSURL *)SQLiteStoreURL;
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSAssert([URLs count] > 0, @"Expected to find a document URL");
    NSURL *documentDirectory = URLs[0];
    return [[documentDirectory URLByAppendingPathComponent:@"tasks"] URLByAppendingPathExtension:@"sqlite"];
}

# pragma mark - Background tasks
-(void)applicationDidEnterBackground:(UIApplication *)application;
{
    APP_DELEGATE_DEBUG_LOG(@"Application did enter background");
    
    if (self.shouldPerformBackgroundTask) {
        NSAssert(self.backgroundOperationTask == UIBackgroundTaskInvalid, @"Should never take out two BG tasks for the one queue");
        
        APP_DELEGATE_DEBUG_LOG(@"Starting background task");
        self.backgroundOperationTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [self endBackgroundTaskIfNecessary];
        }];
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application;
{
    APP_DELEGATE_DEBUG_LOG(@"Application did become active");
    [self endBackgroundTaskIfNecessary];
}

-(void)endBackgroundTaskIfNecessary;
{
    if (self.backgroundOperationTask != UIBackgroundTaskInvalid) {
        APP_DELEGATE_DEBUG_LOG(@"Ending background task");
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundOperationTask];
        self.backgroundOperationTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark -  KVO on shouldPerformBackgroundTask

static NSUInteger ShouldPerformBackgroundTaskContext;
-(void)registerShouldPerformBackgroundTaskObserver;
{
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(shouldPerformBackgroundTask))
              options:NSKeyValueObservingOptionNew
              context:&ShouldPerformBackgroundTaskContext];

}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    NSParameterAssert(object == self);
    NSParameterAssert(context == &ShouldPerformBackgroundTaskContext);
    NSParameterAssert([keyPath isEqualToString:NSStringFromSelector(@selector(shouldPerformBackgroundTask))]);
    
    if (!self.shouldPerformBackgroundTask )
    {
        [self endBackgroundTaskIfNecessary];
    }
}

-(void)unregisterShouldPerformBackgroundTaskObserver;
{
    [self removeObserver:self
              forKeyPath:NSStringFromSelector(@selector(shouldPerformBackgroundTask))
                 context:&ShouldPerformBackgroundTaskContext];
    
}


#pragma mark - clean up
-(void)dealloc;
{
    [self unregisterShouldPerformBackgroundTaskObserver];
}

@end
