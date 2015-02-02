//
//  NFPThumbnailOperation.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "NFPImageData.h"
#import "NFPThumbnailOperation.h"
#import "NFPImageManagedObjectContext.h"
#import "NFPImageData+NFPExtension.h"
#import "UIImage+NFExtensions.h"

@interface NFPThumbnailOperation()
@property (nonatomic,strong) NFPImageData* imageData;
@end

@implementation NFPThumbnailOperation

-(instancetype)initWithNFPImageData:(NFPImageData*)imageData;
{
    self = [super init];
    if (self){
        _imageData = imageData;
        __weak NFPThumbnailOperation* weak_self = self;
        [self setCompletionBlock:^{
            [weak_self operationComplete];
        }];
    }
    return self;
}

// perform the time intensive tasks here
-(void) main;
{    
    // always check if operation is cancelled
    if (self.isCancelled)
        return;
    
    self.imageData.thumbnail =
        [self.imageData.image
            scaledImageConstrainedToSize:CGSizeMake(100.0, 100.0)];
}

-(void) operationComplete;
{
    // always check if operation is cancelled
    if (self.isCancelled)
        return;
        
    //NOTE: perform the update on main queue to be recognized immediately by
    //fetchRequestController since its ManagedObjectContext is on the main
    //queue ( NSMainQueueConcurrencyType )
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageData.hasThumbnail = YES;
    });
    
    
}
@end
