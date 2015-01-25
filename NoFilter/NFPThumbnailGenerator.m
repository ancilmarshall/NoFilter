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
    [thumbnail addObserver:self forKeyPath:@"hasThumbnail"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [self.thumbnails addObject:thumbnail];
    
    // Responsibility of this class to call the delegate on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate willGenerateThumbnailAtIndex:thumbnail.index];
    });
    
    //Initiate and start NSOperation
    NFPThumbnailOperation* operation =
        [[NFPThumbnailOperation alloc] initWithNFPThumbnail:thumbnail];
    [self.thumbnailGeneratorQueue addOperation:operation];
    
}

#pragma  mark - KVO Observer

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    NSParameterAssert([object isKindOfClass:[NFPThumbnail class]]);
    NFPThumbnail* thumbnail = (NFPThumbnail*)object;
    
    // Responsibility of this class to call the delegate on the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate didGenerateThumbnailAtIndex:thumbnail.index];
    });
   
}

#pragma mark - Helper functions
-(NSUInteger)count;
{
    return [self.thumbnails count];
}

@end
