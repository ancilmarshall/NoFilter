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
#import "BatchUpdateManager.h"
#import "NFPServerManager.h"
#import "UIImage+NFExtensions.h"


#if 0 && defined(DEBUG)
#define THUMBNAIL_GEN_LOG(format, ...) NSLog(@"Thumbnail Generator: " format, ## __VA_ARGS__)
#else
#define THUMBNAIL_GEN_LOG(format, ...)
#endif


@interface NFPThumbnailGenerator()  <NSFetchedResultsControllerDelegate>

-(instancetype)initSingleton NS_DESIGNATED_INITIALIZER;

@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@property (nonatomic,strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic,strong) BatchUpdateManager* batchUpdateManager;
@property (nonatomic,strong) NFPImageManagedObjectContext* managedObjectContext;
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
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                         initWithFetchRequest:fetchRequest
                                         managedObjectContext:self.managedObjectContext
                                         sectionNameKeyPath:nil
                                         cacheName:nil];
        
        
        self.fetchedResultsController.delegate = self;
        
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
            
        });
        
        //prints only for debugging purposes
        [self printObjectsInContext:self.managedObjectContext name:@"Root Managed Object Context"];
        
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
    [NFPImageData addImage:image
        context:[self childContextForParentContext:self.managedObjectContext]];
}

-(void)addDownloadedImage:(UIImage*)image withID:(NSUInteger)imageID;
{
    [NFPImageData addImage:image
         context:[self childContextForParentContext:self.managedObjectContext]
          withID:imageID];
}

-(NSUInteger)count;
{
    return [[self.fetchedResultsController sections][0] numberOfObjects] ;
}

-(NSArray*)allImageData;
{
    return [self.fetchedResultsController fetchedObjects];
}

-(NFPImageData*)imageDataWithHighestID;
{
    NSArray* imageDataArray = [self.fetchedResultsController fetchedObjects];
    NFPImageData* maxImageData = [imageDataArray firstObject];
    for (NFPImageData* imageData in imageDataArray) {
        
        if (imageData.imageID > maxImageData.imageID){
            maxImageData = imageData;
        }
    }
    return maxImageData;
}

-(NSArray*)imageDataArrayWithIDs:(NSArray*)imageIDs;
{
    NSArray* allObjects = [self.fetchedResultsController fetchedObjects];
    NSMutableArray* imageDataArray = [NSMutableArray new];
    
    for (NFPImageData* imageData in allObjects)
    {
        if ( [imageIDs containsObject:@(imageData.imageID)]){
            [imageDataArray addObject:imageData];
        }
    }
    
    return [NSArray arrayWithArray:imageDataArray];
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
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^
    {
        imageData.thumbnail = [imageData.image
                               scaledImageConstrainedToSize:CGSizeMake(100.0, 100.0)];
    }];
    operation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            THUMBNAIL_GEN_LOG(@"Thumbnail Updated for ImageID: %tu",imageData.imageID);
            imageData.hasThumbnail = YES;
            NSError* error = nil;
            if (![self.managedObjectContext save:&error]){
                NSLog(@"Error saving thumbnail to NFPImageData: %@",
                      [error localizedDescription]);
            }
        });
    };

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
    THUMBNAIL_GEN_LOG(@"Contents of Context: %@ with %tu objects",mocName,[arr count]);
    [arr enumerateObjectsUsingBlock:^(NFPImageData* data, NSUInteger idx, BOOL *stop) {
        THUMBNAIL_GEN_LOG(@"%@",data);
    }];
    
}

-(NSManagedObjectContext*)childContextForParentContext:(NSManagedObjectContext*)parentContext;
{
    NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = parentContext;
    return childContext;
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
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]){
        NSLog(@"Error deleting objects: %@",
              [error localizedDescription]);
    }
    
}

-(void)deleteAllImagesOnServer;
{
    [[NFPServerManager sharedInstance] deleteAllImagesOnServer];
}


#pragma mark - clean up and dealloc

-(void)dealloc;
{
    [self removeQueueObsever];
    
}









@end
