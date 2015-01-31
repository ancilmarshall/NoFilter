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
@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@property (nonatomic,strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic,strong) NSFetchRequest* fetchRequest;
@property (nonatomic,strong) BatchUpdateManager* batchUpdateManager;
@end

@implementation NFPThumbnailGenerator

#pragma mark - Initialization
-(instancetype)initWithDelegate:(id<NFPThumbnailGeneratorProtocol>)delegate;
{
    self = [super init];
    if (self){
        _delegate = delegate;
        
        self.fetchRequest = [[NSFetchRequest alloc]
                             initWithEntityName:NSStringFromClass([NFPImageData class])];
        self.fetchRequest.sortDescriptors =
            @[ [NSSortDescriptor
                sortDescriptorWithKey:NSStringFromSelector(@selector(dateCreated))
                            ascending:YES] ];
        
        NFPImageManagedObjectContext *moc = [[AppDelegate delegate] managedObjectContext];
        self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                         initWithFetchRequest:self.fetchRequest
                                         managedObjectContext:moc
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
    if ([self  count] == 0){
        return nil;
    }
    
    NFPImageData* imageData = [self.fetchedResultsController
       objectAtIndexPath:[NSIndexPath indexPathForItem:index
                                             inSection:0]];
    return imageData.thumbnail;
}

-(void)addImage:(UIImage *)image;
{
    
    NSUInteger indexOfNewImage = [self count];
    NFPImageData* imageData = [NFPImageData initWithImage:image
                                        atCollectionIndex:indexOfNewImage];
    
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
    [self.delegate performBatchUpdatesForManager:self.batchUpdateManager];
    self.batchUpdateManager = nil;
    
    NSError* error = nil;
    NFPImageManagedObjectContext* moc = [[AppDelegate delegate] managedObjectContext];
    if (![moc save:&error]){
        NSLog(@"Error saving core data object %@",[error localizedDescription]);
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
        [[NFPThumbnailOperation alloc] initWithNFPImageData:imageData];
    [self.thumbnailGeneratorQueue addOperation:operation];
 
}

#pragma mark - Debugging methods
-(void) performRegenerationOfAllThumbnails;
{
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform initial fetch: %@", error);
    }
    
    NSArray* images = self.fetchedResultsController.fetchedObjects;
    
    //first reset all images
    for (NFPImageData* imageData in images) {
        imageData.hasThumbnail = @NO;
        imageData.thumbnail = nil;
    }

    //then add start the generation process
    for (NFPImageData* imageData in images){
        [self startThumbnailGeneration:imageData];
    }
}

-(void)clearAllThumbnails;
{
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to perform initial fetch: %@", error);
    }
    
    NSArray* images = self.fetchedResultsController.fetchedObjects;
    NFPImageManagedObjectContext *moc = [[AppDelegate delegate] managedObjectContext];
    for (NFPImageData* imageData in images) {
        [moc deleteObject:imageData];
    }

}









@end
