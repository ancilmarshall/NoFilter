//
//  NFPThumbnailOperation.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

//#import "AppDelegate.h"
#import "NFPImageData.h"
#import "NFPThumbnailOperation.h"
#import "NFPImageManagedObjectContext.h"
#import "NFPImageData+NFPExtension.h"
#import "UIImage+NFExtensions.h"

@interface NFPThumbnailOperation()
@property (nonatomic,strong) NFPImageData* imageData;
@property (nonatomic,strong) NSManagedObjectContext* moc;
@end

@implementation NFPThumbnailOperation

-(instancetype)initWithNFPImageData:(NFPImageData*)imageData
                            context:(NSManagedObjectContext*)context;
{
    self = [super init];
    if (self){
        _imageData = imageData;
        _moc = context;
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
    
    // call performBlock to ensure that all this work is taken into account
    // in the managed object context's queue (either private or main, but we
    // don't know or need to know to keep the interface abstract
    [self.moc performBlock:^{
        self.imageData.hasThumbnail = YES;
        NSError* error = nil;
        if (![self.moc save:&error]){
            NSLog(@"Error saving thumbnail to NFPImageData: %@",
                  [error localizedDescription]);
        }
        
    }];
    
}
@end
