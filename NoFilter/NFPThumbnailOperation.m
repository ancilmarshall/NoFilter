//
//  NFPThumbnailOperation.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPThumbnail.h"
#import "NFPThumbnailOperation.h"
#import "UIImage+NFExtensions.h"

@interface NFPThumbnailOperation()
@property (nonatomic,strong) NFPThumbnail* thumbnail;
@end

@implementation NFPThumbnailOperation

-(instancetype)initWithNFPThumbnail:(NFPThumbnail*) thumbnail;
{
    self = [super init];
    if (self){
        _thumbnail = thumbnail;
        __weak NFPThumbnailOperation* weak_self = self;
        [self setCompletionBlock:^{
            [weak_self operationComplete];
        }];
    }
    return self;
}

-(void) main;
{
    if (self.isCancelled)
        return;
    
    self.thumbnail.thumbnailImage =
        [self.thumbnail.rawImage scaledImageConstrainedToSize:CGSizeMake(100.0, 100.0)];
    
}

-(void) operationComplete;
{
    if (self.isCancelled)
        return;
    
    self.thumbnail.hasThumbnail = YES;
}
@end
