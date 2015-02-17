//
//  NFPImageData+NFPExtension.h
//  NoFilter
//
//  Created by Ancil on 1/29/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NFPImageData.h"

@interface NFPImageData (NFPExtension)
+ (void) addImage:(UIImage*)image context:(NSManagedObjectContext*)context;
@property (nonatomic,assign) BOOL hasThumbnail;
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,strong) UIImage* thumbnail;
@end
