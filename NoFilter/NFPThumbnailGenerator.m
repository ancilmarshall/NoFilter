//
//  NFPThumbnailGenerator.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "NFPImageManagedObjectContext.h"
#import "NFPThumbnailGenerator.h"
#import "NFPImageData.h"
#import "NFPImageData+NFPExtension.h"
#import "NFPThumbnailOperation.h"
#import "BatchUpdateManager.h"
#import "NFPServerManager.h"

@interface NFPThumbnailGenerator()  <NSFetchedResultsControllerDelegate>

-(instancetype)initSingleton NS_DESIGNATED_INITIALIZER;

@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@property (nonatomic,strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic,strong) BatchUpdateManager* batchUpdateManager;
@property (nonatomic,strong) NFPImageManagedObjectContext* managedObjectContext;
@property (nonatomic,strong) NSManagedObjectContext* childContext;
@property (nonatomic,strong) NSManagedObjectContext* uploadContext;
@end

@implementation NFPThumbnailGenerator

#pragma mark - Initialization

+(instancetype) sharedInstance;
{
    static NFPThumbnailGenerator* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NFPThumbnailGenerator alloc] initSingleton];
    });
    return instance;
}

-(instancetype)initSingleton;
{
    self = [super init];
    if (self){
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc]
                             initWithEntityName:NSStringFromClass([NFPImageData class])];
        fetchRequest.sortDescriptors =
            @[ [NSSortDescriptor
                sortDescriptorWithKey:NSStringFromSelector(@selector(dateCreated))
                            ascending:YES] ];
        //fetchRequest.fetchLimit = 1;
        
        self.managedObjectContext = [[AppDelegate delegate] managedObjectContext];
        self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.childContext.parentContext = self.managedObjectContext;
        
        //aim to observe the changes to core data model after the upload has been completed, so do this
        // on a background context, and don't necessarily want to be observed by the fetchedManagedController
        // since don't need to update the UI after the upload is complete. Only the returned image_id
        // from the server needs to be updated into the Core Data model
        self.uploadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.uploadContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
        
//        [[NSNotificationCenter defaultCenter]
//         addObserverForName: NSManagedObjectContextDidSaveNotification
//                     object:self.childContext
//                     queue:[[NSOperationQueue alloc] init]
//            usingBlock:^(NSNotification *note) {
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.managedObjectContext  mergeChangesFromContextDidSaveNotification:note];
//                });
//                
//                //[self printObjectsInContext:self.uploadContext name:@"Upload Context"];
//                
//            }];

        self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                         initWithFetchRequest:fetchRequest
                                         managedObjectContext:self.managedObjectContext
                                         sectionNameKeyPath:nil
                                         cacheName:nil];
        
        self.fetchedResultsController.delegate = self;
        
//        NSUInteger cnt = [self.managedObjectContext countForFetchRequest:fetchRequest error:nil];
//        NSLog(@"Count for Fetch Request %tu",cnt);
        
        //TODO: Perform fetches in the background and in batches
        // Update the main context and call the delegate after updating the context
        // Show an activity wheel stating that photos are updating
        // Allow UI user interactivity, ie don't let the UI get unresponsive
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError* error;
            if (![self.fetchedResultsController performFetch:&error]) {
                NSLog(@"Failed to perform initial fetch: %@", error);
            }
            
            NSArray* objects = [self.fetchedResultsController fetchedObjects];
            for (NSUInteger i=0; i<[objects count]; i++) {
                NSIndexPath* path = [NSIndexPath indexPathForItem:i inSection:0];
                [self.batchUpdateManager.insertArray addObject:path];
            }
            [self.delegate performBatchUpdatesForManager:self.batchUpdateManager];
            self.batchUpdateManager = nil;
            
            // TODO: remove
            //[self printObjectsInContext:self.managedObjectContext name:@"Main Context"];
            
        });
        
        // add KVO observer on the thumbnailGeneratorQueue
        [self addQueueObserver];
        
    }
    return self;
}


-(NSOperationQueue*)thumbnailGeneratorQueue;
{
    if (!_thumbnailGeneratorQueue){
        _thumbnailGeneratorQueue = [NSOperationQueue new];
        _thumbnailGeneratorQueue.maxConcurrentOperationCount = 2;
        _thumbnailGeneratorQueue.name = @"NFPThumbnailGeneratorQueue";
    }
    return _thumbnailGeneratorQueue;
}

-(BatchUpdateManager*)batchUpdateManager;
{
    if (!_batchUpdateManager){
        _batchUpdateManager = [BatchUpdateManager new];
    }
    return _batchUpdateManager;
}

#pragma mark - Accessor methods

-(UIImage*)thumbnailAtIndex:(NSUInteger)index;
{
    if ([[self imageDataAtIndex:index] hasThumbnail]){
        return [[self imageDataAtIndex:index] thumbnail];
    }
    else {
        [self startThumbnailGeneration:[self imageDataAtIndex:index]];
        return nil;
    }
}

-(NFPImageData*)imageDataAtIndex:(NSUInteger)index;
{
    return [self.fetchedResultsController
            objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

-(void)addImage:(UIImage *)image;
{
    NFPImageData* imageData = [NFPImageData addImage:image context:self.managedObjectContext]; //child or managedObject Context
    [[NFPServerManager sharedInstance] uploadImage:imageData context:self.childContext]; //child or upload context
}

-(void)addDownloadedImage:(UIImage*)image withID:(NSUInteger)imageID;
{
    NFPImageData* imageData = [NFPImageData addImage:image context:self.managedObjectContext]; //child or managedObject Context
    imageData.imageID = imageID;
}

-(NSUInteger)count;
{
    return [[self.fetchedResultsController sections][0] numberOfObjects] ;
}

-(NSArray*)allImageIDs;
{
    NSArray* allObjects = [self.fetchedResultsController fetchedObjects];
    NSMutableArray* ids = [NSMutableArray new];

    for (NFPImageData* imageData in allObjects) {
        //use only id's that are not zero as this function could be called
        //asynchronously from the upload to the server (when the id is returned)
        if (imageData.imageID >0){
            [ids addObject:@(imageData.imageID)];
        }
    }
    return [NSArray arrayWithArray:ids];
}

#pragma mark - NSFetchedResultsControllerDelegate
/*
 *  NSFetchedResultsController responds to changes in its context through
 *  this delegate. Changes such as additions, deletions, updates etc are observed
 *  here.
 */
-(void) controllerWillChangeContent:(NSFetchedResultsController *)controller;
{
}

- (void)controller:(NSFetchedResultsController *)controller
                           didChangeObject:(id)anObject
                               atIndexPath:(NSIndexPath *)indexPath
                             forChangeType:(NSFetchedResultsChangeType)type
                              newIndexPath:(NSIndexPath *)newIndexPath;
{

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.batchUpdateManager.insertArray addObject:newIndexPath];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.batchUpdateManager.deleteArray addObject:indexPath];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.batchUpdateManager.updateArray addObject:indexPath];
            break;
            
        default:
            NSLog(@"Shouldn't be here ... probably a problem");
            break;
    }
}

-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller;
{
    if (self.batchUpdateManager != nil){
        [self.delegate performBatchUpdatesForManager:self.batchUpdateManager];
        
        NSError* error = nil;
        if (![self.managedObjectContext save:&error]){
            NSLog(@"Error saving CoreData context, msg: %@",
                  [error localizedDescription]);
        }

        // reset the batchUpdateManager after completion
        self.batchUpdateManager = nil;
    }
}

#pragma mark - KVO 
static NSUInteger ThumbnailGeneratorQueueContext;

-(void) addQueueObserver;
{
    [self.thumbnailGeneratorQueue addObserver:self
                                   forKeyPath:NSStringFromSelector(@selector(operationCount))
                                      options:NSKeyValueObservingOptionNew
                                      context:&ThumbnailGeneratorQueueContext];
    
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    
    NSParameterAssert([object isKindOfClass:[NSOperationQueue class]]);
    NSParameterAssert([keyPath isEqualToString:NSStringFromSelector(@selector(operationCount))]);
    
    NSUInteger opCount = [((NSOperationQueue*)object) operationCount];
    if (opCount > 0){
        [AppDelegate delegate].shouldPerformBackgroundTask = YES;
    }
    else {
        [AppDelegate delegate].shouldPerformBackgroundTask = NO;
    }
}


-(void) removeQueueObsever;
{
    [self.thumbnailGeneratorQueue removeObserver:self
                                      forKeyPath:NSStringFromSelector(@selector(operationCount))
                                         context:&ThumbnailGeneratorQueueContext];
}


#pragma mark - Helper functions


-(void)startThumbnailGeneration:(NFPImageData*)imageData;
{
    //Initiate and start NSOperation
    NFPThumbnailOperation* operation =
        [[NFPThumbnailOperation alloc] initWithNFPImageData:imageData
                                                    context:self.childContext];
    [self.thumbnailGeneratorQueue addOperation:operation];
}

// good for debugging what objects are in a specific context at any time in this app
// print output is determined by the description method of NFPImageData+NFPExtension category
-(void)printObjectsInContext:(NSManagedObjectContext*)moc name:(NSString*)mocName;
{
    
    //create a fetch request with the mandatory sort descriptor
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([NFPImageData class])];
    request.sortDescriptors =
    @[ [NSSortDescriptor
        sortDescriptorWithKey:NSStringFromSelector(@selector(dateCreated))
        ascending:YES] ];
    
    NSFetchedResultsController* frc = [[NSFetchedResultsController alloc]
                                       initWithFetchRequest:request
                                       managedObjectContext:moc
                                       sectionNameKeyPath:nil
                                       cacheName:nil];
    NSError* fetchError;
    [frc performFetch:&fetchError];
    NSArray* arr = [frc fetchedObjects];
    NSLog(@"Contents of Context: %@ with %tu objects",mocName,[arr count]);
    [arr enumerateObjectsUsingBlock:^(NFPImageData* data, NSUInteger idx, BOOL *stop) {
        NSLog(@"%@",data);
    }];
    
}


#pragma mark - Debugging methods
-(void) performRegenerationOfAllThumbnails;
{
    //reset all images and start the background operation to regenerate thumbnail
    for (NFPImageData* imageData in self.fetchedResultsController.fetchedObjects) {
        imageData.hasThumbnail = NO;
        imageData.thumbnail = nil;
        [self startThumbnailGeneration:imageData];
    }
}

-(void)clearAllThumbnails;
{
    for (NFPImageData* imageData in self.fetchedResultsController.fetchedObjects) {
        [self.managedObjectContext deleteObject:imageData];
    }
}


#pragma mark - clean up and dealloc

-(void)dealloc;
{
    [self removeQueueObsever];
    
}









@end
