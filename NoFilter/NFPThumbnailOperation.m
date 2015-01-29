//
//  NFPThumbnailOperation.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPImageData.h"
#import "NFPThumbnailOperation.h"
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
    
    //This boolean can be used to trigger an event notification to indicate that
    // the operation has been completed
    self.imageData.hasThumbnail = YES;
}
@end
