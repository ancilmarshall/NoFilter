//
//  NFPThumbnailGenerator.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPThumbnailGenerator.h"
#import "NFPThumbnail.h"
#import "NFPThumbnailOperation.h"

@interface NFPThumbnailGenerator()
@property (nonatomic,strong) NSMutableArray* thumbnails; // of NFPThumbnail objects
@property (nonatomic,strong) NSOperationQueue* thumbnailGeneratorQueue;
@end

@implementation NFPThumbnailGenerator

static NSString* kKeyPath = @"hasThumbnail";

#pragma mark - Initialization
-(instancetype)initWithDelegate:(id<NFPThumbnailGeneratorProtocol>)delegate;
{
    self = [super init];
    if (self){
        _delegate = delegate;
    }
    return self;
}

-(NSMutableArray*)thumbnails;
{
    if (!_thumbnails){
        _thumbnails = [NSMutableArray new];
    }
    return _thumbnails;
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
    if ([self.thumbnails count] == 0){
        return nil;
    }
    
    NFPThumbnail* thumbnail = [self.thumbnails objectAtIndex:index];
    return thumbnail.thumbnailImage;
}

-(void)addImage:(UIImage *)image;
{
    
    NSUInteger currentIndex = [self.thumbnails count];
    NFPThumbnail* thumbnail = [[NFPThumbnail alloc] initWithRawImage:image
                                                   atCollectionIndex:currentIndex];
    
    //Add self as observer to know when the operation has completed
    [thumbnail addObserver:self forKeyPath:kKeyPath
                   options:NSKeyValueObservingOptionOld
                   context:nil];
    thumbnail.observer = self;
    thumbnail.keyPath = kKeyPath;
    
    [self.thumbnails addObject:thumbnail];
    [self startThumbnailGeneration:thumbnail];
}

#pragma  mark - KVO Observer

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSParameterAssert([object isKindOfClass:[NFPThumbnail class]]);
    NFPThumbnail* thumbnail = (NFPThumbnail*)object;
    
    BOOL oldValue = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
    BOOL newValue = thumbnail.hasThumbnail;
    
    // Responsibility of this class to call the delegate on the main queue
    // protect against debugging actions when the hasThumbnail is reset to NO
    if (oldValue == NO && newValue == YES){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didGenerateThumbnailAtIndex:thumbnail.index];
        });
    }
}

#pragma mark - Helper functions
-(NSUInteger)count;
{
    return [self.thumbnails count];
}

-(void)startThumbnailGeneration:(NFPThumbnail*)thumbnail;
{
    // Responsibility of this class to call the delegate on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate willGenerateThumbnailAtIndex:thumbnail.index];
    });
    
    //Initiate and start NSOperation
    NFPThumbnailOperation* operation =
    [[NFPThumbnailOperation alloc] initWithNFPThumbnail:thumbnail];
    [self.thumbnailGeneratorQueue addOperation:operation];
    
}

#pragma mark - Debuggin methods
-(void) performRegenerationOfAllThumbnails;
{
    //first reset all images
    for (NFPThumbnail* thumbnail in self.thumbnails) {
        thumbnail.hasThumbnail = NO;
        thumbnail.thumbnailImage = nil;
    }
    
    //then add start the generation process
    for (NFPThumbnail* thumbnail in self.thumbnails){
        [self startThumbnailGeneration:thumbnail];
    }
}

-(void)clearAllThumbnails;
{
    [self.thumbnails removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didClearAllThumbnails];
    });
    
}









@end
