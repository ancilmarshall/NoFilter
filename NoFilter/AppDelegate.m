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
    
    self.isAppPerformingTasks = NO;
    self.backgroundOperationTask = UIBackgroundTaskInvalid;
    [self addIsGeneratingThumbnailObserver];
    
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
    if (self.isAppPerformingTasks) {
        NSAssert(self.backgroundOperationTask == UIBackgroundTaskInvalid, @"Should never take out two BG tasks for the one queue");
        
        self.backgroundOperationTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:self.backgroundOperationTask];
            self.backgroundOperationTask = UIBackgroundTaskInvalid;
        }];
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application;
{
    if (self.backgroundOperationTask != UIBackgroundTaskInvalid) {
        [application endBackgroundTask:self.backgroundOperationTask];
        self.backgroundOperationTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark -  KVO on isGeneratingThumbnail
static NSUInteger kIsGeneratingObserverContext;
-(void)addIsGeneratingThumbnailObserver;
{
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(isAppPerformingTasks))
              options:NSKeyValueObservingOptionNew
              context:&kIsGeneratingObserverContext];

}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    NSParameterAssert([object isKindOfClass:[AppDelegate class]]);
    NSParameterAssert([keyPath isEqualToString:NSStringFromSelector(@selector(isAppPerformingTasks))]);
    
    if (!self.isAppPerformingTasks)
    {
        if (self.backgroundOperationTask != UIBackgroundTaskInvalid){
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundOperationTask];
            self.backgroundOperationTask = UIBackgroundTaskInvalid;

        }
    }
    
}

-(void)removeIsGeneratingThumbnailObserver;
{
    [self removeObserver:self
              forKeyPath:NSStringFromSelector(@selector(isAppPerformingTasks))
                 context:&kIsGeneratingObserverContext];
    
}


#pragma mark - clean up
-(void)dealloc;
{
    [self removeIsGeneratingThumbnailObserver];
}

@end
