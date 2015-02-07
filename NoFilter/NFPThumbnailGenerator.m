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

@interface NFPThumbnailGenerator()  <NSFetchedResultsControllerDelegate>

-(instancetype)initSingleton NS_DESIGNATED_INITIALIZER;

@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@property (nonatomic,strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic,strong) BatchUpdateManager* batchUpdateManager;
@property (nonatomic,strong) NFPImageManagedObjectContext* managedObjectContext;
@property (nonatomic,strong) NSManagedObjectContext* childContext;
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
        
        self.managedObjectContext = [[AppDelegate delegate] managedObjectContext];
        self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.childContext.parentContext = self.managedObjectContext;

        self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                         initWithFetchRequest:fetchRequest
                                         managedObjectContext:self.managedObjectContext
                                         sectionNameKeyPath:nil
                                         cacheName:nil];
        
        self.fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error]) {
            NSLog(@"Failed to perform initial fetch: %@", error);
        }
        
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
    NFPImageData* imageData = [self.fetchedResultsController
       objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                          
    return imageData.thumbnail;
}

-(BOOL)hasThumbnailAtIndex:(NSUInteger)index;
{
    NFPImageData* imageData = [self.fetchedResultsController
        objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return imageData.hasThumbnail;
}

-(void)addImage:(UIImage *)image;
{
    
    NFPImageData* imageData = [NFPImageData addImage:image];
    
    // Start the thumbnail generation by adding to background queue
    [self startThumbnailGeneration:imageData];
}

#pragma mark - NSFetchedResultsControllerDelegate

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

        self.batchUpdateManager = nil;
    }
}

#pragma mark - Helper functions

-(NSUInteger)count;
{
    return [[self.fetchedResultsController sections][0] numberOfObjects] ;
}

-(void)startThumbnailGeneration:(NFPImageData*)imageData;
{
    //Initiate and start NSOperation
    NFPThumbnailOperation* operation =
        [[NFPThumbnailOperation alloc] initWithNFPImageData:imageData
                                                    context:self.childContext];
    [self.thumbnailGeneratorQueue addOperation:operation];
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










@end
