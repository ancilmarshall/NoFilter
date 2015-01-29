//
//  NFPThumbnailGenerator.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPThumbnailGenerator.h"
#import "NFPImageData.h"
#import "NFPThumbnailOperation.h"

@interface NFPThumbnailGenerator()
@property (nonatomic,strong) NSMutableArray* images; // of NFPImageData objects
@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
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
    }
    return self;
}

-(NSMutableArray*)images;
{
    if (!_images){
        _images = [NSMutableArray new];
    }
    return _images;
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
    if ([self.images count] == 0){
        return nil;
    }
    
    NFPImageData* imageData = [self.images objectAtIndex:index];
    return imageData.thumbnail;
}

-(void)addImage:(UIImage *)image;
{
    
    NSUInteger indexOfNewImage = [self.images count];
    NFPImageData* imageData = [[NFPImageData alloc] initWithImage:image
                                                   atCollectionIndex:indexOfNewImage];
    
    //Add self as observer to know when the operation has completed
    [imageData addObserver:self forKeyPath:kKeyPath
                   options:NSKeyValueObservingOptionOld
                   context:nil];
    imageData.observer = self;
    imageData.keyPath = kKeyPath;
    
    [self.images addObject:imageData];
    [self startThumbnailGeneration:imageData
                    generationType:NFPThumbnailGenerationTypeGenerate];
}

#pragma  mark - KVO Observer

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSParameterAssert([object isKindOfClass:[NFPImageData class]]);
    NFPImageData* imageData = (NFPImageData*)object;
    
    BOOL oldValue = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
    BOOL newValue = imageData.hasThumbnail;
    
    // Responsibility of this class to call the delegate on the main queue
    // protect against debugging actions when the hasThumbnail is reset to NO
    if (oldValue == NO && newValue == YES){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didGenerateThumbnailAtIndex:imageData.index];
        });
    }
}

#pragma mark - Helper functions
-(NSUInteger)count;
{
    return [self.images count];
}

-(void)startThumbnailGeneration:(NFPImageData*)imageData
                 generationType:(NFP_THUMBNAIL_GENERATION_TYPE)type;
{
    // Responsibility of this class to call the delegate on the main queue
    if (type == NFPThumbnailGenerationTypeGenerate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate willGenerateThumbnailAtIndex:imageData.index];
        });
    }
    else if (type == NFPThumbnailGenerationTypeRegenerate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate willRegenerateThumbnailAtIndex:imageData.index];
        });
    }
    
    //Initiate and start NSOperation
    NFPThumbnailOperation* operation =
        [[NFPThumbnailOperation alloc] initWithNFPImageData:imageData];
    [self.thumbnailGeneratorQueue addOperation:operation];
    
}

#pragma mark - Debuggin methods
-(void) performRegenerationOfAllThumbnails;
{
    //first reset all images
    for (NFPImageData* imageData in self.images) {
        imageData.hasThumbnail = NO;
        imageData.thumbnail = nil;
    }
    
    //then add start the generation process
    for (NFPImageData* imageData in self.images){
        [self startThumbnailGeneration:imageData
                        generationType:NFPThumbnailGenerationTypeRegenerate];
    }
}

-(void)clearAllThumbnails;
{
    [self.images removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didClearAllThumbnails];
    });
    
}









@end
