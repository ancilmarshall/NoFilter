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

@interface NFPThumbnailGenerator()  <NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@property (nonatomic,strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic,strong) NSFetchRequest* fetchRequest;
@end

@implementation NFPThumbnailGenerator

static NSString* kKeyPath = @"hasThumbnail";

typedef enum {
    NFPThumbnailGenerationTypeGenerate = 0,
    NFPThumbnailGenerationTypeRegenerate
} NFP_THUMBNAIL_GENERATION_TYPE;

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
    //Add self as observer to know when the operation has completed
//    [imageData addObserver:self forKeyPath:kKeyPath
//                   options:NSKeyValueObservingOptionOld
//                   context:nil];
    
    // Start the thumbnail generation by adding to background queue
    [self startThumbnailGeneration:imageData
                    generationType:NFPThumbnailGenerationTypeGenerate];
}

#pragma  mark - KVO Observer

//-(void)observeValueForKeyPath:(NSString *)keyPath
//                     ofObject:(id)object
//                       change:(NSDictionary *)change
//                      context:(void *)context
//{
//    NSParameterAssert([object isKindOfClass:[NFPImageData class]]);
//    NFPImageData* imageData = (NFPImageData*)object;
//    
//    BOOL oldValue = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
//    BOOL newValue = imageData.hasThumbnail;
//    
//    // Responsibility of this class to call the delegate on the main queue
//    // protect against debugging actions when the hasThumbnail is reset to NO
//    if (oldValue == NO && newValue == YES){
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.delegate didGenerateThumbnailAtIndex:[imageData.index intValue]];
//        });
//    }
//}
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
            [self.delegate willGenerateThumbnailAtIndex:newIndexPath.row];
            //TODO row or item?
            //TODO: dispatch_async?
            
//            [self.batchUpdatesInsertArray addObject:newIndexPath];
            break;
            
        case NSFetchedResultsChangeDelete:
//            [self.batchUpdatesDeleteArray addObject:indexPath];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.delegate didGenerateThumbnailAtIndex:indexPath.row];
            
//            [self.batchUpdatesUpdateArray addObject:indexPath];
            break;
            
        default:
            NSLog(@"Shouldn't be here ... probably a problem");
            break;
    }
    
}



-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller;
{
    
}



#pragma mark - Helper functions
-(NSUInteger)count;
{
    return [[self.fetchedResultsController sections][0] numberOfObjects] ;
}

-(void)startThumbnailGeneration:(NFPImageData*)imageData
                 generationType:(NFP_THUMBNAIL_GENERATION_TYPE)type;
{
    // Responsibility of this class to call the delegate on the main queue
    
    // Let delegate know that I am about to start the generation of the thumbnail
    // Delegate will most likely reload/insert/update/delete it's collection or table view data
    
//    if (type == NFPThumbnailGenerationTypeGenerate) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.delegate willGenerateThumbnailAtIndex:[imageData.index intValue]];
//        });
//    }
//    else if (type == NFPThumbnailGenerationTypeRegenerate) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.delegate willRegenerateThumbnailAtIndex:[imageData.index intValue]];
//        });
//    }
    
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
//
//    //then add start the generation process
//    for (NFPImageData* imageData in self.images){
//        [self startThumbnailGeneration:imageData
//                        generationType:NFPThumbnailGenerationTypeRegenerate];
//    }
}

-(void)clearAllThumbnails;
{
//    [self.images removeAllObjects];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.delegate didClearAllThumbnails];
//    });
//    
}









@end
