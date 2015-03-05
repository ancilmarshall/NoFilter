//
//  NFPThumbnailGenerator.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class BatchUpdateManager;
@protocol NFPThumbnailGeneratorProtocol;

@interface NFPThumbnailGenerator : NSObject

@property (nonatomic,weak) id<NFPThumbnailGeneratorProtocol> delegate;

+(instancetype) sharedInstance;
-(UIImage*) thumbnailAtIndex:(NSUInteger)index;
-(void) addImage:(UIImage*)image;
-(void)addDownloadedImage:(UIImage*)image withID:(NSUInteger)imageID;
-(NSUInteger) count;
-(void) performRegenerationOfAllThumbnails;
-(void) clearAllThumbnails;
@end


@protocol NFPThumbnailGeneratorProtocol <NSObject>

-(void) performBatchUpdatesForManager:(BatchUpdateManager*)manager;

@end