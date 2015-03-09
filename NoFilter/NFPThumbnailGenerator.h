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
@property (nonatomic,strong) NSArray* toUploadImageIDs;

+(instancetype) sharedInstance;
-(UIImage*) thumbnailAtIndex:(NSUInteger)index;
-(void) addImage:(UIImage*)image;
-(void)addDownloadedImage:(UIImage*)image withID:(NSUInteger)imageID;
-(NSUInteger) count;
-(void) performRegenerationOfAllThumbnails;
-(void) clearAllThumbnails;
-(NSArray*)allImageIDs;
@end


@protocol NFPThumbnailGeneratorProtocol <NSObject>

-(void) performBatchUpdatesForManager:(BatchUpdateManager*)manager;

@end