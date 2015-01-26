//
//  NFPThumbnailGenerator.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NFPThumbnailGeneratorProtocol;

@interface NFPThumbnailGenerator : NSObject

@property (nonatomic,weak) id<NFPThumbnailGeneratorProtocol> delegate;

-(instancetype) initWithDelegate:(id<NFPThumbnailGeneratorProtocol>)delegate
    NS_DESIGNATED_INITIALIZER;
-(UIImage*) thumbnailAtIndex:(NSUInteger)index;
-(void) addImage:(UIImage*)image;
-(NSUInteger) count;
-(void) performRegenerationOfAllThumbnails;
@end


@protocol NFPThumbnailGeneratorProtocol <NSObject>

-(void) didGenerateThumbnailAtIndex:(NSUInteger)index;
-(void) willGenerateThumbnailAtIndex:(NSUInteger)index;

@end