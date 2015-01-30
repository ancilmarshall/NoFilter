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
+ (NFPImageData*) initWithImage:(UIImage*)image atCollectionIndex:(NSUInteger)index;
@end
