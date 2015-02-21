//
//  AppDelegate.m
//  NoFilter
//
//  Created by Ancil on 1/16/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "NFPImageManagedObjectContext.h"

#if 1 && defined(DEBUG)
#define APP_DELEGATE_DEBUG_LOG(format, ...) NSLog(@"OPERATION: " format, ## __VA_ARGS__)
#else
#define APP_DELEGATE_DEBUG_LOG(format, ...)
#endif

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
    
    
    NSURL* webAppPlistURL = [[NSBundle mainBundle] URLForResource:@"NoFilterWebApp" withExtension:@"plist"];
    self.webAppPlistDictionary = [NSDictionary dictionaryWithContentsOfURL:webAppPlistURL];
    
    NSURL* serverBaseURL = [NSURL URLWithString:@"http://nofilter.pneumaticsystem.com/api/v1"];
    
    return YES;
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
