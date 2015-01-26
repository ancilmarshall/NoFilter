//
//  NFPImageItem.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NFPThumbnail : NSObject
@property (nonatomic,strong) UIImage* rawImage;
@property (nonatomic,strong) UIImage* thumbnailImage;
@property (nonatomic,assign) NSUInteger index;
@property (nonatomic,assign) BOOL hasThumbnail;
@property (nonatomic,weak) id observer;
@property (nonatomic,strong) NSString* keyPath;

-(instancetype) initWithRawImage:(UIImage*)image
               atCollectionIndex:(NSUInteger)index NS_DESIGNATED_INITIALIZER;
@end
